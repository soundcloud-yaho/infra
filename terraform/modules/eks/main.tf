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
    subnet_ids              = var.private_subnet_ids
    endpoint_public_access  = true
    endpoint_private_access = true
  }

  access_config {
    authentication_mode                         = "API_AND_CONFIG_MAP"
    bootstrap_cluster_creator_admin_permissions = true
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
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
  ])
  role       = aws_iam_role.node.name
  policy_arn = each.value
}

# ==========================================================
# [신규] Launch Template 3개 — 노드그룹별 커스텀 SG 부착용
#   - 우리가 만든 eks_node SG(ALB→Node→Aurora 체인용) +
#     EKS가 자동 생성한 cluster_security_group(컨트롤플레인 통신용)
#     둘 다 붙여야 안전함 (커스텀 SG만 넣으면 컨트롤플레인 통신이 끊길 위험)
# ==========================================================

resource "aws_launch_template" "system" {
  name_prefix   = "${var.cluster_name}-system-"
  instance_type = var.system_instance_types[0]

  vpc_security_group_ids = [
    var.eks_node_sg_id,
    aws_eks_cluster.this.vpc_config[0].cluster_security_group_id,
  ]

  tag_specifications {
    resource_type = "instance"
    tags          = { Name = "${var.cluster_name}-system" }
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_launch_template" "ai" {
  name_prefix   = "${var.cluster_name}-ai-"
  instance_type = var.ai_instance_types[0]

  vpc_security_group_ids = [
    var.eks_node_sg_id,
    aws_eks_cluster.this.vpc_config[0].cluster_security_group_id,
  ]

  tag_specifications {
    resource_type = "instance"
    tags          = { Name = "${var.cluster_name}-ai" }
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_launch_template" "worker" {
  name_prefix   = "${var.cluster_name}-worker-"
  instance_type = var.worker_instance_types[0]

  vpc_security_group_ids = [
    var.eks_node_sg_id,
    aws_eks_cluster.this.vpc_config[0].cluster_security_group_id,
  ]

  tag_specifications {
    resource_type = "instance"
    tags          = { Name = "${var.cluster_name}-worker" }
  }

  lifecycle {
    create_before_destroy = true
  }
}

# ---------- System 노드그룹 ----------
resource "aws_eks_node_group" "system" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "system"
  node_role_arn   = aws_iam_role.node.arn
  subnet_ids      = var.private_subnet_ids
  capacity_type   = "ON_DEMAND"

  launch_template {
    id      = aws_launch_template.system.id
    version = "$Latest"
  }

  scaling_config {
    desired_size = var.system_desired_size
    min_size     = var.system_min_size
    max_size     = var.system_max_size
  }

  labels = { role = "system" }

  depends_on = [aws_iam_role_policy_attachment.node]
}

# ---------- AI 노드그룹 ----------
resource "aws_eks_node_group" "ai" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "${var.cluster_name}-ai"
  node_role_arn   = aws_iam_role.node.arn
  subnet_ids      = var.private_subnet_ids
  capacity_type   = "ON_DEMAND"

  launch_template {
    id      = aws_launch_template.ai.id
    version = "$Latest"
  }

  scaling_config {
    desired_size = var.ai_desired_size
    min_size     = var.ai_min_size
    max_size     = var.ai_max_size
  }

  labels = { role = "ai" }

  taint {
    key    = "dedicated"
    value  = "ai"
    effect = "NO_SCHEDULE"
  }

  depends_on = [aws_iam_role_policy_attachment.node]
}

# ---------- Worker 노드그룹 ----------
resource "aws_eks_node_group" "worker" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "${var.cluster_name}-worker"
  node_role_arn   = aws_iam_role.node.arn
  subnet_ids      = var.private_subnet_ids
  capacity_type   = "ON_DEMAND"

  launch_template {
    id      = aws_launch_template.worker.id
    version = "$Latest"
  }

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
  depends_on   = [aws_eks_node_group.system]
}