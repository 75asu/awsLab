# modules/iam-user/variables.tf
variable "user_name" {
  description = "Name of the IAM user"
  type        = string
}

variable "path" {
  description = "Path for the IAM user"
  type        = string
  default     = "/"
}

variable "policy_arns" {
  description = "List of policy ARNs to attach to the user"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags to apply to the IAM user"
  type        = map(string)
  default     = {}
}

variable "create_secret" {
  description = "Whether to create a secret in Secrets Manager with the user's access keys"
  type        = bool
  default     = false
}
