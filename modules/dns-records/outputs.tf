output "records" {
  description = "Record key => details of the managed DNS record."

  value = {
    for k, r in cloudflare_dns_record.this : k => {
      id      = r.id
      name    = r.name
      type    = r.type
      content = r.content
      proxied = r.proxied
    }
  }
}
