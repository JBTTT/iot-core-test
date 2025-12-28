variable "prefix" {
  default = "jibin-own"
}

variable "env" {
  default = "dev"
}

variable "region" {
  default = "us-east-1"
}

variable "image_tag" {
  type        = string
  description = "Docker image tag for ECS task"
}
