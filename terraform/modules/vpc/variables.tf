variable "name_prefix" {
  description = "Prefix for all resource names. Typically <project>-<env>-<region>."
  type        = string
}

variable "vpc_cidr" {
  description = "IPv4 CIDR block for the VPC. Must be /16."
  type        = string

  validation {
    condition     = can(cidrnetmask(var.vpc_cidr)) && split("/", var.vpc_cidr)[1] == "16"
    error_message = "vpc_cidr must be a valid /16 CIDR block (e.g. 10.0.0.0/16)."
  }
}

variable "availability_zones" {
  description = "List of AZ suffix letters to deploy subnets into. Exactly 3 required."
  type        = list(string)

  validation {
    condition     = length(var.availability_zones) == 3
    error_message = "Exactly 3 availability zones are required."
  }
}

variable "tags" {
  description = "Tags to apply to all resources."
  type        = map(string)
  default     = {}
}

variable "single_nat_gateway" {
  description = "Use a single NAT Gateway instead of one per AZ. Non-production only."
  type        = bool
  default     = false
}

variable "enable_flow_logs" {
  description = "Enable VPC Flow Logs to CloudWatch Logs."
  type        = bool
  default     = true
}

variable "flow_log_retention_days" {
  description = "Days to retain VPC Flow Logs in CloudWatch."
  type        = number
  default     = 30
}

variable "cluster_name" {
  description = "EKS cluster name. Used to tag subnets for the AWS Load Balancer Controller and Karpenter."
  type        = string
}
