# Translate the simple tfvars format into Cloudflare ruleset rules.
#   - expression set          -> used as-is (advanced)
#   - source_path not set     -> match every path on source_hostname
#   - source_path set         -> wildcard match on the path ("/old", "/blog/*")
# source_hostname defaults to the zone apex.
locals {
  rules = [
    for r in var.rules : {
      ref         = r.name
      description = coalesce(r.description, r.name)
      enabled     = r.enabled
      action      = "redirect"

      expression = (
        r.expression != null ? r.expression :
        r.source_path == null ? format("(http.host eq \"%s\")", coalesce(r.source_hostname, var.zone_name)) :
        format("(http.host eq \"%s\" and http.request.uri.path wildcard r\"%s\")", coalesce(r.source_hostname, var.zone_name), r.source_path)
      )

      action_parameters = {
        from_value = {
          status_code           = r.status_code
          preserve_query_string = r.preserve_query_string

          target_url = {
            value      = r.target_expression == null ? r.target_url : null
            expression = r.target_expression
          }
        }
      }
    }
  ]
}

# One redirect "entry point" ruleset per zone holds all Single Redirect rules.
# The rule "ref" keeps rule IDs stable, so edits update rules in place.
resource "cloudflare_ruleset" "this" {
  count = length(local.rules) > 0 ? 1 : 0

  zone_id     = var.zone_id
  name        = "default"
  description = "Single Redirects for ${var.zone_name} - managed by Terraform"
  kind        = "zone"
  phase       = "http_request_dynamic_redirect"
  rules       = local.rules
}
