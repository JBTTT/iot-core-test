terraform {
  backend "s3" {
    bucket       = "jibin-own-terraform-state"
    key          = "dev/terraform.tfstate"
    region       = "us-east-1"
    use_lockfile = true
    encrypt      = true
  }
}
