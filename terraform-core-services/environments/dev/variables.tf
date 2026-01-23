variable "project_name" {
  description = "The name of the project"
  type        = string
  default     = "trading-platform"
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

# ECS specific variables
variable "container_port" {
  description = "Port on which the application container listens"
  type        = number
  default     = 8080
}

variable "container_image" {
  description = "Docker image for the trading API service"
  type        = string
  default     = "nginx:latest" # Placeholder, will be updated with actual API image
}

variable "container_cpu" {
  description = "CPU units for the Fargate task"
  type        = number
  default     = 256 # 0.25 vCPU
}

variable "container_memory" {
  description = "Memory (in MiB) for the Fargate task"
  type        = number
  default     = 512 # 0.5 GB
}

variable "desired_count" {
  description = "Desired number of tasks for the ECS service"
  type        = number
  default     = 1
}

# Database specific variables
variable "db_instance_class" {
  description = "DB instance type"
  type        = string
  default     = "db.t3.micro"
}

variable "db_allocated_storage" {
  description = "Allocated storage (GB) for the DB"
  type        = number
  default     = 20
}

variable "db_name" {
  description = "Name of the database"
  type        = string
  default     = "tradingdb"
}

variable "db_username" {
  description = "Username for the database"
  type        = string
  default     = "admin"
}

# ElastiCache specific variables
variable "elasticache_node_type" {
  description = "ElastiCache node type"
  type        = string
  default     = "cache.t3.micro"
}

variable "elasticache_num_cache_nodes" {
  description = "Number of cache nodes in the ElastiCache cluster"
  type        = number
  default     = 1
}
