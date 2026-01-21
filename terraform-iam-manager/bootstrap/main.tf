module "state" {
  source = "../modules/state-management"

  bucket_prefix        = "tfstate-trading-platform-${var.environment}"
  dynamodb_table_name  = "tfstate-lock-trading-platform-${var.environment}"
}
