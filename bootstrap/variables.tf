variable "prefix" {
  description = "Project prefix for tagging"
  default     = "cet11-grp1"
}

variable "region" {
  description = "AWS region"
  default     = "us-east-1"
}

variable "state_bucket_name" {
  description = "S3 bucket name for Terraform remote state"
  default     = "cet11-grp1-terraform-state"
}

variable "lock_table_name" {
  description = "DynamoDB table for Terraform state lock"
  default     = "cet11-grp1-iot-terraform-lock"
}
