# Terraform 1.11+ is required for S3-native state locking (use_lockfile) on R2.
# The Cloudflare provider is pinned to patch releases only: v5 minor releases
# sometimes contain schema changes, so upgrade minors deliberately.
terraform {
  required_version = ">= 1.11.0"

  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5.28.0"
    }
  }
}
