variable "project" {
  description = "Name of the platform project. Used as a tag and name prefix."
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

variable "region" {
  description = "AWS region this resource lives in."
  type        = string
}

variable "team" {
  description = "Team that owns the resource."
  type        = string
  default     = "platform-engineering"
}

variable "cost_center" {
  description = "Cost center code for billing attribution."
  type        = string
  default     = "platform"
}

variable "additional_tags" {
  description = "Additional tags merged into the standard tag set."
  type        = map(string)
  default     = {}
}
