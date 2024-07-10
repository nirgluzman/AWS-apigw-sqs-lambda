# AWS provider settings

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  # default tags to be applied to all resources
  default_tags {
    tags = {
      environment = "serverless"
    }
  }
}
