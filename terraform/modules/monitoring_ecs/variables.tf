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

variable "cw_read_policy_name" {
  description = "CloudWatch read IAM policy name"
  type        = string
}

variable "task_role_name" {
  description = "ECS task role name for monitoring"
  type        = string
}

