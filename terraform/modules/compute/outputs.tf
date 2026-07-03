output "cluster_name" {
  description = "EKS Cluster Name"
  value       = aws_eks_cluster.this.name
}

output "cluster_arn" {
  description = "EKS Cluster ARN"
  value       = aws_eks_cluster.this.arn
}

output "cluster_endpoint" {
  description = "EKS Cluster Endpoint"
  value       = aws_eks_cluster.this.endpoint
}

output "cluster_version" {
  description = "EKS Kubernetes Version"
  value       = aws_eks_cluster.this.version
}

output "node_group_name" {
  description = "EKS Managed Node Group Name"
  value       = aws_eks_node_group.default.node_group_name
}

output "oidc_issuer" {
  description = "EKS OIDC Issuer URL"
  value       = aws_eks_cluster.this.identity[0].oidc[0].issuer
}