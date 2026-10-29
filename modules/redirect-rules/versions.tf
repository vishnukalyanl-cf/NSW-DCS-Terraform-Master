# Without this, Terraform would look for a non-existent "hashicorp/cloudflare".
terraform {
  required_providers {
    cloudflare = {
      source = "cloudflare/cloudflare"
    }
  }
}
