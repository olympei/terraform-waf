provider "aws" {
  region = "us-east-1"
}

module "custom_rule_group" {
  source = "../../modules/waf-rule-group"

  rule_group_name = "custom-rule-group-hybrid"
  name            = "custom-rule-group-hybrid"
  scope           = "REGIONAL"
  capacity        = 200
  metric_name     = "CustomRuleGroupHybrid"
  tags = {
    Environment = "dev"
  }

  custom_rules = [
    # Simple type-based rule (backward compatible approach)
    {
      name           = "SimpleBlockSQLi"
      priority       = 1
      metric_name    = "simple_sqli_rule"
      type           = "sqli"
      field_to_match = "body"
      action         = "block"
    },

    # Simple type-based XSS rule
    {
      name           = "SimpleBlockXSS"
      priority       = 2
      metric_name    = "simple_xss_rule"
      type           = "xss"
      field_to_match = "uri_path"
      action         = "block"
    },

    # Simple type-based rate limiting (NEW)
    {
      name               = "SimpleRateLimit"
      priority           = 3
      metric_name        = "simple_rate_limit"
      type               = "rate_based"
      action             = "block"
      rate_limit         = 1000
      aggregate_key_type = "IP"
    },

    # Simple type-based geo blocking (NEW)
    {
      name          = "SimpleGeoBlock"
      priority      = 4
      metric_name   = "simple_geo_block"
      type          = "geo_match"
      action        = "block"
      country_codes = ["CN", "RU"]
    },

    # Advanced object-based SQL injection with header inspection
    {
      name        = "AdvancedSQLiHeader"
      priority    = 10
      metric_name = "advanced_sqli_header"
      action      = "block"
      statement_config = {
        sqli_match_statement = {
          field_to_match = {
            single_header = {
              name = "x-forwarded-for"
            }
          }
          text_transformation = {
            priority = 1
            type     = "URL_DECODE"
          }
        }
      }
    },

    # Advanced object-based XSS with query string inspection
    {
      name        = "AdvancedXSSQuery"
      priority    = 11
      metric_name = "advanced_xss_query"
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

    # Advanced object-based rate limiting with forwarded IP
    {
      name        = "AdvancedRateLimit"
      priority    = 12
      metric_name = "advanced_rate_limit"
      action      = "count" # Count first for monitoring
      statement_config = {
        rate_based_statement = {
          limit              = 500
          aggregate_key_type = "FORWARDED_IP"
        }
      }
    },

    # Advanced object-based geographic blocking
    {
      name        = "AdvancedGeoBlock"
      priority    = 13
      metric_name = "advanced_geo_block"
      action      = "block"
      statement_config = {
        geo_match_statement = {
          country_codes = ["CN", "RU", "KP", "IR", "SY"]
        }
      }
    },

    # Advanced object-based size constraint
    {
      name        = "AdvancedSizeConstraint"
      priority    = 14
      metric_name = "advanced_size_constraint"
      action      = "block"
      statement_config = {
        size_constraint_statement = {
          comparison_operator = "GT"
          size                = 16384 # 16KB limit
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

    # Advanced object-based byte match for bot detection
    {
      name        = "AdvancedBotDetection"
      priority    = 15
      metric_name = "advanced_bot_detection"
      action      = "block"
      statement_config = {
        byte_match_statement = {
          search_string         = "bot"
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
    }
  ]
}

# Outputs
output "hybrid_rule_group_arn" {
  description = "ARN of the hybrid rule group"
  value       = module.custom_rule_group.waf_rule_group_arn
}

output "hybrid_rule_group_name" {
  description = "Name of the hybrid rule group"
  value       = module.custom_rule_group.waf_rule_group_name
}

output "hybrid_rule_group_capacity" {
  description = "Capacity of the hybrid rule group"
  value       = module.custom_rule_group.waf_rule_group_capacity
}

output "rule_summary" {
  description = "Summary of rules in the hybrid rule group"
  value = {
    total_rules = 10
    simple_rules = {
      count = 4
      types = ["SQLi", "XSS", "Rate Limiting", "Geo Blocking"]
    }
    advanced_rules = {
      count = 6
      types = ["Header SQLi", "Query XSS", "Forwarded IP Rate Limiting", "Extended Geo Blocking", "Size Constraint", "Bot Detection"]
    }
    protection_coverage = [
      "SQL Injection (body + header)",
      "XSS (URI path + query string)",
      "Rate Limiting (IP + Forwarded IP)",
      "Geographic Blocking (basic + extended)",
      "Size Constraints (16KB body limit)",
      "Bot Detection (User-Agent analysis)"
    ]
  }
}