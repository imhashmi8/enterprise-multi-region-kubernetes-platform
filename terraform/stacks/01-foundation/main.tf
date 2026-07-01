module "tags" {
  source = "../../modules/tagging"

  project     = var.project
  environment = var.environment
  region      = var.aws_region
  team        = var.team
  cost_center = var.cost_center
}

module "vpc" {
  source = "../../modules/vpc"

  name_prefix        = module.tags.name_prefix
  vpc_cidr           = var.vpc_cidr
  availability_zones = var.availability_zones
  single_nat_gateway = var.single_nat_gateway
  cluster_name       = var.cluster_name
  tags               = module.tags.tags
}
