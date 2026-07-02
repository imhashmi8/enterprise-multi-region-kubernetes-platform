variable "cluster_name" {
  description = "Name of the EKS cluster."
  type        = string
}

variable "cluster_version" {
  description = "Kubernetes version for the EKS cluster."
  type        = string
  default     = "1.32"
}

variable "vpc_id" {
  description = "VPC ID where the cluster will be created."
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for EKS node groups. Nodes must not be in public subnets."
  type        = list(string)
}

variable "public_subnet_ids" {
  description = "Public subnet IDs. Referenced by the control plane for load balancer placement."
  type        = list(string)
}

variable "name_prefix" {
  description = "Name prefix for IAM roles and other named resources."
  type        = string
}

variable "tags" {
  description = "Tags applied to all resources."
  type        = map(string)
  default     = {}
}

variable "cluster_endpoint_public_access" {
  description = "Enable public access to the EKS API endpoint. Disable in production; use VPN or bastion."
  type        = bool
  default     = false
}

variable "cluster_endpoint_public_access_cidrs" {
  description = "CIDRs permitted to reach the public API endpoint. Only relevant when public access is enabled."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "enable_cluster_log_types" {
  description = "EKS control plane log types to send to CloudWatch."
  type        = list(string)
  default     = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
}

variable "system_node_group_config" {
  description = "Configuration for the system node group. Runs platform add-ons with CriticalAddonsOnly taint."
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
  description = "Configuration for the application node group. Runs general workloads."
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
