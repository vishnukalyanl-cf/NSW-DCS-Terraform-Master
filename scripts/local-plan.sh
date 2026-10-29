#!/usr/bin/env bash
# Runs a read-only plan for one zone from your laptop.
# Usage: ./scripts/local-plan.sh <zone-file-name>     e.g. example-com
# Required env vars:
#   CLOUDFLARE_API_TOKEN, AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY (R2),
#   CLOUDFLARE_ACCOUNT_ID, TF_STATE_BUCKET
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <zone-file-name>   (e.g. example-com)"
  exit 1
fi
ZONE="$1"

cd "$(dirname "$0")/../root"
if [[ ! -f "../zones/$ZONE.tfvars" ]]; then
  echo "zones/$ZONE.tfvars not found"
  exit 1
fi

export AWS_ENDPOINT_URL_S3="https://$CLOUDFLARE_ACCOUNT_ID.r2.cloudflarestorage.com"

terraform init -reconfigure -lockfile=readonly \
  -backend-config="bucket=$TF_STATE_BUCKET" \
  -backend-config="key=zones/$ZONE/terraform.tfstate"

terraform plan -var-file="../zones/$ZONE.tfvars"
