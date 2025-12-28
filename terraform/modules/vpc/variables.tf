variable "prefix" { type = string }
variable "env" { type = string }
variable "region" { type = string }

variable "allowed_ssh_cidrs" {
  type    = list(string)
  default = ["0.0.0.0/0"]
}
