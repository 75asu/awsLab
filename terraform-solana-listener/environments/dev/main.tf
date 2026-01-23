# Trading Platform Project 3 - Dev Environment

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

# Module Calls
module "solana_events_stream" {
  source    = "../../modules/kinesis-stream"
  providers = {
    aws = aws.project_3_provider
  }

  project_name = var.project_name
  environment  = var.environment
  stream_name  = var.kinesis_stream_name
  shard_count  = var.kinesis_shard_count
  
  tags = var.tags
}

module "solana_rpc_nodes" {
  source    = "../../modules/solana-node"
  providers = {
    aws = aws.project_3_provider
  }

  project_name      = var.project_name
  environment       = var.environment
  instance_type     = var.solana_instance_type
  ami_id            = var.solana_ami_id
  vpc_id            = data.terraform_remote_state.foundation.outputs.vpc_id
  subnet_id         = data.terraform_remote_state.foundation.outputs.private_subnet_ids[0]
  security_group_ids = [data.terraform_remote_state.foundation.outputs.ecs_security_group_id]
  instance_count    = var.solana_instance_count

  tags = var.tags
}

module "ecs_listener" {
  source    = "../../modules/ecs-listener"
  providers = {
    aws = aws.project_3_provider
  }

  project_name          = var.project_name
  environment           = var.environment
  vpc_id                = data.terraform_remote_state.foundation.outputs.vpc_id
  private_subnet_ids    = data.terraform_remote_state.foundation.outputs.private_subnet_ids
  ecs_security_group_id = data.terraform_remote_state.foundation.outputs.ecs_security_group_id
  container_image       = var.listener_container_image
  container_cpu         = var.listener_container_cpu
  container_memory      = var.listener_container_memory
  desired_count         = var.listener_desired_count
  kinesis_stream_arn    = module.solana_events_stream.stream_arn

  tags = var.tags
}

module "monitoring" {
  source    = "../../modules/monitoring"
  providers = {
    aws = aws.project_3_provider
  }

  project_name           = var.project_name
  environment            = var.environment
  autoscaling_group_name = module.solana_rpc_nodes.autoscaling_group_name
  kinesis_stream_name    = module.solana_events_stream.stream_name

  tags = var.tags
}
