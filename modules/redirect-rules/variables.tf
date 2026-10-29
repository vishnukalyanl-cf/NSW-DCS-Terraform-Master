variable "zone_id" {
  description = "Cloudflare zone ID."
  type        = string
}

variable "zone_name" {
  description = "Zone apex, used as the default source hostname."
  type        = string
}

variable "rules" {
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

  validation {
    condition     = length(distinct([for r in var.rules : r.name])) == length(var.rules)
    error_message = "Each redirect rule needs a unique name."
  }

  validation {
    condition     = alltrue([for r in var.rules : can(regex("^[a-z0-9_]+$", r.name))])
    error_message = "Rule names may only contain lowercase letters, digits and underscores."
  }

  validation {
    condition     = alltrue([for r in var.rules : (r.target_url == null) != (r.target_expression == null)])
    error_message = "Each rule must set exactly one of target_url or target_expression."
  }

  validation {
    condition     = alltrue([for r in var.rules : r.expression == null || (r.source_hostname == null && r.source_path == null)])
    error_message = "Use either expression OR source_hostname/source_path in a rule, not both."
  }

  validation {
    condition     = alltrue([for r in var.rules : contains([301, 302, 303, 307, 308], r.status_code)])
    error_message = "status_code must be 301, 302, 303, 307 or 308."
  }
}
