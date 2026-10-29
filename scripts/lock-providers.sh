#!/usr/bin/env bash
# Generates root/.terraform.lock.hcl for all common platforms.
# Run after cloning (first time) and after bumping the provider version,
# then commit root/.terraform.lock.hcl.
set -euo pipefail
cd "$(dirname "$0")/../root"
terraform init -backend=false -upgrade
terraform providers lock \
  -platform=linux_amd64 \
  -platform=darwin_arm64 \
  -platform=darwin_amd64 \
  -platform=windows_amd64
echo "Done. Commit root/.terraform.lock.hcl"
