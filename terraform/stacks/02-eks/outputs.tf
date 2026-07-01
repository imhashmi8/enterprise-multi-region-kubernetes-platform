output "cluster_name" {
  description = "EKS cluster name. Used to generate kubeconfig."
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "EKS API server endpoint."
  value       = module.eks.cluster_endpoint
  sensitive   = true
}

output "cluster_certificate_authority_data" {
  description = "Base64-encoded CA data for kubeconfig generation."
  value       = module.eks.cluster_certificate_authority_data
  sensitive   = true
}

output "cluster_version" {
  description = "Running Kubernetes version."
  value       = module.eks.cluster_version
}

output "oidc_provider_arn" {
  description = "OIDC provider ARN. Referenced by IRSA policies in later stacks."
  value       = module.eks.oidc_provider_arn
}

output "oidc_provider_url" {
  description = "OIDC provider URL (without https://). Used in StringEquals conditions."
  value       = module.eks.oidc_provider_url
}

output "node_role_arn" {
  description = "Node IAM role ARN. Required by Karpenter EC2NodeClass."
  value       = module.eks.node_role_arn
}

output "cluster_security_group_id" {
  description = "Control plane security group ID."
  value       = module.eks.cluster_security_group_id
}

output "node_security_group_id" {
  description = "Worker node security group ID."
  value       = module.eks.node_security_group_id
}

output "kms_key_arn" {
  description = "KMS key ARN used for secrets encryption. Referenced by add-ons needing decrypt access."
  value       = module.eks.kms_key_arn
}
