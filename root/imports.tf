# Adopt existing DNS records into Terraform without re-creating them.
# Driven by dns_record_imports in the zone .tfvars file.
import {
  for_each = var.dns_record_imports
  to       = module.dns_records.cloudflare_dns_record.this[each.key]
  id       = "${var.zone_id}/${each.value}"
}

# Adopt an existing redirect ruleset (rules created in the dashboard).
# Driven by redirect_ruleset_import_id in the zone .tfvars file.
import {
  for_each = var.redirect_ruleset_import_id == null ? toset([]) : toset([var.redirect_ruleset_import_id])
  to       = module.redirect_rules.cloudflare_ruleset.this[0]
  id       = "zones/${var.zone_id}/${each.value}"
}
