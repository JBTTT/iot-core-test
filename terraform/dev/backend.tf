terraform {
  backend "s3" {
    bucket         = "cet11-grp1-terraform-state"
    key            = "dev/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "cet11-grp1-iot-terraform-lock"
  }
}
