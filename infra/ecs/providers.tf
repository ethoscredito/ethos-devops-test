terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.60"
    }
  }
}

provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile

  default_tags {
    tags = {
      "ethos:candidate" = var.candidate_id
      "ethos:project"   = "devops-test"
      ManagedBy         = "Terraform"
    }
  }
}
