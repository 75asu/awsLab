terraform {
  backend "s3" {
    bucket         = "tfstate-trading-platform-dev"
    key            = "iam-manager/dev/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "tfstate-lock-trading-platform-dev"
    encrypt        = true
  }
}
