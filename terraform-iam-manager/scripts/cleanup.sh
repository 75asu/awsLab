#!/bin/bash
set -e

# Configuration
ENVIRONMENT="${1:-dev}"  # Accept environment as parameter
PROJECT_NAME="trading-platform"

echo "=== Cleaning up $ENVIRONMENT environment ==="

# 1. Delete DynamoDB tables
echo "Checking DynamoDB tables..."
aws dynamodb list-tables --query "TableNames[?contains(@, 'tfstate-lock-$PROJECT_NAME-$ENVIRONMENT')]" --output text | \
while read -r TABLE; do
    echo "Deleting DynamoDB table: $TABLE"
    aws dynamodb delete-table --table-name "$TABLE"
done

# 2. Delete S3 buckets
echo "Checking S3 buckets..."
aws s3 ls | grep "tfstate-$PROJECT_NAME-$ENVIRONMENT" | while read -r line; do
    BUCKET=$(echo "$line" | awk '{print $3}')
    echo "Deleting S3 bucket: $BUCKET"
    
    # Empty bucket
    aws s3 rm s3://$BUCKET --recursive 2>/dev/null || true
    # Delete bucket
    aws s3 rb s3://$BUCKET --force 2>/dev/null || true
done

# 3. Delete IAM resources (environment-specific)
echo "Checking IAM resources..."
aws iam list-users --query "Users[?contains(UserName, '-$ENVIRONMENT')].UserName" --output text | \
while read -r USER; do
    echo "Deleting IAM user: $USER"
    
    # Delete access keys
    aws iam list-access-keys --user-name "$USER" --query 'AccessKeyMetadata[].AccessKeyId' --output text 2>/dev/null | \
    while read KEY; do
        aws iam delete-access-key --user-name "$USER" --access-key-id "$KEY" 2>/dev/null || true
    done
    
    # Detach policies
    aws iam list-attached-user-policies --user-name "$USER" --query 'AttachedPolicies[].PolicyArn' --output text 2>/dev/null | \
    while read POLICY; do
        aws iam detach-user-policy --user-name "$USER" --policy-arn "$POLICY" 2>/dev/null || true
    done
    
    # Delete user
    aws iam delete-user --user-name "$USER" 2>/dev/null || true
done

# 4. Delete other resources (add as project grows)
# - EC2 instances
# - RDS instances
# - ECS clusters
# - etc.

echo "=== Cleanup complete for $ENVIRONMENT ==="
sleep 5  # Brief wait for AWS propagation
