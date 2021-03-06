variable "environment" {
  description = "The Deployment environment"
}

variable "vpc_cidr" {
  description = "VPC CIDR"
}

variable "public_subnets_cidr" {
  type = list
  default = []
  description = "Public Subnet"
}

variable "private_subnets_cidr" {
  type = list
  default = []
  description = "Private Subnet"
}

variable "region" {
  description = "us-west-2"
}

variable "availability_zones" {
  type = list
  description = "multi-AZ resources"
}

