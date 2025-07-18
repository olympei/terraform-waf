
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
  description = "List of custom rules with comprehensive WAF protection types. Supports both simple type-based and advanced object-based configurations."
  type = list(object({
    name              = string
    priority          = number
    metric_name       = string
    action            = optional(string, "block")            # block, allow, count
    
    # Type-based rule generation (simple approach)
    type              = optional(string)                     # "sqli", "xss", "ip_block", "regex", "byte_match", "rate_based", "geo_match", "size_constraint"
    field_to_match    = optional(string, "body")             # e.g., "uri_path", "query_string", "body"
    search_string     = optional(string)                     # For regex or byte match
    regex_pattern_set = optional(string)                     # ARN of regex pattern set
    ip_set_arn        = optional(string)                     # For ip_block
    
    # Legacy statement (deprecated)
    statement         = optional(string)                     # Deprecated - use statement_config instead
    
    # Advanced object-based statement configuration
    statement_config  = optional(object({
      # SQL Injection Match Statement
      sqli_match_statement = optional(object({
        field_to_match = object({
          body                = optional(object({}))
          uri_path           = optional(object({}))
          query_string       = optional(object({}))
          all_query_arguments = optional(object({}))
          single_header      = optional(object({ name = string }))
          method             = optional(object({}))
        })
        text_transformation = object({
          priority = number
          type     = string  # NONE, COMPRESS_WHITE_SPACE, HTML_ENTITY_DECODE, LOWERCASE, CMD_LINE, URL_DECODE
        })
      }))
      
      # XSS Match Statement
      xss_match_statement = optional(object({
        field_to_match = object({
          body                = optional(object({}))
          uri_path           = optional(object({}))
          query_string       = optional(object({}))
          all_query_arguments = optional(object({}))
          single_header      = optional(object({ name = string }))
          method             = optional(object({}))
        })
        text_transformation = object({
          priority = number
          type     = string
        })
      }))
      
      # IP Set Reference Statement
      ip_set_reference_statement = optional(object({
        arn = string
      }))
      
      # Regex Pattern Set Reference Statement
      regex_pattern_set_reference_statement = optional(object({
        arn = string
        field_to_match = object({
          body                = optional(object({}))
          uri_path           = optional(object({}))
          query_string       = optional(object({}))
          all_query_arguments = optional(object({}))
          single_header      = optional(object({ name = string }))
          method             = optional(object({}))
        })
        text_transformation = object({
          priority = number
          type     = string
        })
      }))
      
      # Byte Match Statement
      byte_match_statement = optional(object({
        search_string = string
        field_to_match = object({
          body                = optional(object({}))
          uri_path           = optional(object({}))
          query_string       = optional(object({}))
          all_query_arguments = optional(object({}))
          single_header      = optional(object({ name = string }))
          method             = optional(object({}))
        })
        positional_constraint = string  # EXACTLY, STARTS_WITH, ENDS_WITH, CONTAINS, CONTAINS_WORD
        text_transformation = object({
          priority = number
          type     = string
        })
      }))
      
      # Rate Based Statement
      rate_based_statement = optional(object({
        limit              = number
        aggregate_key_type = string  # IP, FORWARDED_IP
      }))
      
      # Geo Match Statement
      geo_match_statement = optional(object({
        country_codes = list(string)  # ISO 3166-1 alpha-2 country codes
      }))
      
      # Size Constraint Statement
      size_constraint_statement = optional(object({
        comparison_operator = string  # EQ, NE, LE, LT, GE, GT
        size               = number
        field_to_match = object({
          body                = optional(object({}))
          uri_path           = optional(object({}))
          query_string       = optional(object({}))
          all_query_arguments = optional(object({}))
          single_header      = optional(object({ name = string }))
          method             = optional(object({}))
        })
        text_transformation = object({
          priority = number
          type     = string
        })
      }))
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
  
  validation {
    condition = length(distinct([for r in var.custom_rules : r.priority])) == length(var.custom_rules)
    error_message = "Duplicate priorities detected in custom_rules. All rule priorities must be unique."
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
