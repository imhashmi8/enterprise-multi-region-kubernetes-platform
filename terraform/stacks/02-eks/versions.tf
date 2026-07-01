terraform {
  required_version = ">= 1.7.0"

  backend "s3" {
    # Values injected at init time:
    #   terraform init \
    #     -backend-config=../../environments/<region>/backend.tfvars \
    #     -backend-config="key=<region>/02-eks/terraform.tfstate"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.40"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = module.tags.tags
  }
}
