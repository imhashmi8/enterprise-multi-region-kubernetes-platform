aws_region        = "eu-west-1"
environment       = "production"
project           = "eks-platform"
team              = "platform-engineering"
cost_center       = "platform"
cluster_version   = "1.33"
state_bucket_name = "eks-platform-terraform-state-528956693660"

cluster_endpoint_public_access       = false
cluster_endpoint_public_access_cidrs = []

system_node_group_config = {
  instance_types = ["t3.small"]
  min_size       = 1
  max_size       = 2
  desired_size   = 1
  disk_size_gb   = 20
}

application_node_group_config = {
  instance_types = ["t3.medium"]
  min_size       = 1
  max_size       = 2
  desired_size   = 1
  disk_size_gb   = 20
}

admin_iam_roles = [
  # "arn:aws:iam::528956693660:role/PlatformEngineeringRole",
]
