variable "region" {
  description = "us-west-2"
}

variable "environment" {
  description = "Proof Of Concept Env"
}

//Networking
variable "vpc_cidr" {
  description = "VPC CIDR"
}

variable "public_subnets_cidr" {
  type        = list
  default = []
  description = "Public Subnet"
}

variable "private_subnets_cidr" {
  type        = list
  default = []
  description = "Private Subnet"
}
