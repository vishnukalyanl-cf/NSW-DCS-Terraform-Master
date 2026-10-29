variable "zone_id" {
  description = "Cloudflare zone ID."
  type        = string
}

variable "zone_name" {
  description = "Zone apex, used to expand short record names."
  type        = string
}

variable "records" {
  description = "Map of record key => record definition."

  type = map(object({
    name     = string
    type     = string
    content  = string
    ttl      = optional(number, 1)
    proxied  = optional(bool, false)
    priority = optional(number)
    comment  = optional(string, "Managed by Terraform")
  }))

  default = {}

  validation {
    condition     = alltrue([for r in values(var.records) : contains(["A", "AAAA", "CNAME", "TXT", "MX"], r.type)])
    error_message = "Supported record types: A, AAAA, CNAME, TXT, MX."
  }

  validation {
    condition     = alltrue([for r in values(var.records) : !r.proxied || contains(["A", "AAAA", "CNAME"], r.type)])
    error_message = "Only A, AAAA and CNAME records can be proxied."
  }

  validation {
    condition     = alltrue([for r in values(var.records) : r.type != "MX" || r.priority != null])
    error_message = "MX records need a priority."
  }

  validation {
    condition     = alltrue([for r in values(var.records) : r.ttl == 1 || (r.ttl >= 30 && r.ttl <= 86400)])
    error_message = "ttl must be 1 (Auto) or 60-86400 seconds (30 minimum on Enterprise)."
  }
}
