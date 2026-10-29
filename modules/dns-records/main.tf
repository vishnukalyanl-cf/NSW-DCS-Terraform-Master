# Customers write short names ("www", "@"). Cloudflare stores full names,
# so expand them here to avoid permanent plan diffs.
locals {
  fqdns = {
    for key, r in var.records : key => r.name == "@" ? var.zone_name : (r.name == var.zone_name || endswith(r.name, ".${var.zone_name}")) ? r.name : "${r.name}.${var.zone_name}"
  }
}

resource "cloudflare_dns_record" "this" {
  for_each = var.records

  zone_id  = var.zone_id
  name     = local.fqdns[each.key]
  type     = each.value.type
  content  = each.value.content
  ttl      = each.value.proxied ? 1 : each.value.ttl
  proxied  = each.value.proxied
  priority = each.value.type == "MX" ? each.value.priority : null
  comment  = each.value.comment
}
