terraform {
  backend "s3" {
    bucket         = "tfstate-trading-platform-dev-glorious-marmot"  # Will be replaced by GitHub Actions
    key            = "iam/dev.tfstate"
    region         = "us-east-1"
    dynamodb_table = "tfstate-lock-trading-platform-dev"   # Will be replaced by GitHub Actions
    encrypt        = true
  }
}
