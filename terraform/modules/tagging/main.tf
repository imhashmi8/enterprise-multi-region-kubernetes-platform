locals {
  standard_tags = {
    Project     = var.project
    Environment = var.environment
    Region      = var.region
    Team        = var.team
    CostCenter  = var.cost_center
    ManagedBy   = "terraform"
  }

  tags = merge(local.standard_tags, var.additional_tags)
}
