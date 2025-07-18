provider "aws" {
  region = "us-east-1"
}

# Variables for configuration
variable "name" {
  description = "Base name for resources"
  type        = string
  default     = "enhanced-waf-rules"
}

variable "scope" {
  description = "Scope of the WAF (REGIONAL or CLOUDFRONT)"
  type        = string
  default     = "REGIONAL"
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default = {
    Environment = "demo"
    Purpose     = "Enhanced WAF Rule Group Demo"
  }
}

# Example 1: Simple Type-Based Rules (Easy Configuration)
module "simple_rule_group" {
  source = "../../modules/waf-rule-group"

  rule_group_name = "${var.name}-simple"
  name            = "${var.name}-simple"
  scope           = var.scope
  capacity        = 200
  metric_name     = "SimpleRuleGroup"

  custom_rules = [
    # SQL Injection Protection
    {
      name           = "SimpleSQLi"
      priority       = 1
      action         = "block"
      metric_name    = "simple_sqli"
      type           = "sqli"
      field_to_match = "body"
    },
    # XSS Protection
    {
      name           = "SimpleXSS"
      priority       = 2
      action         = "block"
      metric_name    = "simple_xss"
      type           = "xss"
      field_to_match = "uri_path"
    },
    # Rate Limiting (NEW)
    {
      name               = "SimpleRateLimit"
      priority           = 3
      action             = "block"
      metric_name        = "simple_rate_limit"
      type               = "rate_based"
      rate_limit         = 1000
      aggregate_key_type = "IP"
    },
    # Geographic Blocking (NEW)
    {
      name          = "SimpleGeoBlock"
      priority      = 4
      action        = "block"
      metric_name   = "simple_geo_block"
      type          = "geo_match"
      country_codes = ["CN", "RU", "KP"]
    },
    # Size Constraint (NEW)
    {
      name                = "SimpleSizeLimit"
      priority            = 5
      action              = "block"
      metric_name         = "simple_size_limit"
      type                = "size_constraint"
      field_to_match      = "body"
      comparison_operator = "GT"
      size                = 10240
    }
  ]

  tags = var.tags
}

# Example 2: Advanced Object-Based Rules (Full Control)
module "advanced_rule_group" {
  source = "../../modules/waf-rule-group"

  rule_group_name = "${var.name}-advanced"
  name            = "${var.name}-advanced"
  scope           = var.scope
  capacity        = 300
  metric_name     = "AdvancedRuleGroup"

  custom_rules = [
    # Advanced SQL Injection with Header Inspection
    {
      name        = "AdvancedSQLiHeader"
      priority    = 10
      action      = "block"
      metric_name = "advanced_sqli_header"
      statement_config = {
        sqli_match_statement = {
          field_to_match = {
            single_header = {
              name = "x-custom-header"
            }
          }
          text_transformation = {
            priority = 1
            type     = "URL_DECODE"
          }
        }
      }
    },
    # Advanced XSS with Multiple Transformations
    {
      name        = "AdvancedXSSQuery"
      priority    = 11
      action      = "block"
      metric_name = "advanced_xss_query"
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
    # Advanced Byte Match for Bot Detection
    {
      name        = "AdvancedBotDetection"
      priority    = 12
      action      = "block"
      metric_name = "advanced_bot_detection"
      statement_config = {
        byte_match_statement = {
          search_string         = "malicious-scanner"
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
    # Advanced Rate Limiting with Forwarded IP
    {
      name        = "AdvancedRateLimit"
      priority    = 13
      action      = "count" # Count first, then block in production
      metric_name = "advanced_rate_limit"
      statement_config = {
        rate_based_statement = {
          limit              = 500
          aggregate_key_type = "FORWARDED_IP"
        }
      }
    },
    # Advanced Geographic Blocking
    {
      name        = "AdvancedGeoBlock"
      priority    = 14
      action      = "block"
      metric_name = "advanced_geo_block"
      statement_config = {
        geo_match_statement = {
          country_codes = ["CN", "RU", "KP", "IR", "SY"]
        }
      }
    },
    # Advanced Size Constraint for URI Path
    {
      name        = "AdvancedURISize"
      priority    = 15
      action      = "block"
      metric_name = "advanced_uri_size"
      statement_config = {
        size_constraint_statement = {
          comparison_operator = "GT"
          size                = 2048
          field_to_match = {
            uri_path = {}
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
    Type = "Advanced"
  })
}

# Example 3: Comprehensive Security Rule Group
module "comprehensive_rule_group" {
  source = "../../modules/waf-rule-group"

  rule_group_name = "${var.name}-comprehensive"
  name            = "${var.name}-comprehensive"
  scope           = var.scope
  capacity        = 500
  metric_name     = "ComprehensiveRuleGroup"

  custom_rules = [
    # Layer 1: Input Validation
    {
      name        = "InputSizeValidation"
      priority    = 20
      action      = "block"
      metric_name = "input_size_validation"
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
    # Layer 2: Injection Attacks
    {
      name        = "ComprehensiveSQLi"
      priority    = 21
      action      = "block"
      metric_name = "comprehensive_sqli"
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
      name        = "ComprehensiveXSS"
      priority    = 22
      action      = "block"
      metric_name = "comprehensive_xss"
      statement_config = {
        xss_match_statement = {
          field_to_match = {
            body = {}
          }
          text_transformation = {
            priority = 2
            type     = "HTML_ENTITY_DECODE"
          }
        }
      }
    },
    # Layer 3: Rate Limiting & DDoS Protection
    {
      name        = "DDoSProtection"
      priority    = 23
      action      = "block"
      metric_name = "ddos_protection"
      statement_config = {
        rate_based_statement = {
          limit              = 2000
          aggregate_key_type = "IP"
        }
      }
    },
    # Layer 4: Geographic Security
    {
      name        = "HighRiskCountries"
      priority    = 24
      action      = "block"
      metric_name = "high_risk_countries"
      statement_config = {
        geo_match_statement = {
          country_codes = ["CN", "RU", "KP", "IR", "SY", "CU", "SD"]
        }
      }
    },
    # Layer 5: Bot & Scanner Detection
    {
      name        = "ScannerDetection"
      priority    = 25
      action      = "block"
      metric_name = "scanner_detection"
      statement_config = {
        byte_match_statement = {
          search_string         = "nmap"
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
    # Layer 6: Method Validation
    {
      name        = "MethodValidation"
      priority    = 26
      action      = "count" # Monitor unusual methods
      metric_name = "method_validation"
      statement_config = {
        byte_match_statement = {
          search_string         = "TRACE"
          positional_constraint = "EXACTLY"
          field_to_match = {
            method = {}
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
    Type     = "Comprehensive"
    Security = "Multi-Layer"
  })
}

# Outputs
output "simple_rule_group_arn" {
  description = "ARN of the simple rule group"
  value       = module.simple_rule_group.waf_rule_group_arn
}

output "advanced_rule_group_arn" {
  description = "ARN of the advanced rule group"
  value       = module.advanced_rule_group.waf_rule_group_arn
}

output "comprehensive_rule_group_arn" {
  description = "ARN of the comprehensive rule group"
  value       = module.comprehensive_rule_group.waf_rule_group_arn
}

output "rule_group_summary" {
  description = "Summary of created rule groups"
  value = {
    simple = {
      name             = module.simple_rule_group.waf_rule_group_name
      arn              = module.simple_rule_group.waf_rule_group_arn
      rules            = 5
      protection_types = ["SQLi", "XSS", "Rate Limiting", "Geo Blocking", "Size Constraint"]
    }
    advanced = {
      name             = module.advanced_rule_group.waf_rule_group_name
      arn              = module.advanced_rule_group.waf_rule_group_arn
      rules            = 6
      protection_types = ["Advanced SQLi", "Advanced XSS", "Bot Detection", "Advanced Rate Limiting", "Geo Blocking", "URI Size Validation"]
    }
    comprehensive = {
      name             = module.comprehensive_rule_group.waf_rule_group_name
      arn              = module.comprehensive_rule_group.waf_rule_group_arn
      rules            = 7
      protection_types = ["Multi-Layer Security", "Input Validation", "Injection Protection", "DDoS Protection", "Geographic Security", "Bot Detection", "Method Validation"]
    }
  }
}