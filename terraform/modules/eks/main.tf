# [EKS] 클러스터 + System 관리형 노드그룹 + OIDC 프로바이더
# 핵심: OIDC가 모든 IRSA(Pod가 AWS API를 호출할 권한)의 뿌리다

# ---------- 클러스터가 쓸 IAM Role ----------
resource "aws_iam_role" "cluster" {
  name = "${var.cluster_name}-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "eks.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "cluster" {
  role       = aws_iam_role.cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# ---------- EKS 클러스터 ----------
resource "aws_eks_cluster" "this" {
  name     = var.cluster_name
  version  = var.cluster_version
  role_arn = aws_iam_role.cluster.arn

  vpc_config {
    subnet_ids              = var.private_subnet_ids # 워커/컨트롤플레인 ENI는 프라이빗에만
    endpoint_public_access  = true                   # kubectl을 로컬에서 치기 위함 (실무는 IP 제한 권장)
    endpoint_private_access = true
  }

  # access entries 방식 - aws-auth ConfigMap 수동 관리 지옥에서 해방
  access_config {
    authentication_mode                         = "API_AND_CONFIG_MAP"
    bootstrap_cluster_creator_admin_permissions = true # terraform 실행자에게 admin 자동 부여
  }

  depends_on = [aws_iam_role_policy_attachment.cluster]
}

# ---------- OIDC 프로바이더 (IRSA의 뿌리) ----------
data "tls_certificate" "oidc" {
  url = aws_eks_cluster.this.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "this" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.oidc.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.this.identity[0].oidc[0].issuer
}

# ---------- System 노드그룹용 IAM Role ----------
resource "aws_iam_role" "node" {
  name = "${var.cluster_name}-system-node-role"

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
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",          # 노드가 클러스터에 조인
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",               # Pod에 VPC IP 할당
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly", # ECR 이미지 pull
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",       # SSM 접속 (SSH 키 불필요)
  ])
  role       = aws_iam_role.node.name
  policy_arn = each.value
}

resource "aws_eks_node_group" "system" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "system"
  node_role_arn   = aws_iam_role.node.arn
  subnet_ids      = var.private_subnet_ids
  instance_types  = var.system_instance_types
  capacity_type   = "ON_DEMAND" 

  scaling_config {
  desired_size = var.system_desired_size
  min_size     = var.system_min_size
  max_size     = var.system_max_size
}

  labels = { role = "system" } 

  depends_on = [aws_iam_role_policy_attachment.node]
}
resource "aws_eks_node_group" "ai" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "${var.cluster_name}-ai"
  node_role_arn   = aws_iam_role.node.arn
  subnet_ids      = var.private_subnet_ids
  instance_types  = var.ai_instance_types
  capacity_type   = "ON_DEMAND"

  scaling_config {
    desired_size = var.ai_desired_size
    min_size     = var.ai_min_size
    max_size     = var.ai_max_size
  }

  labels = { role = "ai" }

  # AI CronJob만 진입 허용 - toleration 없는 파드 차단
  taint {
    key    = "dedicated"
    value  = "ai"
    effect = "NO_SCHEDULE"
  }

  depends_on = [aws_iam_role_policy_attachment.node]
}

# ---------- Worker 관리형 노드그룹 (FastAPI 베이스라인, 항상 ON_DEMAND 1개 유지) ----------
resource "aws_eks_node_group" "worker" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "${var.cluster_name}-worker"
  node_role_arn   = aws_iam_role.node.arn
  subnet_ids      = var.private_subnet_ids
  instance_types  = var.worker_instance_types
  capacity_type   = "ON_DEMAND"

  scaling_config {
    desired_size = var.worker_desired_size
    min_size     = var.worker_min_size
    max_size     = var.worker_max_size
  }

  labels = { role = "worker" }

  depends_on = [aws_iam_role_policy_attachment.node]
}   

# ---------- 필수 애드온 ----------
resource "aws_eks_addon" "vpc_cni" {
  cluster_name = aws_eks_cluster.this.name
  addon_name   = "vpc-cni"
}

resource "aws_eks_addon" "kube_proxy" {
  cluster_name = aws_eks_cluster.this.name
  addon_name   = "kube-proxy"
}

resource "aws_eks_addon" "coredns" {
  cluster_name = aws_eks_cluster.this.name
  addon_name   = "coredns"
  depends_on   = [aws_eks_node_group.system] # coredns Pod가 뜰 노드가 먼저 있어야 함
}
