variable "project_name" {
  description = "The name of the project"
  type        = string
  default     = "solana-listener"
}

variable "environment" {
  description = "The environment name (e.g., dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "region" {
  description = "AWS region for deployment"
  type        = string
  default     = "us-east-1"
}

variable "tags" {
  description = "A map of tags to apply to all resources"
  type        = map(string)
  default = {
    Owner = "phoenix-admin"
  }
}

# Kinesis specific variables
variable "kinesis_stream_name" {
  description = "Name of the Kinesis stream for Solana events"
  type        = string
  default     = "solana-events"
}

variable "kinesis_shard_count" {
  description = "Number of shards for the Kinesis stream"
  type        = number
  default     = 1
}

# Solana RPC Node specific variables
variable "solana_instance_type" {
  description = "EC2 instance type for the Solana RPC node"
  type        = string
  default     = "t3.large"
}

variable "solana_ami_id" {
  description = "AMI ID for the Solana RPC node. This is a hardcoded value for Ubuntu 22.04 LTS in us-east-1. It is not guaranteed to be the latest version. In a production environment, this should be dynamically fetched."
  type        = string
  default     = "ami-0c55b159cbfafe1f0"
}

variable "solana_instance_count" {
  description = "The number of Solana RPC node instances to create"
  type        = number
  default     = 1
}

# ECS Listener specific variables
variable "listener_container_image" {
  description = "Docker image for the listener service"
  type        = string
  default     = "nginx:latest" # Placeholder, will be updated with actual listener image
}

variable "listener_container_cpu" {
  description = "CPU units for the Fargate task"
  type        = number
  default     = 256 # 0.25 vCPU
}

variable "listener_container_memory" {
  description = "Memory (in MiB) for the Fargate task"
  type        = number
  default     = 512 # 0.5 GB
}

variable "listener_desired_count" {
  description = "Desired number of tasks for the ECS listener service"
  type        = number
  default     = 1
}
