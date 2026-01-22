#!/bin/bash

# This script destroys all the resources created by the Terraform projects.
# It should be run with credentials that have permission to delete all the created resources.

set -e

echo "Destroying terraform-foundation..."
cd terraform-foundation/environments/dev
terraform init -reconfigure || true # Allow init to fail if backend is gone
terraform destroy -auto-approve -lock=false

echo "Destroying terraform-iam-manager..."
cd ../../../terraform-iam-manager/environments/dev
terraform init -reconfigure || true # Allow init to fail if backend is gone
terraform destroy -auto-approve -lock=false

echo "Destroying terraform-iam-manager bootstrap..."
cd ../../bootstrap
terraform init -reconfigure # Bootstrap's backend must exist to destroy itself
terraform destroy -auto-approve

echo "Cleanup complete!"
