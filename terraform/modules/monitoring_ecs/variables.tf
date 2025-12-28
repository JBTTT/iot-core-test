variable "prefix" {}
variable "env" {}
variable "region" {}

variable "vpc_id" {}
variable "public_subnet_ids" {
  type = list(string)
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "allowed_cidrs" {
  type = list(string)
}
