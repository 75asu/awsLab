output "state_bucket" {
  value = module.state.s3_bucket_name
}

output "state_lock_table" {
  value = module.state.dynamodb_table_name
}
