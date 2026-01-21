variable "project_name" {
  description = "Project name"
  type        = string
  default     = "trading-platform"
}

variable "environment" {
  description = "Environment"
  type        = string
  default     = "dev"
}

variable "owner" {
  description = "Owner"
  type        = string
  default     = "phoenix-admin"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}
