terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.3.0"
}

provider "aws" {
  region = "us-east-1"
}

# Test only the valid priorities configuration to verify it works correctly
module "waf_valid_priorities_test" {
  source                  = "../../../modules/waf"
  name                   = "valid-priorities-test"
  scope                  = "REGIONAL"
  default_action         = "allow"
  alb_arn_list          = []
  tags                   = {
    Environment = "test"
    Purpose     = "Valid Priority Test"
    Example     = "valid-only"
  }

  # Custom rule groups with unique priorities
  rule_group_arn_list = [
    {
      arn      = "arn:aws:wafv2:us-east-1:123456789012:regional/rulegroup/valid-group-1/abc123"
      name     = "valid-group-1"
      priority = 50
    },
    {
      arn      = "arn:aws:wafv2:us-east-1:123456789012:regional/rulegroup/valid-group-2/def456"
      name     = "valid-group-2"
      priority = 75
    }
  ]

  # AWS managed rules with unique priorities
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

  # Inline rules with unique priorities
  custom_inline_rules = [
    {
      name        = "BlockMaliciousIPs"
      priority    = 400
      action      = "block"
      metric_name = "block_malicious_ips"
      statement_config = {
        ip_set_reference_statement = {
          arn = "arn:aws:wafv2:us-east-1:123456789012:regional/ipset/malicious-ips/abc123"
        }
      }
    },
    {
      name        = "AllowHealthChecks"
      priority    = 500
      action      = "allow"
      metric_name = "allow_health_checks"
      statement_config = {
        byte_match_statement = {
          search_string         = "/health"
          positional_constraint = "EXACTLY"
          field_to_match = {
            uri_path = {}
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

output "valid_waf_arn" {
  description = "ARN of the valid WAF configuration"
  value       = module.waf_valid_priorities_test.web_acl_arn
}