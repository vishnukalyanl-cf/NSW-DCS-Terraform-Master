# =====================================================================
#  Zone: example.org  (second zone - copy a file like this to onboard
#  more zones; each zone gets its own state file automatically)
# =====================================================================

zone_id   = "fedcba9876543210fedcba9876543210"
zone_name = "example.org"

dns_records = {
  root_a = {
    name    = "@"
    type    = "A"
    content = "198.51.100.10"
    proxied = true
  }

  www_cname = {
    name    = "www"
    type    = "CNAME"
    content = "example.org"
    proxied = true
  }
}

redirect_rules = [
  {
    name                  = "www_to_apex"
    description           = "www.example.org/* -> example.org/*"
    source_hostname       = "www.example.org"
    target_expression     = "concat(\"https://example.org\", http.request.uri.path)"
    preserve_query_string = true
  },
]
