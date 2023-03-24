data "aws_vpc" "primary-vpc" {
  default = true
}

data "aws_region" "current" {
}

