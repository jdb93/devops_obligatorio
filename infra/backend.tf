terraform {
  backend "s3" {
    bucket = "180358-stockwiz-backend"
    key    = "default/terraform.tfstate"
    region = "us-east-1"
  }
}