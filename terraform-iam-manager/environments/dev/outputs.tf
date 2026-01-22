output "terraform_admin_access_key_id" {
  description = "Access key ID for terraform admin"
  value       = module.terraform_admin.access_key_id
  sensitive   = true
}

output "terraform_admin_secret_access_key" {
  description = "Secret access key for terraform admin"
  value       = module.terraform_admin.secret_access_key
  sensitive   = true
}

output "ci_cd_access_key_id" {
  description = "Access key ID for CI/CD user"
  value       = module.ci_cd_user.access_key_id
  sensitive   = true
}

output "ci_cd_secret_access_key" {
  description = "Secret access key for CI/CD user"
  value       = module.ci_cd_user.secret_access_key
  sensitive   = true
}

output "ci_cd_secret_arn" {
  description = "ARN of the secret in Secrets Manager for the CI/CD user"
  value       = module.ci_cd_user.secret_arn
}
