terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  
  backend "s3" {
    bucket         = "tfstate-trading-platform-dev"
    key            = "foundation/dev/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "tfstate-lock-trading-platform-dev"
    encrypt        = true
  }
}

provider "aws" {
  region = "us-east-1"
}

provider "aws" {
  alias       = "foundation_provider"
  region      = "us-east-1"
  access_key  = local.ci_cd_credentials.access_key_id
  secret_key  = local.ci_cd_credentials.secret_access_key
  
  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}
