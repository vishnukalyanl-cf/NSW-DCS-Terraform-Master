# Safety check: stop the run if zone_id does not belong to zone_name.
data "cloudflare_zone" "this" {
  zone_id = var.zone_id

  lifecycle {
    postcondition {
      condition     = self.name == var.zone_name
      error_message = "zone_id ${var.zone_id} belongs to '${self.name}', not '${var.zone_name}'. Check the zone .tfvars file."
    }
  }
}

module "dns_records" {
  source = "../modules/dns-records"

  zone_id   = var.zone_id
  zone_name = data.cloudflare_zone.this.name
  records   = var.dns_records
}

module "redirect_rules" {
  source = "../modules/redirect-rules"

  zone_id   = var.zone_id
  zone_name = data.cloudflare_zone.this.name
  rules     = var.redirect_rules
}
