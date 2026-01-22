# modules/iam-user/main.tf
resource "aws_iam_user" "this" {
  name = var.user_name
  path = var.path
  
  tags = merge(var.tags, {
    ManagedBy = "Terraform"
    Module    = "iam-user"
  })
}

resource "aws_iam_access_key" "this" {
  user = aws_iam_user.this.name
}

resource "aws_iam_user_policy_attachment" "this" {
  for_each = toset(var.policy_arns)
  
  user       = aws_iam_user.this.name
  policy_arn = each.value
}

resource "aws_secretsmanager_secret" "this" {
  count = var.create_secret ? 1 : 0

  name                    = var.user_name
  recovery_window_in_days = 0
  tags                    = var.tags
}

resource "aws_secretsmanager_secret_version" "this" {
  count = var.create_secret ? 1 : 0

  secret_id     = aws_secretsmanager_secret.this[0].id
  secret_string = jsonencode({
    access_key_id     = aws_iam_access_key.this.id,
    secret_access_key = aws_iam_access_key.this.secret
  })
}
