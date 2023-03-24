terraform {
  required_version = ">=1.3.6"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
    }
  }

####  UPDATE this with your TFC organization name ####
  cloud {
    organization = "jaware-hc-demos"

    workspaces {
      name = "tf-resource-migration-example-oldwksp"
    }
  }
}


provider "aws" {
  region = var.aws_region
}