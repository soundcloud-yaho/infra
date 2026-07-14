# [Security] SG 최소 권한 체인(ALB → EKS Node → Aurora) + LB Controller IRSA
#
# SG 체인 구조:
#   인터넷 → ALB SG(80/443) → EKS Node SG(app_port만) → Aurora SG(5432만)
#   각 SG가 이전 SG를 소스로 참조해서 IP가 아닌 SG 단위로 화이트리스트 관리
#
# ALB 자체는 LB Controller가 Ingress 보고 자동 생성 - 여기선 SG만 미리 만들어둠
# LB Controller가 이 alb_sg를 Ingress 어노테이션으로 지정해서 사용
data "aws_caller_identity" "current" {}
# ---------- ALB SG: 인터넷에서 80/443만 허용 ----------
resource "aws_security_group" "alb" {
  name        = "${var.project_name}-${var.environment}-alb-sg"
  description = "Security group for ALB"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTP from Internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "HTTPS from Internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project_name}-${var.environment}-alb-sg" }
}

# ---------- EKS Node SG: ALB에서 app_port만 + 노드 간 통신 ----------
resource "aws_security_group" "eks_node" {
  name        = "${var.project_name}-${var.environment}-eks-node-sg"
  description = "Security group for EKS worker nodes"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Application traffic from ALB to Pod IP"
    from_port       = var.app_port
    to_port         = var.app_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }
  ingress {
    description = "Node to node communication"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project_name}-${var.environment}-eks-node-sg" }
}

# ---------- Aurora SG: EKS Node에서 5432만 허용 ----------
resource "aws_security_group" "aurora" {
  name        = "${var.project_name}-${var.environment}-aurora-sg"
  description = "Security group for Aurora DB"
  vpc_id      = var.vpc_id

  ingress {
    description     = "PostgreSQL from EKS nodes"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.eks_node.id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project_name}-${var.environment}-aurora-sg" }
}

# ---------- AWS Load Balancer Controller IRSA ----------
resource "aws_iam_policy" "lb_controller" {
  name   = "${var.project_name}-${var.environment}-lb-controller-policy"
  policy = file("${path.module}/lb_controller_policy.json")
}

resource "aws_iam_role" "lb_controller" {
  name = "${var.project_name}-${var.environment}-lb-controller"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Federated = var.oidc_provider_arn }
      Action    = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${var.oidc_issuer}:sub" = "system:serviceaccount:kube-system:aws-load-balancer-controller"
          "${var.oidc_issuer}:aud" = "sts.amazonaws.com"
        }
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lb_controller" {
  role       = aws_iam_role.lb_controller.name
  policy_arn = aws_iam_policy.lb_controller.arn
}

resource "aws_kms_key" "this" {
  description             = "${var.project_name}-${var.environment} Aurora 암호화 키"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        # root 계정 전체 접근 (필수 - 없으면 키 관리 자체가 안 됨)
        Sid    = "EnableRootAccess"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        # Aurora가 암호화/복호화에 키 사용
        Sid    = "AllowAuroraService"
        Effect = "Allow"
        Principal = {
          Service = "rds.amazonaws.com"
        }
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey",
          "kms:CreateGrant",
          "kms:DescribeKey"
        ]
        Resource = "*"
      }
    ]
  })

  tags = { Name = "${var.project_name}-${var.environment}-kms" }
}

resource "aws_kms_alias" "this" {
  name          = "alias/${var.project_name}-${var.environment}-aurora"
  target_key_id = aws_kms_key.this.key_id
}