#!/bin/bash

# This script performs a comprehensive cleanup of all project-related AWS resources,
# including those not managed by Terraform state.
# It should be run with credentials that have administrative permissions.

set -e # Exit immediately if a command exits with a non-zero status, unless explicitly handled

PROJECT_NAME="trading-platform"
ENVIRONMENT_NAME="dev"
TAG_FILTERS=(
    "Name=tag:Project,Values=${PROJECT_NAME}"
    "Name=tag:Environment,Values=${ENVIRONMENT_NAME}"
)

# Ensure jq is installed
if ! command -v jq &> /dev/null
then
    echo "Error: jq is not installed. Please install it (e.g., sudo apt-get install jq) and try again."
    exit 1
fi

# Function to delete S3 buckets matching tags and handling versioning
delete_s3_buckets() {
    local region=$1
    echo "Cleaning up S3 buckets in ${region}..."
    BUCKETS_TO_DELETE=$(aws s3api list-buckets --region "${region}" --query "Buckets[?starts_with(Name, 'tfstate-${PROJECT_NAME}-${ENVIRONMENT_NAME}')].Name" --output text || true)

    for BUCKET in ${BUCKETS_TO_DELETE}; do
        echo "  - Deleting content and bucket ${BUCKET}..."
        
        # Delete all object versions
        aws s3api list-object-versions --bucket "${BUCKET}" --region "${region}" --query 'Versions[].{Key:Key,VersionId:VersionId}' --output json | \
            jq -r '.[] | .Key + "\n" + .VersionId' | \
            while read -r KEY && read -r VERSION_ID; do
                aws s3api delete-object --bucket "${BUCKET}" --key "${KEY}" --version-id "${VERSION_ID}" --region "${region}" || true
            done || true # jq or while loop might exit with non-zero if no input

        # Delete all delete markers
        aws s3api list-object-versions --bucket "${BUCKET}" --region "${region}" --query 'DeleteMarkers[].{Key:Key,VersionId:VersionId}' --output json | \
            jq -r '.[] | .Key + "\n" + .VersionId' | \
            while read -r KEY && read -r VERSION_ID; do
                aws s3api delete-object --bucket "${BUCKET}" --key "${KEY}" --version-id "${VERSION_ID}" --region "${region}" || true
            done || true # jq or while loop might exit with non-zero if no input
        
        # Finally, delete the empty bucket
        aws s3api delete-bucket --bucket "${BUCKET}" --region "${region}" || true
        echo "    Deleted bucket ${BUCKET}."
    done
}

# Function to delete DynamoDB tables matching tags
delete_dynamodb_tables() {
    local region=$1
    echo "Cleaning up DynamoDB tables in ${region}..."
    # List all tables, then filter by name matching our pattern
    TABLES_TO_DELETE=$(aws dynamodb list-tables --region "${region}" --query "TableNames[]" --output text | grep "tfstate-lock-${PROJECT_NAME}-${ENVIRONMENT_NAME}" || true)

    for TABLE in ${TABLES_TO_DELETE}; do
        echo "  - Deleting table ${TABLE}..."
        aws dynamodb delete-table --table-name "${TABLE}" --region "${region}" || true
        echo "    Deleted table ${TABLE}."
    done
}

# Function to delete Secrets Manager secrets by tag
delete_secrets_manager_secrets() {
    local region=$1
    echo "Cleaning up Secrets Manager secrets in ${region}..."
    # Secrets Manager tags are not directly queryable with list-secrets,
    # so we filter by name pattern.
    SECRETS_TO_DELETE=$(aws secretsmanager list-secrets --region "${region}" --query "SecretList[?starts_with(Name, 'ci-cd-${ENVIRONMENT_NAME}') || starts_with(Name, '${PROJECT_NAME}-${ENVIRONMENT_NAME}')].ARN" --output text || true)

    for SECRET_ARN in ${SECRETS_TO_DELETE}; do
        echo "  - Deleting secret ${SECRET_ARN}..."
        # Use --force-delete-without-recovery for immediate deletion
        aws secretsmanager delete-secret --secret-id "${SECRET_ARN}" --force-delete-without-recovery --region "${region}" || true
        echo "    Deleted secret ${SECRET_ARN}."
    done
}

# Function to delete IAM Users and their associated resources by tag
delete_iam_users() {
    echo "Cleaning up IAM Users..."
    USERS_TO_DELETE=$(aws iam list-users --query "Users[?contains(Tags[?Key=='Project'].Value | [0], '${PROJECT_NAME}') && contains(Tags[?Key=='Environment'].Value | [0], '${ENVIRONMENT_NAME}')].UserName" --output text || true)

    for USER in ${USERS_TO_DELETE}; do
        echo "  - Deleting user ${USER}..."
        # Delete access keys
        for AK in $(aws iam list-access-keys --user-name "${USER}" --query 'AccessKeyMetadata[*].AccessKeyId' --output text || true); do 
            aws iam delete-access-key --user-name "${USER}" --access-key-id "${AK}" || true
        done
        # Detach policies
        for POLICY_ARN in $(aws iam list-attached-user-policies --user-name "${USER}" --query 'AttachedPolicies[*].PolicyArn' --output text || true); do 
            aws iam detach-user-policy --user-name "${USER}" --policy-arn "${POLICY_ARN}" || true
        done
        # Delete user
        aws iam delete-user --user-name "${USER}" || true
        echo "    Deleted user ${USER}."
    done
}

# Function to delete IAM Roles by tag
delete_iam_roles() {
    echo "Cleaning up IAM Roles..."
    ROLES_TO_DELETE=$(aws iam list-roles --query "Roles[?contains(Tags[?Key=='Project'].Value | [0], '${PROJECT_NAME}') && contains(Tags[?Key=='Environment'].Value | [0], '${ENVIRONMENT_NAME}')].RoleName" --output text || true)

    for ROLE in ${ROLES_TO_DELETE}; do
        echo "  - Deleting role ${ROLE}..."
        # Detach role policies
        for POLICY_ARN in $(aws iam list-attached-role-policies --role-name "${ROLE}" --query 'AttachedPolicies[*].PolicyArn' --output text || true); do
            aws iam detach-role-policy --role-name "${ROLE}" --policy-arn "${POLICY_ARN}" || true
        done
        # Delete instance profiles associated with the role
        for IP_ARN in $(aws iam list-instance-profiles-for-role --role-name "${ROLE}" --query "InstanceProfiles[*].Arn" --output text || true); do
             aws iam remove-role-from-instance-profile --instance-profile-name "$(basename "${IP_ARN}")" --role-name "${ROLE}" || true
             aws iam delete-instance-profile --instance-profile-name "$(basename "${IP_ARN}")" || true
        done
        # Delete inline policies
        for INLINE_POLICY in $(aws iam list-role-policies --role-name "${ROLE}" --query 'PolicyNames[]' --output text || true);
 do
            aws iam delete-role-policy --role-name "${ROLE}" --policy-name "${INLINE_POLICY}" || true
        done
        # Delete role
        aws iam delete-role --role-name "${ROLE}" || true
        echo "    Deleted role ${ROLE}."
    done
}

# Function to delete VPC and related resources by tag with retries
delete_vpc_resources() {
    local region=$1
    echo "Cleaning up VPC resources in ${region}..."

    # Find VPCs tagged with Project and Environment
    VPC_IDS=$(aws ec2 describe-vpcs --region "${region}" --filters "${TAG_FILTERS[@]}" --query "Vpcs[*].VpcId" --output text || true)

    if [ -z "${VPC_IDS}" ]; then
        echo "  No project-related VPCs found in ${region}."
        return 0
    fi

    for VPC_ID in ${VPC_IDS}; do
        echo "  - Cleaning up VPC ${VPC_ID} in region ${region} (multiple passes for dependencies)..."

        local VPC_DELETED=false
        for i in $(seq 1 10); do # Retry deletion up to 10 times
            echo "    - Pass ${i}/10 of VPC cleanup for ${VPC_ID}..."
            
            # Check if VPC still exists, exit loop if it doesn't
            VPC_EXISTS=$(aws ec2 describe-vpcs --vpc-ids "${VPC_ID}" --region "${region}" --query "Vpcs[0].VpcId" --output text || true)
            if [ -z "${VPC_EXISTS}" ]; then
                echo "      VPC ${VPC_ID} no longer exists. Exiting cleanup for this VPC."
                VPC_DELETED=true
                break
            fi

            # 0. Terminate EC2 Instances
            for INSTANCE_ID in $(aws ec2 describe-instances --region "${region}" --filters "Name=vpc-id,Values=${VPC_ID}" "Name=instance-state-name,Values=pending,running,stopping,stopped" --query "Reservations[*].Instances[*].InstanceId" --output text || true); do
                echo "      - Terminating EC2 Instance ${INSTANCE_ID}..."
                aws ec2 terminate-instances --instance-ids "${INSTANCE_ID}" --region "${region}" || true
                sleep 5
            done
            sleep 10 # Give instances time to terminate

            # 1. Detach and delete any attached ENIs (Network Interfaces)
            for ENI_ID in $(aws ec2 describe-network-interfaces --region "${region}" --filters "Name=vpc-id,Values=${VPC_ID}" --query "NetworkInterfaces[*].NetworkInterfaceId" --output text || true); do
                echo "      - Detaching and deleting Network Interface ${ENI_ID}..."
                ATTACHMENT_ID=$(aws ec2 describe-network-interfaces --network-interface-ids "${ENI_ID}" --region "${region}" --query "NetworkInterfaces[0].Attachment.AttachmentId" --output text || true)
                if [ -n "${ATTACHMENT_ID}" ]; then
                    aws ec2 detach-network-interface --attachment-id "${ATTACHMENT_ID}" --region "${region}" || true
                    sleep 2
                fi
                aws ec2 delete-network-interface --network-interface-id "${ENI_ID}" --region "${region}" || true
                sleep 2
            done
            
            # 2. Delete VPC Endpoints
            for VPCE_ID in $(aws ec2 describe-vpc-endpoints --region "${region}" --filters "Name=vpc-id,Values=${VPC_ID}" --query "VpcEndpoints[*].VpcEndpointId" --output text || true); do
                echo "      - Deleting VPC Endpoint ${VPCE_ID}..."
                aws ec2 delete-vpc-endpoints --vpc-endpoint-ids "${VPCE_ID}" --region "${region}" || true
                sleep 5
            done

            # 3. Delete NAT Gateways
            for NAT_ID in $(aws ec2 describe-nat-gateways --region "${region}" --filters "Name=vpc-id,Values=${VPC_ID}" --query "NatGateways[*].NatGatewayId" --output text || true); do
                echo "      - Deleting NAT Gateway ${NAT_ID}..."
                aws ec2 delete-nat-gateway --nat-gateway-id "${NAT_ID}" --region "${region}" || true
                sleep 5
            done

            # 4. Release Elastic IPs associated with deleted NAT Gateways, or unassociated
            for EIP_ALLOC_ID in $(aws ec2 describe-addresses --region "${region}" --filters "Name=domain,Values=vpc" --query "Addresses[?AssociationId==null || Association.VpcId=='${VPC_ID}'].AllocationId" --output text || true); do
                echo "      - Releasing EIP ${EIP_ALLOC_ID}..."
                aws ec2 release-address --allocation-id "${EIP_ALLOC_ID}" --region "${region}" || true
                sleep 2
            done

            # 5. Detach and Delete Internet Gateways
            for IGW_ID in $(aws ec2 describe-internet-gateways --region "${region}" --filters "Name=attachment.vpc-id,Values=${VPC_ID}" --query "InternetGateways[*].InternetGatewayId" --output text || true); do
                echo "      - Detaching and deleting Internet Gateway ${IGW_ID}..."
                aws ec2 detach-internet-gateway --internet-gateway-id "${IGW_ID}" --vpc-id "${VPC_ID}" --region "${region}" || true
                aws ec2 delete-internet-gateway --internet-gateway-id "${IGW_ID}" --region "${region}" || true
                sleep 5
            done
            
            # 6. Delete Custom Route Tables (excluding main route table)
            for RT_ID in $(aws ec2 describe-route-tables --region "${region}" --filters "Name=vpc-id,Values=${VPC_ID}" --query "RouteTables[?!Associations[0].Main].RouteTableId" --output text || true); do
                echo "      - Deleting Route Table ${RT_ID}..."
                aws ec2 delete-route-table --route-table-id "${RT_ID}" --region "${region}" || true
                sleep 2
            done

            # 7. Delete Custom Network ACLs (excluding default)
            for NACL_ID in $(aws ec2 describe-network-acls --region "${region}" --filters "Name=vpc-id,Values=${VPC_ID}" --query "NetworkAcls[?!IsDefault].NetworkAclId" --output text || true); do
                echo "      - Deleting Network ACL ${NACL_ID}..."
                aws ec2 delete-network-acl --network-acl-id "${NACL_ID}" --region "${region}" || true
                sleep 2
            done

            # 8. Delete Custom Security Groups (excluding default ones)
            for SG_ID in $(aws ec2 describe-security-groups --region "${region}" --filters "Name=vpc-id,Values=${VPC_ID}" "${TAG_FILTERS[@]}" --query "SecurityGroups[?!contains(GroupName,'default')].GroupId" --output text || true); do
                echo "      - Deleting Security Group ${SG_ID}..."
                aws ec2 delete-security-group --group-id "${SG_ID}" --region "${region}" || true
                sleep 2
            done
            
            # 9. Delete Subnets
            for SUBNET_ID in $(aws ec2 describe-subnets --region "${region}" --filters "Name=vpc-id,Values=${VPC_ID}" --query "Subnets[*].SubnetId" --output text || true); do
                echo "      - Deleting Subnet ${SUBNET_ID}..."
                aws ec2 delete-subnet --subnet-id "${SUBNET_ID}" --region "${region}" || true
                sleep 2
            done

            # 10. Attempt to delete the VPC itself
            echo "      - Attempting to delete VPC ${VPC_ID}..."
            if aws ec2 delete-vpc --vpc-id "${VPC_ID}" --region "${region}"; then
                echo "    Deleted VPC ${VPC_ID}."
                VPC_DELETED=true
                break # Exit retry loop if VPC is deleted
            fi
            sleep 15 # Wait a bit longer before next retry if VPC deletion failed

        done # End of retry loop for VPC

        # Final check if VPC still exists after all retries
        if [ "${VPC_DELETED}" == "false" ]; then
            echo "    ERROR: VPC ${VPC_ID} still exists after multiple cleanup attempts due to unhandled dependencies."
            # Optionally, keep running and let other parts of cleanup proceed, or exit here
            # exit 1 
        fi
    done
}


# --- Main Cleanup Logic ---
echo "Starting comprehensive cleanup..."

# Cleanup in ap-southeast-2 first (manual cleanup region)
echo ""
echo "--- Cleaning up ap-southeast-2 (Sydney) region ---"
delete_s3_buckets "ap-southeast-2"
delete_dynamodb_tables "ap-southeast-2"
delete_secrets_manager_secrets "ap-southeast-2"
delete_vpc_resources "ap-southeast-2"
# IAM resources are global, handled once below

# Cleanup in us-east-1 (main region)
echo ""
echo "--- Cleaning up us-east-1 (N. Virginia) region ---"
delete_s3_buckets "us-east-1"
delete_dynamodb_tables "us-east-1"
delete_secrets_manager_secrets "us-east-1"
delete_vpc_resources "us-east-1"


# Cleanup Global IAM resources (users, roles)
echo ""
echo "--- Cleaning up Global IAM resources (users, roles) ---"
delete_iam_users
delete_iam_roles


# Final Terraform Destroy for any remaining state-managed resources
echo ""
echo "--- Running Terraform Destroy for all projects ---"

# Destroy in reverse dependency order
# Core Services -> Foundation -> IAM Manager -> Bootstrap
PROJECTS=(
    "terraform-core-services/environments/dev"
    "terraform-foundation/environments/dev"
    "terraform-iam-manager/environments/dev"
    "terraform-iam-manager/bootstrap"
)

for PROJECT_PATH in "${PROJECTS[@]}"; do
    echo "Destroying ${PROJECT_PATH}..."
    cd "${PROJECT_PATH}" || { echo "Error: Directory ${PROJECT_PATH} not found."; exit 1; }
    terraform init -reconfigure || true # Allow init to fail gracefully if backend is gone
    terraform destroy -auto-approve -lock=false || true # Allow destroy to fail gracefully if resources are already gone
    cd - > /dev/null # Go back to previous directory
done

echo ""
echo "Comprehensive cleanup complete!"
