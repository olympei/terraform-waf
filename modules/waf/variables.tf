
variable "name" { type = string }
variable "scope" { type = string } # REGIONAL or CLOUDFRONT
variable "default_action" { type = string } # allow or block
#variable "rule_group_arn_list" { type = list(string) default = [] }
# Variable: rule_group_arn_list (with optional name/priority)
variable "rule_group_arn_list" {
  type = list(object({
    arn      = string
    name     = optional(string)
    priority = optional(number)
  }))
  default = []
  description = "List of rule group ARNs to associate with the WAF ACL. Name and priority are optional."
}

# Variable: aws_managed_rule_groups
variable "aws_managed_rule_groups" {
  description = "List of AWS Managed Rule Groups to include in the WAF ACL. Each object must include vendor_name, name, and priority."
  type = list(object({
    name         = string
    vendor_name  = string
    priority     = number
    override_action = optional(string, "none") # none or count
  }))
  default = []
}


variable "alb_arn_list" { 
  description = "List of ALB ARNs to associate with the WAF"
  type        = list(string) 
  default     = [] 
}

variable "tags" { 
  description = "Tags to apply to WAF resources"
  type        = map(string) 
  default     = {} 
}



variable "create_log_group" {
  type    = bool
  default = false
}

variable "log_group_name" {
  type    = string
  default = null
}

variable "existing_log_group_arn" {
  type    = string
  default = null
}

variable "log_group_retention_in_days" {
  type    = number
  default = 30
}

variable "kms_key_id" {
  type    = string
  default = null
  description = "KMS Key ID to encrypt the CloudWatch Log Group if created."
}


# Variable: rules (object list for inline rule types)
variable "custom_inline_rules" {
  type = list(object({
    name         = string
    priority     = number
    action       = string
    rule_type    = optional(string)
    statement    = optional(string)                     # Legacy string-based statement
    metric_name  = string
    
    # New object-based statement configuration
    statement_config = optional(object({
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
          type     = string
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
        positional_constraint = string
        text_transformation = object({
          priority = number
          type     = string
        })
      }))
      
      # Rate Based Statement
      rate_based_statement = optional(object({
        limit              = number
        aggregate_key_type = string
        forwarded_ip_config = optional(object({
          header_name       = string
          fallback_behavior = string  # MATCH, NO_MATCH
        }))
      }))
      
      # Geo Match Statement
      geo_match_statement = optional(object({
        country_codes = list(string)
      }))
      
      # Size Constraint Statement
      size_constraint_statement = optional(object({
        comparison_operator = string
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
      
      # AND Statement (for combining multiple conditions with logical AND)
      and_statement = optional(object({
        statements = list(object({
          geo_match_statement = optional(object({
            country_codes = list(string)
          }))
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
            positional_constraint = string
            text_transformation = object({
              priority = number
              type     = string
            })
          }))
          or_statement = optional(object({
            statements = list(object({
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
                positional_constraint = string
                text_transformation = object({
                  priority = number
                  type     = string
                })
              }))
            }))
          }))
        }))
      }))
      
      # OR Statement (for alternative conditions with logical OR)
      or_statement = optional(object({
        statements = list(object({
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
            positional_constraint = string
            text_transformation = object({
              priority = number
              type     = string
            })
          }))
        }))
      }))
    }))
  }))
  default = []
  description = "Inline rule definitions for WAF. Supports both legacy string statements and new object-based statement configurations."
  
  validation {
    condition = length(distinct([for r in var.custom_inline_rules : r.priority])) == length(var.custom_inline_rules)
    error_message = "Duplicate priorities detected in custom_inline_rules. All rule priorities must be unique."
  }
  
  validation {
    condition = alltrue([
      for rule in var.custom_inline_rules : (
        (lookup(rule, "statement", null) != null && lookup(rule, "statement_config", null) == null) ||
        (lookup(rule, "statement", null) == null && lookup(rule, "statement_config", null) != null)
      )
    ])
    error_message = "Each rule must use either 'statement' (legacy string) OR 'statement_config' (object), but not both."
  }
}

# Validation Rule
variable "validate_priorities" {
  description = "Ensures unique WAF rule priorities across all rule types"
  type        = bool
  default     = true
  validation {
    condition     = var.validate_priorities == true || var.validate_priorities == false
    error_message = "validate_priorities must be a boolean value (true or false)."
  }
}