variable "region" {
  default = "us-east-1"
}

variable "bucket_name" {
  default = "jibin-own-terraform-state"
}

variable "lock_table_name" {
  default = "terraform-locks"
}
