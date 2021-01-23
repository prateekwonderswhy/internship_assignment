terraform {
  backend "s3" {
    bucket = "prateek-pratilipi-remote-backend"
    key    = "global/terraform.tfstate"
    region = "us-east-1"
  }
}