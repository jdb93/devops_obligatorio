terraform {
  backend "s3" {
    bucket = "180358-stockwiz-backend"
    key    = "dev/terraform.tfstate"
    region = "us-east-1"
  }
}