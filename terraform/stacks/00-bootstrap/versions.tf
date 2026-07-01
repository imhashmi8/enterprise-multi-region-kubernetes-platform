terraform {
  required_version = ">= 1.7.0"

  # No remote backend — this stack CREATES the backend.
  # Its own state is stored locally and kept out of version control via .gitignore.

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.40"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      ManagedBy = "terraform"
      Stack     = "00-bootstrap"
      Project   = var.project
    }
  }
}
