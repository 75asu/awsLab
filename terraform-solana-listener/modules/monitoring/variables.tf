variable "project_name" {
  description = "The name of the project"
  type        = string
}

variable "environment" {
  description = "The environment (e.g., dev, staging, prod)"
  type        = string
}

variable "autoscaling_group_name" {
  description = "The name of the autoscaling group for the Solana RPC nodes"
  type        = string
}

variable "kinesis_stream_name" {
  description = "The name of the Kinesis stream"
  type        = string
}

variable "tags" {
  description = "A map of tags to assign to the resources"
  type        = map(string)
  default     = {}
}
