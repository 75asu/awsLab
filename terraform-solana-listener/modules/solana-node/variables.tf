variable "project_name" {
  description = "The name of the project"
  type        = string
}

variable "environment" {
  description = "The environment (e.g., dev, staging, prod)"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type for the Solana RPC node"
  type        = string
}

variable "ami_id" {
  description = "AMI ID for the Solana RPC node"
  type        = string
}

variable "vpc_id" {
  description = "The ID of the VPC where the EC2 instance will be created"
  type        = string
}

variable "subnet_id" {
  description = "The ID of the subnet where the EC2 instance will be created"
  type        = string
}

variable "security_group_ids" {
  description = "A list of security group IDs to associate with the EC2 instance"
  type        = list(string)
}

variable "instance_count" {
  description = "The number of EC2 instances to create"
  type        = number
  default     = 1
}

variable "tags" {
  description = "A map of tags to assign to the resources"
  type        = map(string)
  default     = {}
}
