terraform {
  backend "s3" {
    bucket = "cet11-grp1-terraform-state"
    key    = "dev/terraform.tfstate"
    region = "us-east-1"

    # New Terraform backend locking method
    use_lockfile = true

    encrypt = true
  }
}
