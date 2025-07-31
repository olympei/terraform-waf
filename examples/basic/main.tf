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

  # Custom inline rules with exceptions for /testo/ and /appgo/ paths
  custom_inline_rules = [
    {
      name        = "CrossSiteScripting_BODY_Block"
      priority    = 10
      action      = "block"
      rule_type   = "xss"
      metric_name = "CrossSiteScripting_BODY_Block"
      statement = jsonencode({
        and_statement = {
          statements = [
            {
              xss_match_statement = {
                field_to_match = {
                  body = {}
                }
                text_transformations = [
                  {
                    priority = 1
                    type     = "URL_DECODE"
                  },
                  {
                    priority = 2
                    type     = "HTML_ENTITY_DECODE"
                  }
                ]
              }
            },
            {
              not_statement = {
                statement = {
                  or_statement = {
                    statements = [
                      {
                        byte_match_statement = {
                          field_to_match = {
                            uri_path = {}
                          }
                          positional_constraint = "STARTS_WITH"
                          search_string         = "/testo/"
                          text_transformations = [
                            {
                              priority = 1
                              type     = "LOWERCASE"
                            }
                          ]
                        }
                      },
                      {
                        byte_match_statement = {
                          field_to_match = {
                            uri_path = {}
                          }
                          positional_constraint = "STARTS_WITH"
                          search_string         = "/appgo/"
                          text_transformations = [
                            {
                              priority = 1
                              type     = "LOWERCASE"
                            }
                          ]
                        }
                      }
                    ]
                  }
                }
              }
            }
          ]
        }
      })
    },
    {
      name        = "SizeRestrictions_BODY_Block"
      priority    = 20
      action      = "block"
      rule_type   = "size_restriction"
      metric_name = "SizeRestrictions_BODY_Block"
      statement = jsonencode({
        and_statement = {
          statements = [
            {
              size_constraint_statement = {
                field_to_match = {
                  body = {}
                }
                comparison_operator = "GT"
                size                = 8192
                text_transformations = [
                  {
                    priority = 1
                    type     = "NONE"
                  }
                ]
              }
            },
            {
              not_statement = {
                statement = {
                  or_statement = {
                    statements = [
                      {
                        byte_match_statement = {
                          field_to_match = {
                            uri_path = {}
                          }
                          positional_constraint = "STARTS_WITH"
                          search_string         = "/testo/"
                          text_transformations = [
                            {
                              priority = 1
                              type     = "LOWERCASE"
                            }
                          ]
                        }
                      },
                      {
                        byte_match_statement = {
                          field_to_match = {
                            uri_path = {}
                          }
                          positional_constraint = "STARTS_WITH"
                          search_string         = "/appgo/"
                          text_transformations = [
                            {
                              priority = 1
                              type     = "LOWERCASE"
                            }
                          ]
                        }
                      }
                    ]
                  }
                }
              }
            }
          ]
        }
      })
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
        "CrossSiteScripting_BODY_Block (Priority 10) - Blocks XSS attempts in request body (except /testo/ and /appgo/)",
        "SizeRestrictions_BODY_Block (Priority 20) - Blocks requests with body > 8KB (except /testo/ and /appgo/)"
      ]
    }
    use_cases = [
      "Quick WAF deployment with URI exceptions",
      "Basic web application protection with path-based allowlists",
      "XSS protection for request bodies (with /testo/ and /appgo/ exceptions)",
      "Request size limiting (with /testo/ and /appgo/ exceptions)",
      "Simple configuration with essential rules and URI-based exceptions"
    ]
  }
}

output "custom_rules_details" {
  description = "Details of the custom inline rules with embedded URI exceptions"
  value = {
    xss_protection_with_exceptions = {
      name            = "CrossSiteScripting_BODY_Block"
      priority        = 10
      action          = "block"
      description     = "Blocks XSS attempts in request body using AND logic with NOT statement for URI exceptions"
      field           = "body"
      transformations = ["URL_DECODE", "HTML_ENTITY_DECODE"]
      exceptions      = ["/testo/", "/appgo/"]
      logic           = "Block if (XSS detected) AND NOT (URI starts with /testo/ OR /appgo/)"
    }
    size_restriction_with_exceptions = {
      name        = "SizeRestrictions_BODY_Block"
      priority    = 20
      action      = "block"
      description = "Blocks large request bodies using AND logic with NOT statement for URI exceptions"
      field       = "body"
      size_limit  = "8192 bytes (8KB)"
      exceptions  = ["/testo/", "/appgo/"]
      logic       = "Block if (body size > 8KB) AND NOT (URI starts with /testo/ OR /appgo/)"
    }
    implementation_approach = {
      method = "Embedded exceptions using complex logical statements"
      benefits = [
        "More efficient - single rule evaluation",
        "Cleaner logic - exceptions embedded in protection rules",
        "Better performance - fewer rules to process",
        "AWS WAF v2 best practice - uses complex logical statements"
      ]
      statement_structure = "AND(protection_condition, NOT(OR(exception1, exception2)))"
    }
  }
}