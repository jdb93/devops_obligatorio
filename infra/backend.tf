terraform {
  backend "s3" {
    bucket = "180358-stockwiz-backend"
    key    = "staging/terraform.tfstate" #pasar a "default/terraform.tfstate" 
    region = "us-east-1"
  }
}