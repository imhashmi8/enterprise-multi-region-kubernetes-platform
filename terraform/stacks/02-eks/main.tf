module "tags" {
  source = "../../modules/tagging"

  project     = var.project
  environment = var.environment
  region      = var.aws_region
  team        = var.team
  cost_center = var.cost_center
}

# Pull VPC outputs from the foundation stack — single source of truth
data "terraform_remote_state" "foundation" {
  backend = "s3"

  config = {
    bucket = var.state_bucket_name
    key    = "${var.aws_region}/01-foundation/terraform.tfstate"
    region = "us-east-1"
  }
}

locals {
  cluster_name = "${var.project}-${var.environment}-${var.aws_region}"
}

module "eks" {
  source = "../../modules/eks"

  cluster_name    = local.cluster_name
  cluster_version = var.cluster_version
  name_prefix     = module.tags.name_prefix

  vpc_id             = data.terraform_remote_state.foundation.outputs.vpc_id
  private_subnet_ids = data.terraform_remote_state.foundation.outputs.private_subnet_ids
  public_subnet_ids  = data.terraform_remote_state.foundation.outputs.public_subnet_ids

  cluster_endpoint_public_access       = var.cluster_endpoint_public_access
  cluster_endpoint_public_access_cidrs = var.cluster_endpoint_public_access_cidrs

  system_node_group_config      = var.system_node_group_config
  application_node_group_config = var.application_node_group_config

  admin_iam_roles = var.admin_iam_roles

  tags = module.tags.tags
}
