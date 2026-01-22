# modules/iam-user/outputs.tf
output "user_arn" {
  description = "ARN of the IAM user"
  value       = aws_iam_user.this.arn
}

output "access_key_id" {
  description = "Access key ID for the IAM user"
  value       = aws_iam_access_key.this.id
  sensitive   = true
}

output "secret_access_key" {
  description = "Secret access key for the IAM user"
  value       = aws_iam_access_key.this.secret
  sensitive   = true
}

output "secret_arn" {
  description = "ARN of the secret in Secrets Manager"
  value       = try(aws_secretsmanager_secret.this[0].arn, null)
}
