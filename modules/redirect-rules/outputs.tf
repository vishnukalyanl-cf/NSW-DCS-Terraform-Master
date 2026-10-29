output "ruleset_id" {
  description = "ID of the zone's redirect ruleset (null when no rules)."
  value       = try(cloudflare_ruleset.this[0].id, null)
}

output "rule_names" {
  description = "Rule refs, in evaluation order."
  value       = [for r in local.rules : r.ref]
}
