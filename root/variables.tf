variable "zone_id" {
  description = "Cloudflare zone ID (Dashboard > zone > Overview > API)."
  type        = string

  validation {
    condition     = can(regex("^[a-f0-9]{32}$", var.zone_id))
    error_message = "zone_id must be a 32-character lowercase hex string."
  }
}

variable "zone_name" {
  description = "Zone apex, e.g. example.com. Must match zone_id (checked at plan time)."
  type        = string
}

variable "dns_records" {
  description = "DNS records. Map key = permanent Terraform ID for the record."

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
}

variable "redirect_rules" {
  description = "Single Redirect rules, evaluated in list order."

  type = list(object({
    name                  = string
    description           = optional(string)
    enabled               = optional(bool, true)
    source_hostname       = optional(string)
    source_path           = optional(string)
    expression            = optional(string)
    target_url            = optional(string)
    target_expression     = optional(string)
    status_code           = optional(number, 301)
    preserve_query_string = optional(bool, false)
  }))

  default = []
}

variable "dns_record_imports" {
  description = "Existing records to adopt: { <dns_records key> = \"<record_id>\" }."
  type        = map(string)
  default     = {}
}

variable "redirect_ruleset_import_id" {
  description = "ID of an existing redirect ruleset (created in the dashboard) to adopt."
  type        = string
  default     = null
}
