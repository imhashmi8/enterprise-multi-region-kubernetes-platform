variable "aws_region" {
  description = "AWS region to deploy into."
  type        = string
}

variable "environment" {
  description = "Deployment environment."
  type        = string

  validation {
    condition     = contains(["production", "staging", "development"], var.environment)
    error_message = "environment must be one of: production, staging, development."
  }
}

variable "project" {
  description = "Short project name."
  type        = string
  default     = "eks-platform"
}

variable "team" {
  description = "Owning team name."
  type        = string
  default     = "platform-engineering"
}

variable "cost_center" {
  description = "Cost center code for billing attribution."
  type        = string
  default     = "platform"
}

variable "state_bucket_name" {
  description = "S3 bucket name holding Terraform state for all stacks. Used to read foundation outputs."
  type        = string
}

variable "cluster_version" {
  description = "Kubernetes version for the EKS cluster."
  type        = string
  default     = "1.29"
}

variable "cluster_endpoint_public_access" {
  description = "Enable public access to the EKS API endpoint. Disable in production."
  type        = bool
  default     = false
}

variable "cluster_endpoint_public_access_cidrs" {
  description = "CIDRs allowed to reach the public API endpoint."
  type        = list(string)
  default     = []
}

variable "system_node_group_config" {
  description = "System node group configuration."
  type = object({
    instance_types = list(string)
    min_size       = number
    max_size       = number
    desired_size   = number
    disk_size_gb   = number
  })
  default = {
    instance_types = ["t3.medium"]
    min_size       = 3
    max_size       = 6
    desired_size   = 3
    disk_size_gb   = 50
  }
}

variable "application_node_group_config" {
  description = "Application node group configuration."
  type = object({
    instance_types = list(string)
    min_size       = number
    max_size       = number
    desired_size   = number
    disk_size_gb   = number
  })
  default = {
    instance_types = ["m6i.xlarge"]
    min_size       = 3
    max_size       = 20
    desired_size   = 3
    disk_size_gb   = 100
  }
}

variable "admin_iam_roles" {
  description = "IAM role ARNs granted cluster-admin access via EKS Access Entries."
  type        = list(string)
  default     = []
}
