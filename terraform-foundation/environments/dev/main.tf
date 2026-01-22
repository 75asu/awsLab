# Trading Platform Foundation - Dev Environment

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

# VPC Networking
module "vpc" {
  source   = "../../modules/vpc"
  providers = {
    aws = aws.foundation_provider
  }
  
  project_name  = var.project_name
  environment   = var.environment
  vpc_cidr      = var.vpc_cidr
  
  availability_zones   = var.availability_zones
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  database_subnet_cidrs = var.database_subnet_cidrs
  
  tags = merge(var.tags, {
    ManagedBy = "Terraform"
  })
}

# Security Groups
module "security" {
  source   = "../../modules/security"
  providers = {
    aws = aws.foundation_provider
  }
  
  project_name  = var.project_name
  environment   = var.environment
  vpc_id        = module.vpc.vpc_id
  container_port = 8080  # Default for trading API
  
  tags = merge(var.tags, {
    ManagedBy = "Terraform"
  })
}

# IAM Roles for ECS
resource "aws_iam_role" "ecs_task_execution" {
  provider = aws.foundation_provider
  name = "${var.project_name}-${var.environment}-ecs-task-execution"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
  
  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-ecs-task-execution-role"
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution" {
  provider   = aws.foundation_provider
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Outputs
output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = module.vpc.private_subnet_ids
}

output "database_subnet_ids" {
  description = "Database subnet IDs"
  value       = module.vpc.database_subnet_ids
}

output "alb_security_group_id" {
  description = "ALB security group ID"
  value       = module.security.alb_security_group_id
}

output "ecs_security_group_id" {
  description = "ECS security group ID"
  value       = module.security.ecs_security_group_id
}

output "database_security_group_id" {
  description = "Database security group ID"
  value       = module.security.database_security_group_id
}
