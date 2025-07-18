provider "aws" {
  region = "us-east-1"
}

# Variables for configuration
variable "alb_arn_list" {
  description = "List of ALB ARNs to associate with the WAF"
  type        = list(string)
  default = [
    # Example ALB ARN - replace with your actual ALB ARN
    "arn:aws:elasticloadbalancing:us-east-1:123456789012:loadbalancer/app/example-alb/50dc6c495c0c9188"
  ]
}

variable "name" {
  description = "Base name for WAF resources"
  type        = string
  default     = "custom-rule-group-waf"
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

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    Environment = "demo"
    Purpose     = "Custom Rule Group WAF ACL Example"
    Example     = "custom_rule_group_waf_acl"
  }
}

# Example 1: Basic Custom Rule Group with Simple Rules
module "basic_custom_rule_group" {
  source = "../../modules/waf-rule-group"

  rule_group_name = "${var.name}-basic-rules"
  name            = "${var.name}-basic-rules"
  scope           = var.scope
  capacity        = 100
  metric_name     = "BasicCustomRuleGroup"

  # Simple type-based rules (easy configuration)
  custom_rules = [
    {
      name           = "BasicSQLiProtection"
      priority       = 1
      metric_name    = "basic_sqli_protection"
      type           = "sqli"
      field_to_match = "body"
      action         = "block"
    },
    {
      name           = "BasicXSSProtection"
      priority       = 2
      metric_name    = "basic_xss_protection"
      type           = "xss"
      field_to_match = "uri_path"
      action         = "block"
    },
    {
      name               = "BasicRateLimit"
      priority           = 3
      metric_name        = "basic_rate_limit"
      type               = "rate_based"
      action             = "block"
      rate_limit         = 2000
      aggregate_key_type = "IP"
    }
  ]

  tags = merge(var.tags, {
    RuleGroupType = "Basic"
  })
}

# Example 2: Advanced Custom Rule Group with Object-Based Rules
module "advanced_custom_rule_group" {
  source = "../../modules/waf-rule-group"

  rule_group_name = "${var.name}-advanced-rules"
  name            = "${var.name}-advanced-rules"
  scope           = var.scope
  capacity        = 200
  metric_name     = "AdvancedCustomRuleGroup"

  # Advanced object-based rules (full control)
  custom_rules = [
    {
      name        = "AdvancedSQLiDetection"
      priority    = 10
      metric_name = "advanced_sqli_detection"
      action      = "block"
      statement_config = {
        sqli_match_statement = {
          field_to_match = {
            all_query_arguments = {}
          }
          text_transformation = {
            priority = 1
            type     = "URL_DECODE"
          }
        }
      }
    },
    {
      name        = "AdvancedXSSDetection"
      priority    = 11
      metric_name = "advanced_xss_detection"
      action      = "block"
      statement_config = {
        xss_match_statement = {
          field_to_match = {
            query_string = {}
          }
          text_transformation = {
            priority = 2
            type     = "HTML_ENTITY_DECODE"
          }
        }
      }
    },
    {
      name        = "AdvancedBotDetection"
      priority    = 12
      metric_name = "advanced_bot_detection"
      action      = "block"
      statement_config = {
        byte_match_statement = {
          search_string         = "scanner"
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
      name        = "AdvancedGeoBlocking"
      priority    = 13
      metric_name = "advanced_geo_blocking"
      action      = "block"
      statement_config = {
        geo_match_statement = {
          country_codes = ["CN", "RU", "KP", "IR"]
        }
      }
    },
    {
      name        = "AdvancedSizeConstraint"
      priority    = 14
      metric_name = "advanced_size_constraint"
      action      = "block"
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
    RuleGroupType = "Advanced"
  })
}

# Example 3: WAF ACL using Basic Custom Rule Group
module "waf_acl_basic" {
  source = "../../modules/waf"

  name                    = "${var.name}-basic"
  scope                   = var.scope
  default_action          = var.default_action
  aws_managed_rule_groups = []
  custom_inline_rules     = []
  alb_arn_list            = var.alb_arn_list

  # Use the basic custom rule group
  rule_group_arn_list = [
    {
      arn      = module.basic_custom_rule_group.waf_rule_group_arn
      name     = "basic-custom-rules"
      priority = 100
    }
  ]

  tags = merge(var.tags, {
    WAFType = "Basic-Custom-Rules"
  })
}

# Example 4: WAF ACL using Advanced Custom Rule Group
module "waf_acl_advanced" {
  source = "../../modules/waf"

  name                    = "${var.name}-advanced"
  scope                   = var.scope
  default_action          = var.default_action
  aws_managed_rule_groups = []
  custom_inline_rules     = []
  alb_arn_list            = var.alb_arn_list

  # Use the advanced custom rule group
  rule_group_arn_list = [
    {
      arn      = module.advanced_custom_rule_group.waf_rule_group_arn
      name     = "advanced-custom-rules"
      priority = 100
    }
  ]

  tags = merge(var.tags, {
    WAFType = "Advanced-Custom-Rules"
  })
}

# Example 5: Comprehensive WAF ACL using Both Rule Groups + AWS Managed Rules
module "waf_acl_comprehensive" {
  source = "../../modules/waf"

  name           = "${var.name}-comprehensive"
  scope          = var.scope
  default_action = var.default_action
  alb_arn_list   = var.alb_arn_list

  # Use both custom rule groups
  rule_group_arn_list = [
    {
      arn      = module.basic_custom_rule_group.waf_rule_group_arn
      name     = "basic-custom-rules"
      priority = 100
    },
    {
      arn      = module.advanced_custom_rule_group.waf_rule_group_arn
      name     = "advanced-custom-rules"
      priority = 200
    }
  ]

  # Add AWS managed rules for additional protection
  aws_managed_rule_groups = [
    {
      name            = "AWSManagedRulesCommonRuleSet"
      vendor_name     = "AWS"
      priority        = 300
      override_action = "none"
    },
    {
      name            = "AWSManagedRulesKnownBadInputsRuleSet"
      vendor_name     = "AWS"
      priority        = 301
      override_action = "count"
    }
  ]

  # Add some inline rules for specific use cases
  custom_inline_rules = [
    {
      name        = "InlineRateLimitAPI"
      priority    = 400
      action      = "block"
      metric_name = "inline_api_rate_limit"
      statement_config = {
        rate_based_statement = {
          limit              = 100
          aggregate_key_type = "IP"
        }
      }
    }
  ]

  tags = merge(var.tags, {
    WAFType = "Comprehensive-Multi-Layer"
  })
}

# Outputs
output "basic_rule_group_arn" {
  description = "ARN of the basic custom rule group"
  value       = module.basic_custom_rule_group.waf_rule_group_arn
}

output "advanced_rule_group_arn" {
  description = "ARN of the advanced custom rule group"
  value       = module.advanced_custom_rule_group.waf_rule_group_arn
}

output "waf_acl_basic_arn" {
  description = "ARN of the basic WAF ACL"
  value       = module.waf_acl_basic.web_acl_arn
}

output "waf_acl_advanced_arn" {
  description = "ARN of the advanced WAF ACL"
  value       = module.waf_acl_advanced.web_acl_arn
}

output "waf_acl_comprehensive_arn" {
  description = "ARN of the comprehensive WAF ACL"
  value       = module.waf_acl_comprehensive.web_acl_arn
}

output "deployment_summary" {
  description = "Summary of all deployed resources"
  value = {
    rule_groups = {
      basic = {
        name     = module.basic_custom_rule_group.waf_rule_group_name
        arn      = module.basic_custom_rule_group.waf_rule_group_arn
        capacity = module.basic_custom_rule_group.waf_rule_group_capacity
        rules    = 3
        types    = ["SQLi", "XSS", "Rate Limiting"]
      }
      advanced = {
        name     = module.advanced_custom_rule_group.waf_rule_group_name
        arn      = module.advanced_custom_rule_group.waf_rule_group_arn
        capacity = module.advanced_custom_rule_group.waf_rule_group_capacity
        rules    = 5
        types    = ["Advanced SQLi", "Advanced XSS", "Bot Detection", "Geo Blocking", "Size Constraint"]
      }
    }
    waf_acls = {
      basic = {
        name       = "${var.name}-basic"
        arn        = module.waf_acl_basic.web_acl_arn
        protection = "Basic custom rules only"
      }
      advanced = {
        name       = "${var.name}-advanced"
        arn        = module.waf_acl_advanced.web_acl_arn
        protection = "Advanced custom rules only"
      }
      comprehensive = {
        name       = "${var.name}-comprehensive"
        arn        = module.waf_acl_comprehensive.web_acl_arn
        protection = "Custom rules + AWS managed rules + inline rules"
      }
    }
    total_resources = {
      rule_groups = 2
      waf_acls    = 3
      total_rules = 9 # 3 basic + 5 advanced + 1 inline
    }
  }
}