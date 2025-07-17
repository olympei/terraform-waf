
variable "rule_group_name" { 
  description = "Name of the WAF rule group"
  type        = string 
}

variable "name" {
  description = "Base name for resources (used for templated rule group)"
  type        = string
  default     = ""
}

variable "scope" { 
  description = "Scope of the rule group (REGIONAL or CLOUDFRONT)"
  type        = string 
  validation {
    condition     = contains(["REGIONAL", "CLOUDFRONT"], var.scope)
    error_message = "Scope must be either REGIONAL or CLOUDFRONT."
  }
}

variable "capacity" { 
  description = "Capacity units for the rule group"
  type        = number 
}

variable "metric_name" { 
  description = "CloudWatch metric name for the rule group"
  type        = string 
}

variable "custom_rules" {
  description = "List of custom rules of various types. Supports both shorthand (type-based) and full statement definitions."
  type = list(object({
    name              = string
    priority          = number
    metric_name       = string
    type              = optional(string)                     # "sqli", "xss", "ip_block", "regex", "byte_match"
    statement         = optional(string)                     # Raw statement override
    field_to_match    = optional(string, "body")             # e.g., "uri_path", "query_string", "body"
    search_string     = optional(string)                     # For regex or byte match
    regex_pattern_set = optional(string)                     # ARN of regex pattern set
    ip_set_arn        = optional(string)                     # For ip_block
    action            = optional(string, "block")            # block, allow, count
  }))
  default = []
}

variable "use_templatefile_rendering" {
  description = "Enable templatefile rendering for rule statements"
  type        = bool
  default     = false
}

variable "use_rendered_rules" { 
  description = "Enable rendered rules (deprecated - use use_templatefile_rendering instead)"
  type        = bool 
  default     = false 
}

variable "tags" { 
  description = "Tags to apply to the rule group"
  type        = map(string) 
  default     = {} 
}
