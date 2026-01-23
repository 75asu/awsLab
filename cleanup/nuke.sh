#!/bin/bash
# AWS Nuke - Delete everything in us-east-1, no questions
# Use when terraform state is lost or resources are orphaned

REGION="us-east-1"

echo "=== AWS NUKE - Region: $REGION ==="
echo ""

# 1. NAT Gateways ($$$ - ~$32/month each)
echo "--- NAT Gateways ---"
for nat in $(aws ec2 describe-nat-gateways --region $REGION --filter "Name=state,Values=available,pending" --query 'NatGateways[].NatGatewayId' --output text 2>/dev/null); do
  echo "Deleting NAT Gateway: $nat"
  aws ec2 delete-nat-gateway --nat-gateway-id $nat --region $REGION 2>/dev/null || true
done

# 2. Elastic IPs ($$$ when unassociated)
echo "--- Elastic IPs ---"
for eip in $(aws ec2 describe-addresses --region $REGION --query 'Addresses[?AssociationId==`null`].AllocationId' --output text 2>/dev/null); do
  echo "Releasing EIP: $eip"
  aws ec2 release-address --allocation-id $eip --region $REGION 2>/dev/null || true
done

# 3. Load Balancers
echo "--- Load Balancers ---"
for alb in $(aws elbv2 describe-load-balancers --region $REGION --query 'LoadBalancers[].LoadBalancerArn' --output text 2>/dev/null); do
  echo "Deleting ALB: $alb"
  aws elbv2 delete-load-balancer --load-balancer-arn "$alb" --region $REGION 2>/dev/null || true
done

# 4. ECS - Services then Clusters
echo "--- ECS ---"
for cluster in $(aws ecs list-clusters --region $REGION --query 'clusterArns[]' --output text 2>/dev/null); do
  for svc in $(aws ecs list-services --cluster $cluster --region $REGION --query 'serviceArns[]' --output text 2>/dev/null); do
    echo "Stopping ECS service: $svc"
    aws ecs update-service --cluster $cluster --service $svc --desired-count 0 --region $REGION 2>/dev/null || true
    aws ecs delete-service --cluster $cluster --service $svc --force --region $REGION 2>/dev/null || true
  done
  echo "Deleting ECS cluster: $cluster"
  aws ecs delete-cluster --cluster $cluster --region $REGION 2>/dev/null || true
done

# 5. RDS Instances & Clusters
echo "--- RDS ---"
for rds in $(aws rds describe-db-instances --region $REGION --query 'DBInstances[].DBInstanceIdentifier' --output text 2>/dev/null); do
  echo "Deleting RDS instance: $rds"
  aws rds delete-db-instance --db-instance-identifier $rds --skip-final-snapshot --delete-automated-backups --region $REGION 2>/dev/null || true
done
for cluster in $(aws rds describe-db-clusters --region $REGION --query 'DBClusters[].DBClusterIdentifier' --output text 2>/dev/null); do
  echo "Deleting RDS cluster: $cluster"
  aws rds delete-db-cluster --db-cluster-identifier $cluster --skip-final-snapshot --region $REGION 2>/dev/null || true
done

# 6. ElastiCache
echo "--- ElastiCache ---"
for cache in $(aws elasticache describe-cache-clusters --region $REGION --query 'CacheClusters[].CacheClusterId' --output text 2>/dev/null); do
  echo "Deleting ElastiCache: $cache"
  aws elasticache delete-cache-cluster --cache-cluster-id $cache --region $REGION 2>/dev/null || true
done

# 7. Kinesis
echo "--- Kinesis ---"
for stream in $(aws kinesis list-streams --region $REGION --query 'StreamNames[]' --output text 2>/dev/null); do
  echo "Deleting Kinesis stream: $stream"
  aws kinesis delete-stream --stream-name $stream --region $REGION 2>/dev/null || true
done

# 8. Auto Scaling Groups
echo "--- Auto Scaling Groups ---"
for asg in $(aws autoscaling describe-auto-scaling-groups --region $REGION --query 'AutoScalingGroups[].AutoScalingGroupName' --output text 2>/dev/null); do
  echo "Deleting ASG: $asg"
  aws autoscaling delete-auto-scaling-group --auto-scaling-group-name $asg --force-delete --region $REGION 2>/dev/null || true
done

# 9. Launch Templates
echo "--- Launch Templates ---"
for lt in $(aws ec2 describe-launch-templates --region $REGION --query 'LaunchTemplates[].LaunchTemplateId' --output text 2>/dev/null); do
  echo "Deleting Launch Template: $lt"
  aws ec2 delete-launch-template --launch-template-id $lt --region $REGION 2>/dev/null || true
done

# Wait for NAT gateways to delete before VPC cleanup
sleep 5

# 10. VPCs (non-default)
echo "--- VPCs ---"
for vpc in $(aws ec2 describe-vpcs --region $REGION --filters "Name=isDefault,Values=false" --query 'Vpcs[].VpcId' --output text 2>/dev/null); do
  echo "Cleaning VPC: $vpc"

  # VPC Endpoints
  for ep in $(aws ec2 describe-vpc-endpoints --region $REGION --filters "Name=vpc-id,Values=$vpc" --query 'VpcEndpoints[].VpcEndpointId' --output text 2>/dev/null); do
    aws ec2 delete-vpc-endpoints --vpc-endpoint-ids $ep --region $REGION 2>/dev/null || true
  done

  # Network Interfaces
  for eni in $(aws ec2 describe-network-interfaces --region $REGION --filters "Name=vpc-id,Values=$vpc" --query 'NetworkInterfaces[].NetworkInterfaceId' --output text 2>/dev/null); do
    att=$(aws ec2 describe-network-interfaces --region $REGION --network-interface-ids $eni --query 'NetworkInterfaces[0].Attachment.AttachmentId' --output text 2>/dev/null)
    [[ "$att" != "None" && -n "$att" ]] && aws ec2 detach-network-interface --attachment-id $att --force --region $REGION 2>/dev/null || true
    sleep 1
    aws ec2 delete-network-interface --network-interface-id $eni --region $REGION 2>/dev/null || true
  done

  # Internet Gateway
  for igw in $(aws ec2 describe-internet-gateways --region $REGION --filters "Name=attachment.vpc-id,Values=$vpc" --query 'InternetGateways[].InternetGatewayId' --output text 2>/dev/null); do
    aws ec2 detach-internet-gateway --internet-gateway-id $igw --vpc-id $vpc --region $REGION 2>/dev/null || true
    aws ec2 delete-internet-gateway --internet-gateway-id $igw --region $REGION 2>/dev/null || true
  done

  # Subnets
  for subnet in $(aws ec2 describe-subnets --region $REGION --filters "Name=vpc-id,Values=$vpc" --query 'Subnets[].SubnetId' --output text 2>/dev/null); do
    aws ec2 delete-subnet --subnet-id $subnet --region $REGION 2>/dev/null || true
  done

  # Route Tables (non-main)
  for rt in $(aws ec2 describe-route-tables --region $REGION --filters "Name=vpc-id,Values=$vpc" --query 'RouteTables[?Associations[0].Main!=`true`].RouteTableId' --output text 2>/dev/null); do
    for assoc in $(aws ec2 describe-route-tables --region $REGION --route-table-ids $rt --query 'RouteTables[0].Associations[?!Main].RouteTableAssociationId' --output text 2>/dev/null); do
      aws ec2 disassociate-route-table --association-id $assoc --region $REGION 2>/dev/null || true
    done
    aws ec2 delete-route-table --route-table-id $rt --region $REGION 2>/dev/null || true
  done

  # Security Groups (non-default)
  for sg in $(aws ec2 describe-security-groups --region $REGION --filters "Name=vpc-id,Values=$vpc" --query 'SecurityGroups[?GroupName!=`default`].GroupId' --output text 2>/dev/null); do
    aws ec2 delete-security-group --group-id $sg --region $REGION 2>/dev/null || true
  done

  # Network ACLs (non-default)
  for nacl in $(aws ec2 describe-network-acls --region $REGION --filters "Name=vpc-id,Values=$vpc" --query 'NetworkAcls[?IsDefault==`false`].NetworkAclId' --output text 2>/dev/null); do
    aws ec2 delete-network-acl --network-acl-id $nacl --region $REGION 2>/dev/null || true
  done

  # Delete VPC
  echo "Deleting VPC: $vpc"
  aws ec2 delete-vpc --vpc-id $vpc --region $REGION 2>/dev/null || echo "  Failed - may have remaining dependencies"
done

# 11. Secrets Manager
echo "--- Secrets ---"
for secret in $(aws secretsmanager list-secrets --region $REGION --query 'SecretList[].Name' --output text 2>/dev/null); do
  echo "Deleting secret: $secret"
  aws secretsmanager delete-secret --secret-id $secret --force-delete-without-recovery --region $REGION 2>/dev/null || true
done

# 12. CloudWatch Log Groups (project-related)
echo "--- CloudWatch Logs ---"
for lg in $(aws logs describe-log-groups --region $REGION --query 'logGroups[].logGroupName' --output text 2>/dev/null); do
  if [[ "$lg" == *"trading"* ]] || [[ "$lg" == *"solana"* ]] || [[ "$lg" == *"ecs"* ]]; then
    echo "Deleting log group: $lg"
    aws logs delete-log-group --log-group-name "$lg" --region $REGION 2>/dev/null || true
  fi
done

# Global resources (IAM, S3)
echo ""
echo "--- IAM Users ---"
for user in terraform-admin-dev ci-cd-dev; do
  if aws iam get-user --user-name $user 2>/dev/null; then
    echo "Deleting IAM user: $user"
    for key in $(aws iam list-access-keys --user-name $user --query 'AccessKeyMetadata[].AccessKeyId' --output text 2>/dev/null); do
      aws iam delete-access-key --user-name $user --access-key-id $key
    done
    for policy in $(aws iam list-attached-user-policies --user-name $user --query 'AttachedPolicies[].PolicyArn' --output text 2>/dev/null); do
      aws iam detach-user-policy --user-name $user --policy-arn $policy
    done
    for policy in $(aws iam list-user-policies --user-name $user --query 'PolicyNames[]' --output text 2>/dev/null); do
      aws iam delete-user-policy --user-name $user --policy-name $policy
    done
    aws iam delete-user --user-name $user
  fi
done

echo "--- IAM Roles ---"
for role in trading-platform-dev-ecs-task-execution github-actions-role solana-listener-dev-listener-task-role; do
  if aws iam get-role --role-name $role 2>/dev/null; then
    echo "Deleting IAM role: $role"
    for policy in $(aws iam list-attached-role-policies --role-name $role --query 'AttachedPolicies[].PolicyArn' --output text 2>/dev/null); do
      aws iam detach-role-policy --role-name $role --policy-arn $policy
    done
    for policy in $(aws iam list-role-policies --role-name $role --query 'PolicyNames[]' --output text 2>/dev/null); do
      aws iam delete-role-policy --role-name $role --policy-name $policy
    done
    aws iam delete-role --role-name $role
  fi
done

echo "--- OIDC Providers ---"
for oidc in $(aws iam list-open-id-connect-providers --query 'OpenIDConnectProviderList[].Arn' --output text 2>/dev/null); do
  if [[ "$oidc" == *"github"* ]] || [[ "$oidc" == *"token.actions"* ]]; then
    echo "Deleting OIDC: $oidc"
    aws iam delete-open-id-connect-provider --open-id-connect-provider-arn $oidc
  fi
done

echo "--- S3 Buckets ---"
for bucket in $(aws s3api list-buckets --query 'Buckets[].Name' --output text 2>/dev/null); do
  if [[ "$bucket" == *"tfstate"* ]] || [[ "$bucket" == *"trading"* ]] || [[ "$bucket" == *"solana"* ]]; then
    echo "Deleting S3 bucket: $bucket"
    aws s3 rm s3://$bucket --recursive 2>/dev/null || true
    aws s3api delete-objects --bucket $bucket --delete "$(aws s3api list-object-versions --bucket $bucket --query '{Objects: Versions[].{Key:Key,VersionId:VersionId}}' --output json 2>/dev/null)" 2>/dev/null || true
    aws s3api delete-objects --bucket $bucket --delete "$(aws s3api list-object-versions --bucket $bucket --query '{Objects: DeleteMarkers[].{Key:Key,VersionId:VersionId}}' --output json 2>/dev/null)" 2>/dev/null || true
    aws s3api delete-bucket --bucket $bucket 2>/dev/null || true
  fi
done

echo "--- DynamoDB ---"
for table in $(aws dynamodb list-tables --region $REGION --query 'TableNames[]' --output text 2>/dev/null); do
  if [[ "$table" == *"tfstate"* ]] || [[ "$table" == *"trading"* ]]; then
    echo "Deleting DynamoDB table: $table"
    aws dynamodb delete-table --table-name $table --region $REGION 2>/dev/null || true
  fi
done

echo ""
echo "=== NUKE COMPLETE ==="
echo "Run again if VPC deletion failed (dependencies need time to delete)"
