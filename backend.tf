terraform {
  backend "s3" {
    bucket         = "shire-terraform"
    key            = "terraform"
    region         = "us-east-1"
    dynamodb_table = "terraform-lock"
  }
}
