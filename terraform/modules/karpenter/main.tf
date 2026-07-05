# [Karpenter] AWS쪽 절반 - 컨트롤러 IRSA, 노드 IAM Role, SQS 인터럽션 큐, EventBridge 규칙 4종
# 클러스터쪽 절반(헬름 차트, NodePool)은 k8s/ 폴더에서 ArgoCD가 배포한다

data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
}

# ---------- 클러스터 SG에 discovery 태그 부착 ----------
# EC2NodeClass의 securityGroupSelectorTerms가 이 태그로 SG를 찾는다
resource "aws_ec2_tag" "cluster_sg_discovery" {
  resource_id = var.cluster_security_group_id
  key         = "karpenter.sh/discovery"
  value       = var.cluster_name
}

# ---------- Karpenter가 만들 노드가 쓸 IAM Role ----------
resource "aws_iam_role" "node" {
  name = "${var.cluster_name}-karpenter-node"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "node" {
  for_each = toset([
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
  ])
  role       = aws_iam_role.node.name
  policy_arn = each.value
}

# ---------- Access Entry: Karpenter 노드를 클러스터가 신뢰하도록 등록 ----------
# 이거 없으면 노드가 EC2로는 뜨는데 클러스터 조인이 안 되는 지옥을 맛본다
resource "aws_eks_access_entry" "karpenter_node" {
  cluster_name  = var.cluster_name
  principal_arn = aws_iam_role.node.arn
  type          = "EC2_LINUX"
}

# ---------- Spot 인터럽션 큐 (2분 통보 수신처) ----------
resource "aws_sqs_queue" "interruption" {
  name                      = var.cluster_name # karpenter values의 interruptionQueue와 동일해야 함
  message_retention_seconds = 300
  sqs_managed_sse_enabled   = true
}

resource "aws_sqs_queue_policy" "interruption" {
  queue_url = aws_sqs_queue.interruption.url
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = ["events.amazonaws.com", "sqs.amazonaws.com"] }
      Action    = "sqs:SendMessage"
      Resource  = aws_sqs_queue.interruption.arn
    }]
  })
}

# ---------- EventBridge 규칙 4종: AWS의 노드 관련 이벤트를 큐로 배달 ----------
locals {
  interruption_rules = {
    spot-interruption = { # Spot 회수 2분 전 통보 - 제일 중요
      source      = "aws.ec2"
      detail-type = "EC2 Spot Instance Interruption Warning"
    }
    rebalance = { # 회수 가능성 높아짐 사전 신호
      source      = "aws.ec2"
      detail-type = "EC2 Instance Rebalance Recommendation"
    }
    instance-state = { # 인스턴스 종료/중지 상태 변화
      source      = "aws.ec2"
      detail-type = "EC2 Instance State-change Notification"
    }
    scheduled-change = { # AWS 예정 유지보수
      source      = "aws.health"
      detail-type = "AWS Health Event"
    }
  }
}

resource "aws_cloudwatch_event_rule" "interruption" {
  for_each = local.interruption_rules
  name     = "${var.cluster_name}-karpenter-${each.key}"

  event_pattern = jsonencode({
    source        = [each.value.source]
    "detail-type" = [each.value["detail-type"]]
  })
}

resource "aws_cloudwatch_event_target" "interruption" {
  for_each = local.interruption_rules
  rule     = aws_cloudwatch_event_rule.interruption[each.key].name
  arn      = aws_sqs_queue.interruption.arn
}

# ---------- 컨트롤러 IRSA Role ----------
# kube-system 네임스페이스의 karpenter ServiceAccount만 이 Role을 쓸 수 있다
  resource "aws_iam_role" "controller" {
    name = "${var.cluster_name}-karpenter-controller"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Federated = var.oidc_provider_arn }
      Action    = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${var.oidc_issuer}:sub" = "system:serviceaccount:kube-system:karpenter"
          "${var.oidc_issuer}:aud" = "sts.amazonaws.com"
        }
      }
    }]
  })
}

resource "aws_iam_role_policy" "controller" {
  name = "karpenter-controller-policy"
  role = aws_iam_role.controller.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "EC2NodeManagement" # 노드 구매/반납/조회
        Effect = "Allow"
        Action = [
          "ec2:RunInstances", "ec2:CreateFleet", "ec2:TerminateInstances",
          "ec2:CreateLaunchTemplate", "ec2:DeleteLaunchTemplate",
          "ec2:CreateTags", "ec2:DescribeInstances", "ec2:DescribeInstanceTypes",
          "ec2:DescribeInstanceTypeOfferings", "ec2:DescribeAvailabilityZones",
          "ec2:DescribeImages", "ec2:DescribeLaunchTemplates", "ec2:DescribeSubnets",
          "ec2:DescribeSecurityGroups", "ec2:DescribeSpotPriceHistory"
        ]
        Resource = "*"
      },
      {
        Sid      = "Pricing" # Spot/온디맨드 가격 비교로 최적 인스턴스 선택
        Effect   = "Allow"
        Action   = ["pricing:GetProducts"]
        Resource = "*"
      },
      {
        Sid      = "SSMGetParameter" # 최신 EKS 최적화 AMI ID 조회
        Effect   = "Allow"
        Action   = ["ssm:GetParameter"]
        Resource = "arn:${data.aws_partition.current.partition}:ssm:*:*:parameter/aws/service/*"
      },
      {
        Sid      = "PassNodeRole" # 만든 EC2에 노드 Role을 붙일 권한
        Effect   = "Allow"
        Action   = ["iam:PassRole"]
        Resource = aws_iam_role.node.arn
      },
      {
        Sid    = "InstanceProfileManagement" # Karpenter v1은 인스턴스 프로파일을 직접 만들어 관리
        Effect = "Allow"
        Action = [
          "iam:CreateInstanceProfile", "iam:DeleteInstanceProfile",
          "iam:AddRoleToInstanceProfile", "iam:RemoveRoleFromInstanceProfile",
          "iam:GetInstanceProfile", "iam:TagInstanceProfile"
        ]
        Resource = "*"
      },
      {
        Sid      = "EKSDescribe"
        Effect   = "Allow"
        Action   = ["eks:DescribeCluster"]
        Resource = "arn:${data.aws_partition.current.partition}:eks:*:${local.account_id}:cluster/${var.cluster_name}"
      },
      {
        Sid    = "InterruptionQueue" # 2분 통보 수신
        Effect = "Allow"
        Action = [
          "sqs:DeleteMessage", "sqs:GetQueueAttributes",
          "sqs:GetQueueUrl", "sqs:ReceiveMessage"
        ]
        Resource = aws_sqs_queue.interruption.arn
      }
    ]
  })
}
