terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
  # backend "s3" {
  #   bucket = "value"
  #   key = "value"
  #   region = "value"
  #   encrypt = false
  #   use_lockfile = false
  # }
}

provider "aws" {
  assume_role {
    role_arn = "arn:aws:iam::816583873447:role/ethos-cand-jesus-eduardo85-terraform"
  }
  # profile = "ethos"
  region  = "us-east-1"
  default_tags {
    tags = {
      "ethos:candidate" = "jesus-eduardo85"
      "ethos:project"   = "devops-test"
    }
  }
}