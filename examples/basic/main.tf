provider "aws" {
  region = "us-east-1"
}

# Variables for basic configuration
variable "name" {
  description = "Name of the WAF ACL"
  type        = string
  default     = "basic-waf"
}

variable "scope" {
  description = "Scope of the WAF (REGIONAL or CLOUDFRONT)"
  type        = string
  default     = "REGIONAL"

  validation {
    condition     = contains(["REGIONAL", "CLOUDFRONT"], var.scope)
    error_message = "Scope must be either REGIONAL or CLOUDFRONT."
  }
}

variable "default_action" {
  description = "Default action for the WAF (allow or block)"
  type        = string
  default     = "allow"

  validation {
    condition     = contains(["allow", "block"], var.default_action)
    error_message = "Default action must be either allow or block."
  }
}

variable "alb_arn_list" {
  description = "List of ALB ARNs to associate with the WAF (optional)"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags to apply to WAF resources"
  type        = map(string)
  default = {
    Environment = "basic"
    Purpose     = "Basic WAF Example"
    Example     = "basic"
  }
}

# Basic WAF ACL with essential AWS managed rules
module "waf_basic" {
  source = "../../modules/waf"

  name           = var.name
  scope          = var.scope
  default_action = var.default_action
  alb_arn_list   = var.alb_arn_list

  # No custom rule groups
  rule_group_arn_list = []

  # Basic AWS managed rules for essential protection
  aws_managed_rule_groups = [
    {
      name            = "AWSManagedRulesCommonRuleSet"
      vendor_name     = "AWS"
      priority        = 100
      override_action = "none"
    },
    {
      name            = "AWSManagedRulesSQLiRuleSet"
      vendor_name     = "AWS"
      priority        = 200
      override_action = "none"
    }
  ]

  # Custom inline rules for basic protection
  custom_inline_rules = [
    # Cross-Site Scripting (XSS) protection for request body
    {
      name        = "CrossSiteScripting_BODY"
      priority    = 300
      action      = "block"
      metric_name = "CrossSiteScripting_BODY"
      statement_config = {
        xss_match_statement = {
          field_to_match = {
            body = {}
          }
          text_transformation = {
            priority = 1
            type     = "HTML_ENTITY_DECODE"
          }
        }
      }
    },
    
    # Size restrictions for request body (limit to 8KB)
    {
      name        = "SizeRestrictions_BODY"
      priority    = 301
      action      = "block"
      metric_name = "SizeRestrictions_BODY"
      statement_config = {
        size_constraint_statement = {
          comparison_operator = "GT"
          size                = 8192  # 8KB limit
          field_to_match = {
            body = {}
          }
          text_transformation = {
            priority = 0
            type     = "NONE"
          }
        }
      }
    }
  ]

  tags = var.tags
}

# Outputs
output "waf_acl_arn" {
  description = "ARN of the basic WAF ACL"
  value       = module.waf_basic.web_acl_arn
}

output "waf_acl_id" {
  description = "ID of the basic WAF ACL"
  value       = module.waf_basic.web_acl_id
}

output "waf_acl_name" {
  description = "Name of the basic WAF ACL"
  value       = var.name
}

output "basic_waf_summary" {
  description = "Summary of the basic WAF configuration"
  value = {
    name           = var.name
    scope          = var.scope
    default_action = var.default_action
    arn            = module.waf_basic.web_acl_arn
    protection = {
      aws_managed_rules = [
        "AWSManagedRulesCommonRuleSet (Priority 100)",
        "AWSManagedRulesSQLiRuleSet (Priority 200)"
      ]
      custom_rules = "None (basic example)"
      inline_rules = [
        "CrossSiteScripting_BODY (Priority 300) - Blocks XSS attempts in request body",
        "SizeRestrictions_BODY (Priority 301) - Blocks requests with body > 8KB"
      ]
    }
    use_cases = [
      "Quick WAF deployment",
      "Basic web application protection",
      "XSS protection for request bodies",
      "Request size limiting",
      "Simple configuration with essential rules"
    ]
  }
}

output "custom_rules_details" {
  description = "Details of the custom inline rules"
  value = {
    xss_protection = {
      name        = "CrossSiteScripting_BODY"
      priority    = 300
      action      = "block"
      description = "Blocks Cross-Site Scripting (XSS) attempts in request body"
      field       = "body"
      transformation = "HTML_ENTITY_DECODE"
    }
    size_restriction = {
      name        = "SizeRestrictions_BODY"
      priority    = 301
      action      = "block"
      description = "Blocks requests with body size greater than 8KB (8192 bytes)"
      field       = "body"
      size_limit  = "8192 bytes (8KB)"
    }
  }
}