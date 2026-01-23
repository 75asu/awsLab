#!/bin/bash
# Terraform Destroy - Auto-approve, no questions
# Destroys in correct dependency order

set -e
ROOT="$(dirname "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)")"

echo "=== Terraform Destroy - All Projects ==="

for project in \
  "terraform-solana-listener/environments/dev" \
  "terraform-core-services/environments/dev" \
  "terraform-foundation/environments/dev" \
  "terraform-iam-manager/environments/dev" \
  "terraform-oidc"; do

  path="$ROOT/$project"
  echo ""
  echo "--- $project ---"

  if [[ ! -d "$path" ]]; then
    echo "SKIP: Directory not found"
    continue
  fi

  cd "$path"
  terraform init -input=false 2>/dev/null || { echo "SKIP: Init failed"; continue; }

  count=$(terraform state list 2>/dev/null | wc -l)
  if [[ "$count" -eq 0 ]]; then
    echo "OK: No resources in state"
    continue
  fi

  echo "Destroying $count resources..."
  terraform destroy -auto-approve || echo "WARN: Destroy had errors"
done

echo ""
echo "=== Terraform destroy complete ==="
echo "Note: Bootstrap (state bucket) not destroyed. Run manually if needed:"
echo "  cd $ROOT/terraform-iam-manager/bootstrap && terraform destroy -auto-approve"
