# dev environment - IAM Users
module "terraform_admin" {
  source = "../../modules/iam-user"
  
  user_name = "terraform-admin-dev"
  
  policy_arns = [
    "arn:aws:iam::aws:policy/AmazonS3FullAccess",
    "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess",
    "arn:aws:iam::aws:policy/IAMFullAccess",
    "arn:aws:iam::aws:policy/AmazonVPCFullAccess",
    "arn:aws:iam::aws:policy/AWSCloudFormationFullAccess",
    "arn:aws:iam::aws:policy/AmazonEC2FullAccess",
    "arn:aws:iam::aws:policy/AmazonRDSFullAccess",
    "arn:aws:iam::aws:policy/AmazonElastiCacheFullAccess",
  ]
  
  tags = {
    Environment = "dev"
    Project     = "trading-platform"
    Owner       = "phoenix-admin"
  }
}

module "ci_cd_user" {
  source = "../../modules/iam-user"
  
  user_name     = "ci-cd-dev"
  path          = "/service/"
  create_secret = true
  
  policy_arns = [
    "arn:aws:iam::aws:policy/AmazonS3FullAccess",
    "arn:aws:iam::aws:policy/AmazonEC2FullAccess",
    "arn:aws:iam::aws:policy/AmazonVPCFullAccess",
    "arn:aws:iam::aws:policy/IAMFullAccess",
    "arn:aws:iam::aws:policy/AmazonECS_FullAccess",
    "arn:aws:iam::aws:policy/AmazonKinesisFullAccess",
    "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess",
    "arn:aws:iam::aws:policy/AutoScalingFullAccess"
  ]
  
  tags = {
    Environment = "dev"
    Project     = "trading-platform"
    Purpose     = "ci-cd"
  }
}
