variable "aws_region" {
  description = "AWS region for the state backend. Always use the primary region (us-east-1)."
  type        = string
  default     = "us-east-1"
}

variable "project" {
  description = "Short project name used in resource names."
  type        = string
  default     = "eks-platform"
}

variable "state_bucket_name" {
  description = "Globally unique S3 bucket name for Terraform remote state. Append your AWS account ID to ensure uniqueness."
  type        = string
}

variable "lock_table_name" {
  description = "DynamoDB table name for Terraform state locking."
  type        = string
  default     = "eks-platform-terraform-locks"
}

variable "log_retention_days" {
  description = "Days to retain S3 server access logs for the state bucket."
  type        = number
  default     = 90
}
