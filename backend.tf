terraform {
  backend "s3" {
    bucket         = "chi-terra-prod-bucket"
    key            = "prod/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}