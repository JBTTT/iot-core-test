variable "iot_s3_role_name" {
  description = "IAM role name for IoT S3 access"
  type        = string
}

variable "iot_s3_policy_name" {
  description = "IAM policy name for IoT S3 access"
  type        = string
}

variable "s3_bucket" {
  type = string
}

variable "prefix" {
  type = string
}

variable "env" {
  type = string
}
