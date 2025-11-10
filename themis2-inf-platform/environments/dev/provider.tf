terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.95.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = var.use_region

  default_tags {
    tags = {
      systemname          = var.sys_name
      environment         = var.env
      create-by-terraform = "true"
    }
  }
}

# Cloudfront用プロバイダー設定
provider "aws" {
  alias  = "virginia"
  region = "us-east-1"

  default_tags {
    tags = {
      systemname          = var.sys_name
      environment         = var.env
      create-by-terraform = "true"
    }
  }
}
