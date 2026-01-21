variable "bucket_prefix" {
  description = "Prefix for the S3 bucket name (must be globally unique)"
  type        = string
  default     = "terraform-state"
}

variable "dynamodb_table_name" {
  description = "Name of the DynamoDB table for state locking"
  type        = string
  default     = "terraform-state-lock"
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
