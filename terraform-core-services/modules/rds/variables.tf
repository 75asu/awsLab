variable "project_name" {
  description = "The name of the project"
  type        = string
}

variable "environment" {
  description = "The environment name (e.g., dev, staging, prod)"
  type        = string
}

variable "vpc_id" {
  description = "The ID of the VPC to deploy the RDS instance into"
  type        = string
}

variable "database_subnet_ids" {
  description = "A list of database subnet IDs for the RDS instance"
  type        = list(string)
}

variable "db_instance_class" {
  description = "DB instance type"
  type        = string
}

variable "db_allocated_storage" {
  description = "Allocated storage (GB) for the DB"
  type        = number
}

variable "db_name" {
  description = "Name of the database"
  type        = string
}

variable "db_username" {
  description = "Username for the database"
  type        = string
}

variable "db_password_secret_arn" {
  description = "ARN of the Secrets Manager secret containing the DB master password"
  type        = string
}

variable "db_security_group_id" {
  description = "The ID of the security group for the RDS instance"
  type        = string
}

variable "tags" {
  description = "A map of tags to apply to all resources"
  type        = map(string)
  default     = {}
}
