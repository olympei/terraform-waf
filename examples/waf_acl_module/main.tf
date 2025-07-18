provider "aws" {
  region = "us-east-1"
}

# Variables for configuration
variable "name" {
  description = "Name of the WAF Web ACL"
  type        = string
  default     = "waf-acl-example"
}

variable "scope" {
  description = "Scope of the WAF (REGIONAL or CLOUDFRONT)"
  type        = string
  default     = "REGIONAL"
}

variable "default_action" {
  description = "Default action for the WAF (allow or block)"
  type        = string
  default     = "allow"
}

variable "alb_arn_list" {
  description = "List of ALB ARNs to associate with the WAF"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default = {
    Environment = "example"
    Purpose     = "WAF ACL Module Demo"
  }
}

# Example 1: Create a custom rule group first
module "custom_rule_group" {
  source = "../../modules/waf-rule-group"

  rule_group_name = "${var.name}-custom-rules"
  name            = "${var.name}-custom-rules"
  scope           = var.scope
  capacity        = 100
  metric_name     = "CustomRuleGroup"

  custom_rules = [
    {
      name           = "BlockSQLInjection"
      priority       = 1
      action         = "block"
      metric_name    = "block_sqli"
      type           = "sqli"
      field_to_match = "body"
    },
    {
      name           = "BlockXSS"
      priority       = 2
      action         = "block"
      metric_name    = "block_xss"
      type           = "xss"
      field_to_match = "uri_path"
    }
  ]

  tags = var.tags
}

# Example 2: WAF ACL using the custom rule group
module "waf_acl_with_custom_rules" {
  source = "../../modules/waf"

  name                    = "${var.name}-with-custom"
  scope                   = var.scope
  default_action          = var.default_action
  aws_managed_rule_groups = []
  custom_inline_rules     = []
  alb_arn_list            = var.alb_arn_list

  rule_group_arn_list = [
    {
      arn      = module.custom_rule_group.waf_rule_group_arn
      name     = "custom-rule-group"
      priority = 100
    }
  ]

  tags = merge(var.tags, {
    Type = "Custom-Rules"
  })
}

# Example 3: WAF ACL with AWS managed rules
module "waf_acl_with_aws_managed" {
  source = "../../modules/waf"

  name                = "${var.name}-with-aws-managed"
  scope               = var.scope
  default_action      = var.default_action
  rule_group_arn_list = []
  custom_inline_rules = []
  alb_arn_list        = var.alb_arn_list

  aws_managed_rule_groups = [
    {
      name            = "AWSManagedRulesCommonRuleSet"
      vendor_name     = "AWS"
      priority        = 200
      override_action = "none"
    },
    {
      name            = "AWSManagedRulesSQLiRuleSet"
      vendor_name     = "AWS"
      priority        = 201
      override_action = "none"
    }
  ]

  tags = merge(var.tags, {
    Type = "AWS-Managed"
  })
}

# Example 4: WAF ACL with object-based inline rules (NEW FUNCTIONALITY)
module "waf_acl_with_object_inline_rules" {
  source = "../../modules/waf"

  name                    = "${var.name}-object-inline"
  scope                   = var.scope
  default_action          = var.default_action
  aws_managed_rule_groups = []
  rule_group_arn_list     = []
  alb_arn_list            = var.alb_arn_list

  # New object-based inline rules
  custom_inline_rules = [
    {
      name        = "ObjectBasedSQLi"
      priority    = 300
      action      = "block"
      metric_name = "object_sqli_block"
      statement_config = {
        sqli_match_statement = {
          field_to_match = {
            body = {}
          }
          text_transformation = {
            priority = 0
            type     = "NONE"
          }
        }
      }
    },
    {
      name        = "ObjectBasedXSS"
      priority    = 301
      action      = "block"
      metric_name = "object_xss_block"
      statement_config = {
        xss_match_statement = {
          field_to_match = {
            query_string = {}
          }
          text_transformation = {
            priority = 0
            type     = "URL_DECODE"
          }
        }
      }
    },
    {
      name        = "ObjectBasedRateLimit"
      priority    = 302
      action      = "block"
      metric_name = "object_rate_limit"
      statement_config = {
        rate_based_statement = {
          limit              = 2000
          aggregate_key_type = "IP"
        }
      }
    },
    {
      name        = "ObjectBasedGeoBlock"
      priority    = 303
      action      = "block"
      metric_name = "object_geo_block"
      statement_config = {
        geo_match_statement = {
          country_codes = ["CN", "RU", "KP"]
        }
      }
    },
    {
      name        = "ObjectBasedSizeConstraint"
      priority    = 304
      action      = "block"
      metric_name = "object_size_constraint"
      statement_config = {
        size_constraint_statement = {
          comparison_operator = "GT"
          size                = 8192
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

  tags = merge(var.tags, {
    Type = "Object-Inline-Rules"
  })
}

# Example 5: Comprehensive WAF ACL with multiple rule types
module "waf_acl_comprehensive" {
  source = "../../modules/waf"

  name           = "${var.name}-comprehensive"
  scope          = var.scope
  default_action = var.default_action
  alb_arn_list   = var.alb_arn_list

  # Custom rule group
  rule_group_arn_list = [
    {
      arn      = module.custom_rule_group.waf_rule_group_arn
      name     = "comprehensive-custom-rules"
      priority = 100
    }
  ]

  # AWS managed rules
  aws_managed_rule_groups = [
    {
      name            = "AWSManagedRulesCommonRuleSet"
      vendor_name     = "AWS"
      priority        = 200
      override_action = "none"
    },
    {
      name            = "AWSManagedRulesKnownBadInputsRuleSet"
      vendor_name     = "AWS"
      priority        = 201
      override_action = "count"
    }
  ]

  # Inline rules - using object-based configuration for advanced rules
  custom_inline_rules = [
    {
      name        = "ComprehensiveIPBlock"
      priority    = 400
      action      = "block"
      metric_name = "comprehensive_ip_block"
      statement_config = {
        byte_match_statement = {
          search_string         = "malicious-bot"
          positional_constraint = "CONTAINS"
          field_to_match = {
            single_header = {
              name = "user-agent"
            }
          }
          text_transformation = {
            priority = 0
            type     = "LOWERCASE"
          }
        }
      }
    },
    {
      name        = "ComprehensiveRateLimit"
      priority    = 401
      action      = "block"
      metric_name = "comprehensive_rate_limit"
      statement_config = {
        rate_based_statement = {
          limit              = 1000
          aggregate_key_type = "IP"
        }
      }
    }
  ]

  tags = merge(var.tags, {
    Type = "Comprehensive"
  })
}

# Outputs
output "custom_rule_group_arn" {
  description = "ARN of the custom rule group"
  value       = module.custom_rule_group.waf_rule_group_arn
}

output "waf_acl_custom_rules_arn" {
  description = "ARN of WAF ACL with custom rules"
  value       = module.waf_acl_with_custom_rules.web_acl_arn
}

output "waf_acl_aws_managed_arn" {
  description = "ARN of WAF ACL with AWS managed rules"
  value       = module.waf_acl_with_aws_managed.web_acl_arn
}

output "waf_acl_object_inline_rules_arn" {
  description = "ARN of WAF ACL with object-based inline rules"
  value       = module.waf_acl_with_object_inline_rules.web_acl_arn
}

output "waf_acl_comprehensive_arn" {
  description = "ARN of comprehensive WAF ACL"
  value       = module.waf_acl_comprehensive.web_acl_arn
}