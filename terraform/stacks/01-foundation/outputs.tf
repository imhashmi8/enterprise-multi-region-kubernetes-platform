output "vpc_id" {
  description = "VPC ID. Consumed by the 02-eks stack via remote state."
  value       = module.vpc.vpc_id
}

output "vpc_cidr" {
  description = "VPC CIDR block."
  value       = module.vpc.vpc_cidr
}

output "public_subnet_ids" {
  description = "Public subnet IDs."
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "Private subnet IDs. EKS nodes are placed here."
  value       = module.vpc.private_subnet_ids
}

output "data_subnet_ids" {
  description = "Data subnet IDs. RDS and ElastiCache are placed here."
  value       = module.vpc.data_subnet_ids
}

output "nat_gateway_public_ips" {
  description = "NAT Gateway public IPs. Add to external firewall allowlists."
  value       = module.vpc.nat_gateway_public_ips
}

output "name_prefix" {
  description = "Standard name prefix used across all resources in this region."
  value       = module.tags.name_prefix
}
