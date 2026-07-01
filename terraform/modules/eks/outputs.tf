output "cluster_name" {
  description = "EKS cluster name."
  value       = aws_eks_cluster.this.name
}

output "cluster_endpoint" {
  description = "EKS API server endpoint."
  value       = aws_eks_cluster.this.endpoint
  sensitive   = true
}

output "cluster_certificate_authority_data" {
  description = "Base64-encoded certificate authority data for the cluster."
  value       = aws_eks_cluster.this.certificate_authority[0].data
  sensitive   = true
}

output "cluster_version" {
  description = "Kubernetes version running on the cluster."
  value       = aws_eks_cluster.this.version
}

output "cluster_oidc_issuer_url" {
  description = "OIDC issuer URL. Used to construct IRSA trust policies."
  value       = aws_eks_cluster.this.identity[0].oidc[0].issuer
}

output "oidc_provider_arn" {
  description = "ARN of the IAM OIDC provider. Pass to IRSA trust policy documents."
  value       = aws_iam_openid_connect_provider.eks.arn
}

output "oidc_provider_url" {
  description = "OIDC provider URL without the https:// prefix. Used in StringEquals conditions."
  value       = local.oidc_issuer_url
}

output "node_role_arn" {
  description = "ARN of the node IAM role. Required by Karpenter NodeClass configuration."
  value       = aws_iam_role.node.arn
}

output "node_role_name" {
  description = "Name of the node IAM role."
  value       = aws_iam_role.node.name
}

output "cluster_security_group_id" {
  description = "Security group ID attached to the EKS control plane."
  value       = aws_security_group.cluster.id
}

output "node_security_group_id" {
  description = "Security group ID attached to worker nodes."
  value       = aws_security_group.node.id
}

output "kms_key_arn" {
  description = "ARN of the KMS key used for secrets encryption."
  value       = aws_kms_key.eks.arn
}
