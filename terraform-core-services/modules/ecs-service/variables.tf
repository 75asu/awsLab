variable "project_name" {
  description = "The name of the project"
  type        = string
}

variable "environment" {
  description = "The environment name (e.g., dev, staging, prod)"
  type        = string
}

variable "vpc_id" {
  description = "The ID of the VPC for the ECS service"
  type        = string
}

variable "private_subnet_ids" {
  description = "A list of private subnet IDs for the ECS tasks"
  type        = list(string)
}

variable "ecs_security_group_id" {
  description = "The ID of the security group for the ECS tasks"
  type        = string
}

variable "alb_target_group_arn" {
  description = "The ARN of the ALB target group for the ECS service"
  type        = string
}

variable "container_port" {
  description = "Port on which the application container listens"
  type        = number
}

variable "container_image" {
  description = "Docker image for the trading API service"
  type        = string
}

variable "container_cpu" {
  description = "CPU units for the Fargate task"
  type        = number
}

variable "container_memory" {
  description = "Memory (in MiB) for the Fargate task"
  type        = number
}

variable "desired_count" {
  description = "Desired number of tasks for the ECS service"
  type        = number
}

variable "rds_endpoint" {
  description = "Endpoint of the RDS database"
  type        = string
}

variable "rds_port" {
  description = "Port of the RDS database"
  type        = number
}

variable "rds_db_name" {
  description = "Name of the RDS database"
  type        = string
}

variable "rds_username" {
  description = "Username for the RDS database"
  type        = string
}

variable "rds_password_secret_arn" {
  description = "ARN of the Secrets Manager secret containing the RDS master password"
  type        = string
}

variable "elasticache_endpoint" {
  description = "Primary endpoint of the ElastiCache cluster"
  type        = string
}

variable "elasticache_port" {
  description = "Port of the ElastiCache cluster"
  type        = number
}

variable "tags" {
  description = "A map of tags to apply to all resources"
  type        = map(string)
  default     = {}
}
