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
