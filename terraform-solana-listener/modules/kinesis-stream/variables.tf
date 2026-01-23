variable "project_name" {
  description = "The name of the project"
  type        = string
}

variable "environment" {
  description = "The environment (e.g., dev, staging, prod)"
  type        = string
}

variable "stream_name" {
  description = "The name of the Kinesis stream"
  type        = string
}

variable "shard_count" {
  description = "The number of shards for the Kinesis stream"
  type        = number
}

variable "tags" {
  description = "A map of tags to assign to the resources"
  type        = map(string)
  default     = {}
}
