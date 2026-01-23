# Trading Platform Core Services - Dev Environment

# Data source for CI/CD user credentials from Secrets Manager
data "terraform_remote_state" "iam_manager" {
  backend = "s3"
  config = {
    bucket = "tfstate-trading-platform-dev"
    key    = "iam-manager/dev/terraform.tfstate"
    region = "us-east-1"
  }
}

data "aws_secretsmanager_secret_version" "ci_cd_credentials" {
  secret_id = data.terraform_remote_state.iam_manager.outputs.ci_cd_secret_arn
}

locals {
  ci_cd_credentials = jsondecode(data.aws_secretsmanager_secret_version.ci_cd_credentials.secret_string)
}

# Data source for VPC and Security Groups from Foundation project
data "terraform_remote_state" "foundation" {
  backend = "s3"
  config = {
    bucket = "tfstate-trading-platform-dev"
    key    = "foundation/dev/terraform.tfstate"
    region = "us-east-1"
  }
}

# Store RDS database master password in Secrets Manager
resource "aws_secretsmanager_secret" "rds_master_password" {
  provider = aws.core_services_provider
  name     = "${var.project_name}-${var.environment}-rds-master-password"
  description = "RDS master password for ${var.project_name}-${var.environment}"
  recovery_window_in_days = 0 # Ensure immediate deletion for development
  
  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-rds-master-password"
  })
}

resource "aws_secretsmanager_secret_version" "rds_master_password_version" {
  provider      = aws.core_services_provider
  secret_id     = aws_secretsmanager_secret.rds_master_password.id
  secret_string = random_password.rds_master_password_gen.result
}

resource "random_password" "rds_master_password_gen" {
  length  = 16
  special = true
  override_special = "!@#$%&*()"
}

# Module Calls
module "alb" {
  source    = "../../modules/alb"
  providers = {
    aws = aws.core_services_provider
  }

  project_name       = var.project_name
  environment        = var.environment
  vpc_id             = data.terraform_remote_state.foundation.outputs.vpc_id
  public_subnet_ids  = data.terraform_remote_state.foundation.outputs.public_subnet_ids
  alb_security_group_id = data.terraform_remote_state.foundation.outputs.alb_security_group_id
  
  tags = var.tags
}

module "rds" {
  source    = "../../modules/rds"
  providers = {
    aws = aws.core_services_provider
  }

  project_name         = var.project_name
  environment          = var.environment
  vpc_id               = data.terraform_remote_state.foundation.outputs.vpc_id
  database_subnet_ids  = data.terraform_remote_state.foundation.outputs.database_subnet_ids
  db_instance_class    = var.db_instance_class
  db_allocated_storage = var.db_allocated_storage
  db_name              = var.db_name
  db_username          = var.db_username
  db_password_secret_arn = aws_secretsmanager_secret.rds_master_password.arn # Pass secret ARN
  db_security_group_id = data.terraform_remote_state.foundation.outputs.database_security_group_id
  
  tags = var.tags
}

module "elasticache" {
  source    = "../../modules/elasticache"
  providers = {
    aws = aws.core_services_provider
  }

  project_name           = var.project_name
  environment            = var.environment
  vpc_id                 = data.terraform_remote_state.foundation.outputs.vpc_id
  private_subnet_ids     = data.terraform_remote_state.foundation.outputs.private_subnet_ids
  elasticache_node_type  = var.elasticache_node_type
  elasticache_num_cache_nodes = var.elasticache_num_cache_nodes
  elasticache_security_group_id = data.terraform_remote_state.foundation.outputs.database_security_group_id # Reusing DB SG
  
  tags = var.tags
}

module "ecs_services" {
  source    = "../../modules/ecs-service"
  providers = {
    aws = aws.core_services_provider
  }

  project_name      = var.project_name
  environment       = var.environment
  vpc_id            = data.terraform_remote_state.foundation.outputs.vpc_id
  private_subnet_ids = data.terraform_remote_state.foundation.outputs.private_subnet_ids
  ecs_security_group_id = data.terraform_remote_state.foundation.outputs.ecs_security_group_id
  alb_target_group_arn  = module.alb.alb_http_target_group_arn
  container_port    = var.container_port
  container_image   = var.container_image
  container_cpu     = var.container_cpu
  container_memory  = var.container_memory
  desired_count     = var.desired_count
  
  # Pass RDS details as environment variables to ECS task
  rds_endpoint      = module.rds.db_endpoint
  rds_port          = module.rds.db_port
  rds_db_name       = var.db_name
  rds_username      = var.db_username
  rds_password_secret_arn = aws_secretsmanager_secret.rds_master_password.arn

  # Pass ElastiCache details as environment variables to ECS task
  elasticache_endpoint = module.elasticache.primary_endpoint
  elasticache_port     = module.elasticache.primary_endpoint_port
  
  tags = var.tags
}
