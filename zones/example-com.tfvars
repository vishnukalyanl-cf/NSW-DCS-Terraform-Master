# =====================================================================
#  Zone: example.com
#  This is the ONLY file you edit for this zone.
#  After editing: run "terraform fmt -recursive", commit, push, then
#  run the pipeline (see README).
# =====================================================================

zone_id   = "0123456789abcdef0123456789abcdef"
zone_name = "example.com"

# ---------------------------------------------------------------------
# DNS RECORDS
# The key on the left (e.g. root_a) is the record's permanent ID inside
# Terraform. Do NOT rename a key later, or Terraform will delete and
# re-create that record.
#
#   name     "@" = apex, or a short name like "www" / "api"
#   type     A | AAAA | CNAME | TXT | MX
#   content  IP, hostname or text
#   proxied  true = orange cloud (A/AAAA/CNAME only). Default false
#   ttl      1 = Auto (default). Ignored when proxied = true
#   priority MX only
#   comment  optional, default "Managed by Terraform"
# ---------------------------------------------------------------------
dns_records = {
  root_a = {
    name    = "@"
    type    = "A"
    content = "192.0.2.10"
    proxied = true
  }

  www_cname = {
    name    = "www"
    type    = "CNAME"
    content = "example.com"
    proxied = true
  }

  api_a = {
    name    = "api"
    type    = "A"
    content = "192.0.2.20"
    proxied = true
  }

  mx_primary = {
    name     = "@"
    type     = "MX"
    content  = "mx1.mailprovider.example"
    priority = 10
  }

  spf_txt = {
    name    = "@"
    type    = "TXT"
    content = "v=spf1 include:_spf.mailprovider.example ~all"
    ttl     = 3600
  }
}

# ---------------------------------------------------------------------
# REDIRECT RULES (Single Redirects)
# Rules are evaluated top to bottom: put specific rules first.
# The source hostname must be PROXIED (orange cloud) for redirects to work.
#
#   name                  unique, lowercase_with_underscores (never rename)
#   description           shown in the Cloudflare dashboard
#   source_hostname       defaults to the zone apex
#   source_path           "/exact-path" or "/folder/*" (omit = all paths)
#   target_url            where to send visitors
#   status_code           301 (default) | 302 | 303 | 307 | 308
#   preserve_query_string keep ?a=b on the redirect (default false)
#   enabled               default true
# ---------------------------------------------------------------------
redirect_rules = [
  {
    name            = "old_pricing_page"
    description     = "Old pricing page to new pricing page"
    source_hostname = "example.com"
    source_path     = "/pricing-old"
    target_url      = "https://example.com/pricing"
    status_code     = 301
  },
  {
    name                  = "blog_to_news"
    description           = "Everything under /blog goes to /news"
    source_path           = "/blog/*"
    target_url            = "https://example.com/news"
    status_code           = 302
    preserve_query_string = true
  },

  # ADVANCED: www -> apex, keeping the path.
  # target_expression uses the Cloudflare rules language directly.
  {
    name                  = "www_to_apex"
    description           = "www.example.com/* -> example.com/*"
    source_hostname       = "www.example.com"
    target_expression     = "concat(\"https://example.com\", http.request.uri.path)"
    status_code           = 301
    preserve_query_string = true
  },

  # ADVANCED: wildcard with path substitution. In .tfvars you must write
  # $${1} (double $) for Cloudflare's ${1} placeholder.
  # {
  #   name              = "docs_v1_to_v2"
  #   expression        = "http.request.full_uri wildcard r\"https://example.com/docs/v1/*\""
  #   target_expression = "wildcard_replace(http.request.full_uri, r\"https://example.com/docs/v1/*\", r\"https://example.com/docs/v2/$${1}\")"
  #   status_code       = 301
  # },
]

# ---------------------------------------------------------------------
# ADOPT EXISTING OBJECTS - only for records/rules already created in the
# dashboard. Get IDs with: ./scripts/list-existing.sh <zone_id>
# See README section 6.
# ---------------------------------------------------------------------
dns_record_imports = {
  # root_a = "<existing_dns_record_id>"
}

# redirect_ruleset_import_id = "<existing_ruleset_id>"
