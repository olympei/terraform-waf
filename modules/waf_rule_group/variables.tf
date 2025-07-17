
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
    action            = optional(string, "block")            # block, allow, count
    
    # Type-based rule generation (simple approach)
    type              = optional(string)                     # "sqli", "xss", "ip_block", "regex", "byte_match"
    field_to_match    = optional(string, "body")             # e.g., "uri_path", "query_string", "body"
    search_string     = optional(string)                     # For regex or byte match
    regex_pattern_set = optional(string)                     # ARN of regex pattern set
    ip_set_arn        = optional(string)                     # For ip_block
    
    # Custom statement configuration (advanced approach)
    statement         = optional(string)                     # Deprecated - use statement_config instead
    statement_config  = optional(object({
      type                          = string                 # "sqli", "xss", "rate_based", "geo_match", "size_constraint"
      field_to_match               = optional(string, "body") # "body", "uri_path", "query_string", "all_query_arguments"
      text_transformation_priority = optional(number, 0)
      text_transformation_type     = optional(string, "NONE")
      
      # Rate-based statement specific
      rate_limit                   = optional(number, 2000)
      aggregate_key_type          = optional(string, "IP")
      
      # Geo match statement specific
      country_codes               = optional(list(string), [])
      
      # Size constraint statement specific
      comparison_operator         = optional(string, "GT")
      size                       = optional(number, 8192)
    }))
  }))
  default = []
  
  validation {
    condition = alltrue([
      for rule in var.custom_rules : (
        (lookup(rule, "type", null) != null && lookup(rule, "statement_config", null) == null) ||
        (lookup(rule, "type", null) == null && lookup(rule, "statement_config", null) != null) ||
        (lookup(rule, "type", null) == null && lookup(rule, "statement_config", null) == null && lookup(rule, "statement", null) != null)
      )
    ])
    error_message = "Each rule must use either 'type' (for simple rules) OR 'statement_config' (for advanced rules) OR 'statement' (deprecated), but not multiple approaches."
  }
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
