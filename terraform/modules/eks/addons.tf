# ===== Kubecost =====
locals {
  kubecost_bucket_name  = "project-sc-cost"
  kubecost_sa_name      = "kubecost-cost-analyzer"
  kubecost_sa_namespace = "kubecost"
}

data "aws_iam_policy_document" "kubecost_assume_role" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_eks_cluster.this.identity[0].oidc[0].issuer, "https://", "")}:sub"
      values   = ["system:serviceaccount:${local.kubecost_sa_namespace}:${local.kubecost_sa_name}"]
    }

    principals {
      identifiers = [aws_iam_openid_connect_provider.this.arn]
      type        = "Federated"
    }
  }
}

resource "aws_iam_role" "kubecost" {
  name               = "${var.cluster_name}-kubecost"
  assume_role_policy = data.aws_iam_policy_document.kubecost_assume_role.json
}


data "aws_iam_policy_document" "kubecost_s3" {
  statement {
    effect    = "Allow"
    actions   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
    resources = ["arn:aws:s3:::${local.kubecost_bucket_name}/*"]
  }
  statement {
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = ["arn:aws:s3:::${local.kubecost_bucket_name}"]
  }
}

resource "aws_iam_role_policy" "kubecost_s3" {
  name   = "${var.cluster_name}-kubecost-s3"
  role   = aws_iam_role.kubecost.name
  policy = data.aws_iam_policy_document.kubecost_s3.json
}

resource "aws_s3_bucket_ownership_controls" "kubecost_bucket" {
  bucket = local.kubecost_bucket_name

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_spot_datafeed_subscription" "kubecost" {
  bucket = local.kubecost_bucket_name
  prefix = "spot-data-feed"

  depends_on = [aws_s3_bucket_ownership_controls.kubecost_bucket]
}


locals {
  spot_price_exporter_sa_name      = "spot-price-exporter"
  spot_price_exporter_sa_namespace = "ai"
}

data "aws_iam_policy_document" "spot_price_exporter_assume_role" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_eks_cluster.this.identity[0].oidc[0].issuer, "https://", "")}:sub"
      values   = ["system:serviceaccount:${local.spot_price_exporter_sa_namespace}:${local.spot_price_exporter_sa_name}"]
    }

    principals {
      identifiers = [aws_iam_openid_connect_provider.this.arn]
      type        = "Federated"
    }
  }
}

resource "aws_iam_role" "spot_price_exporter" {
  name               = "${var.cluster_name}-spot-price-exporter"
  assume_role_policy = data.aws_iam_policy_document.spot_price_exporter_assume_role.json
}

data "aws_iam_policy_document" "spot_price_exporter_ec2" {
  statement {
    effect    = "Allow"
    actions   = ["ec2:DescribeSpotPriceHistory"]
    resources = ["*"]
  }
  statement {
    # Pricing API도 리소스 단위 지정이 불가능한 조회 전용 API
    effect    = "Allow"
    actions   = ["pricing:GetProducts"]
    resources = ["*"]
  }

}

resource "aws_iam_role_policy" "spot_price_exporter_ec2" {
  name   = "${var.cluster_name}-spot-price-exporter-ec2"
  role   = aws_iam_role.spot_price_exporter.name
  policy = data.aws_iam_policy_document.spot_price_exporter_ec2.json
}

locals {
  yace_sa_name      = "yace"
  yace_sa_namespace = "monitoring"
}

data "aws_iam_policy_document" "yace_assume_role" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_eks_cluster.this.identity[0].oidc[0].issuer, "https://", "")}:sub"
      values   = ["system:serviceaccount:${local.yace_sa_namespace}:${local.yace_sa_name}"]
    }

    principals {
      identifiers = [aws_iam_openid_connect_provider.this.arn]
      type        = "Federated"
    }
  }
}

resource "aws_iam_role" "yace" {
  name               = "${var.cluster_name}-yace"
  assume_role_policy = data.aws_iam_policy_document.yace_assume_role.json
}

data "aws_iam_policy_document" "yace_cloudwatch" {
  statement {
    effect    = "Allow"
    actions   = ["cloudwatch:GetMetricData", "cloudwatch:ListMetrics"]
    resources = ["*"]
  }
  statement {
    effect    = "Allow"
    actions   = ["tag:GetResources"]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "yace_cloudwatch" {
  name   = "${var.cluster_name}-yace-cloudwatch"
  role   = aws_iam_role.yace.name
  policy = data.aws_iam_policy_document.yace_cloudwatch.json
}
