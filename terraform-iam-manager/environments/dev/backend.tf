terraform {
  backend "s3" {
    bucket         = "{{S3_BUCKET}}"
    key            = "iam/dev.tfstate"
    region         = "us-east-1"
    dynamodb_table = "{{DYNAMODB_TABLE}}"
    encrypt        = true
  }
}
