variable "region" {
  description = "us-west-2"
}

variable "environment" {
  description = "Proof Of Concept Env"
}

//base
variable "vpc_cidr" {
  description = "VPC CIDR"
}

variable "public_subnets_cidr" {
  type        = list
  default = []
  description = "Public Subnets"
}

variable "private_subnets_cidr" {
  type        = list
  default = []
  description = "Private Subnets"
}
