provider "aws" {
  region = "us-east-1"
}

# Variables for configuration
variable "name" {
  description = "Name of the WAF ACL"
  type        = string
  default     = "block-default-allow-http-waf"
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

variable "alb_arn_list" {
  description = "List of ALB ARNs to associate with the WAF"
  type        = list(string)
  default     = []
}

variable "allowed_countries" {
  description = "List of allowed country codes (ISO 3166-1 alpha-2)"
  type        = list(string)
  default     = ["US", "CA", "GB", "DE", "FR", "AU", "JP"]
}

variable "allowed_user_agents" {
  description = "List of allowed user agent patterns"
  type        = list(string)
  default = [
    "Mozilla",
    "Chrome",
    "Safari",
    "Edge",
    "Firefox"
  ]
}

variable "rate_limit_threshold" {
  description = "Rate limit threshold per IP (requests per 5 minutes)"
  type        = number
  default     = 2000
}

variable "enable_logging" {
  description = "Enable WAF logging to CloudWatch"
  type        = bool
  default     = true
}

variable "create_log_group" {
  description = "Create a new CloudWatch log group for WAF logs"
  type        = bool
  default     = true
}

variable "existing_log_group_arn" {
  description = "ARN of existing CloudWatch log group for WAF logs (used when create_log_group = false)"
  type        = string
  default     = null
}

variable "log_group_name" {
  description = "Name for the CloudWatch log group (only used when create_log_group = true)"
  type        = string
  default     = null
}

variable "log_group_retention_days" {
  description = "Number of days to retain WAF logs in CloudWatch"
  type        = number
  default     = 30

  validation {
    condition = contains([
      1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653
    ], var.log_group_retention_days)
    error_message = "Log group retention must be one of the allowed values: 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653 days."
  }
}

variable "kms_key_id" {
  description = "KMS Key ID for encrypting CloudWatch logs (optional)"
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags to apply to WAF resources"
  type        = map(string)
  default = {
    Environment = "demo"
    Purpose     = "Block Default Allow HTTP Example"
    Example     = "block_default_allow_http"
  }
}

# WAF ACL with default_action = "block" and explicit allow rules
module "block_default_waf" {
  source = "../../modules/waf"

  name           = var.name
  scope          = var.scope
  default_action = "block" # Block everything by default
  alb_arn_list   = var.alb_arn_list

  # CloudWatch logging configuration
  create_log_group            = var.enable_logging ? var.create_log_group : false
  existing_log_group_arn      = var.enable_logging && !var.create_log_group ? var.existing_log_group_arn : null
  log_group_name              = var.enable_logging && var.create_log_group ? var.log_group_name : null
  log_group_retention_in_days = var.enable_logging && var.create_log_group ? var.log_group_retention_days : null
  kms_key_id                  = var.enable_logging && var.create_log_group ? var.kms_key_id : null

  # No custom rule groups for this example
  rule_group_arn_list = []

  # AWS managed rules with COUNT action to monitor without blocking
  aws_managed_rule_groups = [
    {
      name            = "AWSManagedRulesCommonRuleSet"
      vendor_name     = "AWS"
      priority        = 100
      override_action = "count" # Count malicious requests but don't block (we'll handle blocking with custom rules)
    },
    {
      name            = "AWSManagedRulesSQLiRuleSet"
      vendor_name     = "AWS"
      priority        = 101
      override_action = "count" # Count SQL injection attempts
    }
  ]

  # Custom inline rules to explicitly ALLOW legitimate traffic
  custom_inline_rules = [
    # Rule 1: Allow traffic from specific countries
    {
      name        = "AllowSpecificCountries"
      priority    = 200
      action      = "allow"
      metric_name = "allow_specific_countries"
      statement_config = {
        geo_match_statement = {
          country_codes = var.allowed_countries
        }
      }
    },

    # Rule 2: Allow legitimate browsers (User-Agent check)
    {
      name        = "AllowLegitimateUserAgents"
      priority    = 201
      action      = "allow"
      metric_name = "allow_legitimate_user_agents"
      statement_config = {
        byte_match_statement = {
          search_string         = "Mozilla"
          positional_constraint = "CONTAINS"
          field_to_match = {
            single_header = {
              name = "user-agent"
            }
          }
          text_transformation = {
            priority = 0
            type     = "NONE"
          }
        }
      }
    },

    # Rule 3: Allow standard HTTP methods
    {
      name        = "AllowStandardHTTPMethods"
      priority    = 202
      action      = "allow"
      metric_name = "allow_standard_http_methods"
      statement_config = {
        byte_match_statement = {
          search_string         = "GET"
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
    },

    # Rule 4: Allow POST requests (for forms, APIs)
    {
      name        = "AllowPOSTRequests"
      priority    = 203
      action      = "allow"
      metric_name = "allow_post_requests"
      statement_config = {
        byte_match_statement = {
          search_string         = "POST"
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
    },

    # Rule 5: Allow PUT requests (for APIs)
    {
      name        = "AllowPUTRequests"
      priority    = 204
      action      = "allow"
      metric_name = "allow_put_requests"
      statement_config = {
        byte_match_statement = {
          search_string         = "PUT"
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
    },

    # Rule 6: Allow requests with standard Accept headers
    {
      name        = "AllowStandardAcceptHeaders"
      priority    = 205
      action      = "allow"
      metric_name = "allow_standard_accept_headers"
      statement_config = {
        byte_match_statement = {
          search_string         = "text/html"
          positional_constraint = "CONTAINS"
          field_to_match = {
            single_header = {
              name = "accept"
            }
          }
          text_transformation = {
            priority = 0
            type     = "LOWERCASE"
          }
        }
      }
    },

    # Rule 7: Allow JSON API requests
    {
      name        = "AllowJSONRequests"
      priority    = 206
      action      = "allow"
      metric_name = "allow_json_requests"
      statement_config = {
        byte_match_statement = {
          search_string         = "application/json"
          positional_constraint = "CONTAINS"
          field_to_match = {
            single_header = {
              name = "content-type"
            }
          }
          text_transformation = {
            priority = 0
            type     = "LOWERCASE"
          }
        }
      }
    },

    # Rule 8: Rate limiting - Block excessive requests even from allowed sources
    {
      name        = "BlockExcessiveRequests"
      priority    = 300
      action      = "block"
      metric_name = "block_excessive_requests"
      statement_config = {
        rate_based_statement = {
          limit              = var.rate_limit_threshold
          aggregate_key_type = "IP"
        }
      }
    },

    # Rule 9: Block requests with suspicious patterns
    {
      name        = "BlockSuspiciousPatterns"
      priority    = 301
      action      = "block"
      metric_name = "block_suspicious_patterns"
      statement_config = {
        byte_match_statement = {
          search_string         = "../"
          positional_constraint = "CONTAINS"
          field_to_match = {
            uri_path = {}
          }
          text_transformation = {
            priority = 0
            type     = "URL_DECODE"
          }
        }
      }
    },

    # Rule 10: Block requests with large payloads
    {
      name        = "BlockLargePayloads"
      priority    = 302
      action      = "block"
      metric_name = "block_large_payloads"
      statement_config = {
        size_constraint_statement = {
          comparison_operator = "GT"
          size                = 1048576 # 1MB limit
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
  description = "ARN of the block-default WAF ACL"
  value       = module.block_default_waf.web_acl_arn
}

output "waf_acl_id" {
  description = "ID of the block-default WAF ACL"
  value       = module.block_default_waf.web_acl_id
}

output "cloudwatch_log_group_arn" {
  description = "ARN of the CloudWatch log group for WAF logs"
  value       = var.enable_logging && var.create_log_group ? module.block_default_waf.cloudwatch_log_group_arn : var.existing_log_group_arn
}

output "cloudwatch_log_group_name" {
  description = "Name of the CloudWatch log group for WAF logs"
  value       = var.enable_logging ? (var.create_log_group ? module.block_default_waf.cloudwatch_log_group_name : split(":", var.existing_log_group_arn)[6]) : null
}

output "logging_configuration" {
  description = "CloudWatch logging configuration details"
  value = {
    enabled           = var.enable_logging
    log_group_created = var.enable_logging && var.create_log_group
    log_group_arn     = var.enable_logging && var.create_log_group ? module.block_default_waf.cloudwatch_log_group_arn : var.existing_log_group_arn
    log_group_name    = var.enable_logging ? (var.create_log_group ? module.block_default_waf.cloudwatch_log_group_name : split(":", var.existing_log_group_arn)[6]) : null
    retention_days    = var.enable_logging && var.create_log_group ? var.log_group_retention_days : null
    kms_encrypted     = var.enable_logging && var.create_log_group && var.kms_key_id != null ? true : false

    log_analysis_commands = var.enable_logging ? {
      view_recent_logs        = "aws logs tail ${var.enable_logging ? (var.create_log_group ? module.block_default_waf.cloudwatch_log_group_name : split(":", var.existing_log_group_arn)[6]) : "N/A"} --follow"
      filter_blocked_requests = "aws logs filter-log-events --log-group-name ${var.enable_logging ? (var.create_log_group ? module.block_default_waf.cloudwatch_log_group_name : split(":", var.existing_log_group_arn)[6]) : "N/A"} --filter-pattern '{ $.action = \"BLOCK\" }'"
      filter_allowed_requests = "aws logs filter-log-events --log-group-name ${var.enable_logging ? (var.create_log_group ? module.block_default_waf.cloudwatch_log_group_name : split(":", var.existing_log_group_arn)[6]) : "N/A"} --filter-pattern '{ $.action = \"ALLOW\" }'"
      filter_rate_limited     = "aws logs filter-log-events --log-group-name ${var.enable_logging ? (var.create_log_group ? module.block_default_waf.cloudwatch_log_group_name : split(":", var.existing_log_group_arn)[6]) : "N/A"} --filter-pattern '{ $.terminatingRuleId = \"BlockExcessiveRequests\" }'"
    } : null
  }
}

output "waf_configuration_summary" {
  description = "Summary of the block-default WAF configuration"
  value = {
    name           = var.name
    scope          = var.scope
    default_action = "block"
    arn            = module.block_default_waf.web_acl_arn

    security_model = "Default Deny - Explicit Allow"

    allowed_traffic = {
      countries     = var.allowed_countries
      user_agents   = var.allowed_user_agents
      http_methods  = ["GET", "POST", "PUT"]
      content_types = ["text/html", "application/json"]
      rate_limit    = "${var.rate_limit_threshold} requests per 5 minutes"
    }

    blocked_traffic = {
      default_behavior    = "Block all traffic not explicitly allowed"
      rate_limiting       = "Block IPs exceeding ${var.rate_limit_threshold} requests/5min"
      suspicious_patterns = "Block path traversal attempts (../)"
      large_payloads      = "Block requests larger than 1MB"
      monitoring          = "Count (but don't block) SQL injection and common attacks"
    }

    rule_priorities = {
      aws_managed_rules = "100-101 (count mode)"
      allow_rules       = "200-206"
      block_rules       = "300-302"
    }

    use_cases = [
      "High-security applications",
      "Zero-trust network model",
      "Compliance requirements (PCI DSS, SOX)",
      "API endpoints with strict access control",
      "Applications handling sensitive data"
    ]

    warnings = [
      "Default action is BLOCK - ensure allow rules cover all legitimate traffic",
      "Test thoroughly in staging before production deployment",
      "Monitor CloudWatch metrics for blocked legitimate requests",
      "Consider using count mode initially for testing"
    ]
  }
}

output "testing_guide" {
  description = "Guide for testing the block-default WAF configuration"
  value = {
    legitimate_traffic_tests = {
      basic_web_request = "curl -H 'User-Agent: Mozilla/5.0' https://your-app.com/"
      json_api_request  = "curl -H 'Content-Type: application/json' -H 'User-Agent: Mozilla/5.0' -X POST https://your-app.com/api"
      form_submission   = "curl -H 'User-Agent: Mozilla/5.0' -X POST -d 'field=value' https://your-app.com/form"
    }

    blocked_traffic_tests = {
      no_user_agent   = "curl https://your-app.com/"
      suspicious_path = "curl -H 'User-Agent: Mozilla/5.0' https://your-app.com/../etc/passwd"
      large_payload   = "curl -H 'User-Agent: Mozilla/5.0' -X POST -d '@large-file.txt' https://your-app.com/"
      rate_limit_test = "for i in {1..2100}; do curl -H 'User-Agent: Mozilla/5.0' https://your-app.com/; done"
    }

    monitoring_commands = {
      allowed_requests = "aws cloudwatch get-metric-statistics --namespace AWS/WAFV2 --metric-name AllowedRequests --dimensions Name=WebACL,Value=${var.name}"
      blocked_requests = "aws cloudwatch get-metric-statistics --namespace AWS/WAFV2 --metric-name BlockedRequests --dimensions Name=WebACL,Value=${var.name}"
      sampled_requests = "aws wafv2 get-sampled-requests --web-acl-arn <WAF-ARN> --rule-metric-name <RULE-NAME> --scope ${var.scope} --time-window StartTime=<START>,EndTime=<END> --max-items 100"
    }
  }
}