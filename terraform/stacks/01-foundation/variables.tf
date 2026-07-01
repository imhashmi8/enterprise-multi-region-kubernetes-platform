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
  description = "Short project name used in resource names."
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

variable "vpc_cidr" {
  description = "IPv4 CIDR block for the VPC. Must be /16 and unique per region."
  type        = string
}

variable "availability_zones" {
  description = "List of 3 AZ suffix letters (e.g. [\"a\", \"b\", \"c\"])."
  type        = list(string)

  validation {
    condition     = length(var.availability_zones) == 3
    error_message = "Exactly 3 availability zones are required."
  }
}

variable "single_nat_gateway" {
  description = "Use a single NAT Gateway. Set true only for non-production to save cost."
  type        = bool
  default     = false
}

variable "cluster_name" {
  description = "EKS cluster name. Required for subnet tagging before the EKS stack runs."
  type        = string
}
