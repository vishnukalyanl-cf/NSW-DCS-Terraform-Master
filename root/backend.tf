# State is stored in Cloudflare R2 through Terraform's S3 backend.
# Supplied at runtime (not hard-coded):
#   bucket   -> terraform init -backend-config="bucket=<bucket>"
#   key      -> terraform init -backend-config="key=zones/<zone>/terraform.tfstate"
#   endpoint -> env AWS_ENDPOINT_URL_S3=https://<ACCOUNT_ID>.r2.cloudflarestorage.com
#   creds    -> env AWS_ACCESS_KEY_ID / AWS_SECRET_ACCESS_KEY (R2 API token)
terraform {
  backend "s3" {
    region                      = "auto"
    use_path_style              = true
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    skip_requesting_account_id  = true
    skip_s3_checksum            = true

    # Writes <key>.tflock next to the state so two runs cannot change the
    # same zone at once. R2 supports the conditional writes this relies on.
    use_lockfile = true
  }
}
