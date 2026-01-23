variable "project_name" {
  description = "The name of the project"
  type        = string
}

variable "environment" {
  description = "The environment (e.g., dev, staging, prod)"
  type        = string
}

variable "vpc_id" {
  description = "The ID of the VPC"
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

variable "container_image" {
  description = "Docker image for the listener service"
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

variable "kinesis_stream_arn" {
  description = "The ARN of the Kinesis stream to consume from"
  type        = string
}

variable "tags" {
  description = "A map of tags to assign to the resources"
  type        = map(string)
  default     = {}
}
