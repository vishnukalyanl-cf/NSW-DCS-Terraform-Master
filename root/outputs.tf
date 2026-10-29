output "zone" {
  description = "The zone this run managed."

  value = {
    id   = var.zone_id
    name = data.cloudflare_zone.this.name
  }
}

output "dns_records" {
  description = "Managed DNS records."
  value       = module.dns_records.records
}

output "redirect_ruleset_id" {
  description = "ID of the zone's redirect ruleset (null when no rules)."
  value       = module.redirect_rules.ruleset_id
}
