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
  region = var.aws_region
}

# Variables for comprehensive priority validation testing
variable "aws_region" {
  description = "AWS region for deployment"
  type        = string
  default     = "us-east-1"
}

variable "alb_arn_list" {
  description = "List of ALB ARNs to associate with WAF"
  type        = list(string)
  default     = []
}

variable "name" {
  description = "Base name for WAF resources"
  type        = string
  default     = "invalid-priority-waf"
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
  description = "Default action for the WAF"
  type        = string
  default     = "allow"
  
  validation {
    condition     = contains(["allow", "block"], var.default_action)
    error_message = "Default action must be either allow or block."
  }
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default = {
    Environment = "test"
    Purpose     = "Priority Validation Testing"
    Example     = "invalid-priority"
  }
}

# ============================================================================
# USE CASE 1: DUPLICATE RULE GROUP PRIORITIES
# This demonstrates validation errors when custom rule groups have conflicting priorities
# ============================================================================

module "waf_duplicate_rule_groups" {
  source                  = "../../modules/waf"
  name                   = "${var.name}-duplicate-rule-groups"
  scope                  = var.scope
  default_action         = var.default_action
  alb_arn_list          = var.alb_arn_list
  aws_managed_rule_groups = []
  custom_inline_rules    = []
  tags                   = merge(var.tags, { UseCase = "duplicate-rule-groups" })

  # These rule groups have conflicting priorities - should trigger validation error
  rule_group_arn_list = [
    {
      arn      = "arn:aws:wafv2:us-east-1:123456789012:regional/rulegroup/security-group-1/abc123"
      name     = "security-group-1"
      priority = 100  # First rule group with priority 100
    },
    {
      arn      = "arn:aws:wafv2:us-east-1:123456789012:regional/rulegroup/security-group-2/def456"
      name     = "security-group-2"
      priority = 100  # Duplicate priority - should cause validation error
    },
    {
      arn      = "arn:aws:wafv2:us-east-1:123456789012:regional/rulegroup/rate-limit-group/ghi789"
      name     = "rate-limit-group"
      priority = 150  # Valid unique priority
    }
  ]
}

# ============================================================================
# USE CASE 2: DUPLICATE AWS MANAGED RULE PRIORITIES
# This demonstrates validation errors when AWS managed rules have conflicting priorities
# ============================================================================

module "waf_duplicate_aws_managed" {
  source                  = "../../modules/waf"
  name                   = "${var.name}-duplicate-aws-managed"
  scope                  = var.scope
  default_action         = var.default_action
  alb_arn_list          = var.alb_arn_list
  custom_inline_rules    = []
  rule_group_arn_list    = []
  tags                   = merge(var.tags, { UseCase = "duplicate-aws-managed" })

  # These AWS managed rules have conflicting priorities
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
      priority        = 200  # Duplicate priority - should cause validation error
      override_action = "none"
    },
    {
      name            = "AWSManagedRulesKnownBadInputsRuleSet"
      vendor_name     = "AWS"
      priority        = 300  # Valid unique priority
      override_action = "none"
    }
  ]
}

# ============================================================================
# USE CASE 3: MIXED PRIORITY CONFLICTS (Rule Groups + AWS Managed + Inline)
# This demonstrates complex priority conflicts across different rule types
# ============================================================================

module "waf_mixed_priority_conflicts" {
  source                  = "../../modules/waf"
  name                   = "${var.name}-mixed-conflicts"
  scope                  = var.scope
  default_action         = var.default_action
  alb_arn_list          = var.alb_arn_list
  tags                   = merge(var.tags, { UseCase = "mixed-conflicts" })

  # Custom rule groups
  rule_group_arn_list = [
    {
      arn      = "arn:aws:wafv2:us-east-1:123456789012:regional/rulegroup/custom-group-1/abc123"
      name     = "custom-group-1"
      priority = 100
    },
    {
      arn      = "arn:aws:wafv2:us-east-1:123456789012:regional/rulegroup/custom-group-2/def456"
      name     = "custom-group-2"
      priority = 200
    }
  ]

  # AWS managed rules - one conflicts with custom rule group
  aws_managed_rule_groups = [
    {
      name            = "AWSManagedRulesCommonRuleSet"
      vendor_name     = "AWS"
      priority        = 100  # Conflicts with custom-group-1 - should cause validation error
      override_action = "none"
    },
    {
      name            = "AWSManagedRulesSQLiRuleSet"
      vendor_name     = "AWS"
      priority        = 300
      override_action = "none"
    }
  ]

  # Custom inline rules - one conflicts with AWS managed rule
  custom_inline_rules = [
    {
      name        = "BlockSpecificIP"
      priority    = 300  # Conflicts with AWSManagedRulesSQLiRuleSet - should cause validation error
      action      = "block"
      metric_name = "block_specific_ip"
      statement_config = {
        ip_set_reference_statement = {
          arn = "arn:aws:wafv2:us-east-1:123456789012:regional/ipset/blocked-ips/xyz789"
        }
      }
    },
    {
      name        = "AllowHealthChecks"
      priority    = 400  # Valid unique priority
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

# ============================================================================
# USE CASE 4: MULTIPLE INLINE RULE CONFLICTS
# This demonstrates validation errors when inline rules have duplicate priorities
# ============================================================================

module "waf_inline_rule_conflicts" {
  source                  = "../../modules/waf"
  name                   = "${var.name}-inline-conflicts"
  scope                  = var.scope
  default_action         = var.default_action
  alb_arn_list          = var.alb_arn_list
  rule_group_arn_list    = []
  aws_managed_rule_groups = []
  tags                   = merge(var.tags, { UseCase = "inline-conflicts" })

  # Multiple inline rules with conflicting priorities
  custom_inline_rules = [
    {
      name        = "BlockMaliciousIPs"
      priority    = 500
      action      = "block"
      metric_name = "block_malicious_ips"
      statement_config = {
        ip_set_reference_statement = {
          arn = "arn:aws:wafv2:us-east-1:123456789012:regional/ipset/malicious-ips/abc123"
        }
      }
    },
    {
      name        = "BlockSQLInjection"
      priority    = 500  # Duplicate priority - should cause validation error
      action      = "block"
      metric_name = "block_sql_injection"
      statement_config = {
        regex_pattern_set_reference_statement = {
          arn = "arn:aws:wafv2:us-east-1:123456789012:regional/regexpatternset/sqli-patterns/def456"
          field_to_match = {
            body = {}
          }
          text_transformation = {
            priority = 0
            type     = "URL_DECODE"
          }
        }
      }
    },
    {
      name        = "RateLimitAPI"
      priority    = 500  # Another duplicate priority - should cause validation error
      action      = "block"
      metric_name = "rate_limit_api"
      statement_config = {
        rate_based_statement = {
          limit              = 2000
          aggregate_key_type = "IP"
        }
      }
    },
    {
      name        = "AllowTrustedIPs"
      priority    = 600  # Valid unique priority
      action      = "allow"
      metric_name = "allow_trusted_ips"
      statement_config = {
        ip_set_reference_statement = {
          arn = "arn:aws:wafv2:us-east-1:123456789012:regional/ipset/trusted-ips/ghi789"
        }
      }
    }
  ]
}

# ============================================================================
# USE CASE 5: EDGE CASE PRIORITY CONFLICTS
# This demonstrates edge cases and boundary conditions for priority validation
# ============================================================================

module "waf_edge_case_conflicts" {
  source                  = "../../modules/waf"
  name                   = "${var.name}-edge-cases"
  scope                  = var.scope
  default_action         = var.default_action
  alb_arn_list          = var.alb_arn_list
  tags                   = merge(var.tags, { UseCase = "edge-cases" })

  # Rule groups with edge case priorities
  rule_group_arn_list = [
    {
      arn      = "arn:aws:wafv2:us-east-1:123456789012:regional/rulegroup/edge-group-1/abc123"
      name     = "edge-group-1"
      priority = 1  # Minimum priority
    },
    {
      arn      = "arn:aws:wafv2:us-east-1:123456789012:regional/rulegroup/edge-group-2/def456"
      name     = "edge-group-2"
      priority = 1  # Duplicate minimum priority - should cause validation error
    }
  ]

  # AWS managed rules with boundary priorities
  aws_managed_rule_groups = [
    {
      name            = "AWSManagedRulesCommonRuleSet"
      vendor_name     = "AWS"
      priority        = 1  # Conflicts with edge-group-1 - should cause validation error
      override_action = "none"
    }
  ]

  # Inline rules with high priorities
  custom_inline_rules = [
    {
      name        = "HighPriorityRule"
      priority    = 999999  # Very high priority
      action      = "allow"
      metric_name = "high_priority_rule"
      statement_config = {
        byte_match_statement = {
          search_string         = "/admin"
          positional_constraint = "STARTS_WITH"
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

# ============================================================================
# USE CASE 6: VALID PRIORITY CONFIGURATION (Control Test)
# This demonstrates a correctly configured WAF with no priority conflicts
# ============================================================================

module "waf_valid_priorities" {
  source                  = "../../modules/waf"
  name                   = "${var.name}-valid-priorities"
  scope                  = var.scope
  default_action         = var.default_action
  alb_arn_list          = var.alb_arn_list
  tags                   = merge(var.tags, { UseCase = "valid-priorities" })

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
    },
    {
      name            = "AWSManagedRulesKnownBadInputsRuleSet"
      vendor_name     = "AWS"
      priority        = 300
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
    },
    {
      name        = "RateLimitAPI"
      priority    = 600
      action      = "block"
      metric_name = "rate_limit_api"
      statement_config = {
        rate_based_statement = {
          limit              = 2000
          aggregate_key_type = "IP"
        }
      }
    }
  ]
}

# ============================================================================
# USE CASE 7: SEQUENTIAL PRIORITY CONFLICTS
# This demonstrates conflicts in sequential priority assignments
# ============================================================================

module "waf_sequential_conflicts" {
  source                  = "../../modules/waf"
  name                   = "${var.name}-sequential-conflicts"
  scope                  = var.scope
  default_action         = var.default_action
  alb_arn_list          = var.alb_arn_list
  tags                   = merge(var.tags, { UseCase = "sequential-conflicts" })

  # Rule groups with sequential priorities
  rule_group_arn_list = [
    {
      arn      = "arn:aws:wafv2:us-east-1:123456789012:regional/rulegroup/seq-group-1/abc123"
      name     = "seq-group-1"
      priority = 10
    },
    {
      arn      = "arn:aws:wafv2:us-east-1:123456789012:regional/rulegroup/seq-group-2/def456"
      name     = "seq-group-2"
      priority = 20
    },
    {
      arn      = "arn:aws:wafv2:us-east-1:123456789012:regional/rulegroup/seq-group-3/ghi789"
      name     = "seq-group-3"
      priority = 30
    }
  ]

  # AWS managed rules that conflict with the sequence
  aws_managed_rule_groups = [
    {
      name            = "AWSManagedRulesCommonRuleSet"
      vendor_name     = "AWS"
      priority        = 20  # Conflicts with seq-group-2 - should cause validation error
      override_action = "none"
    },
    {
      name            = "AWSManagedRulesSQLiRuleSet"
      vendor_name     = "AWS"
      priority        = 40
      override_action = "none"
    }
  ]

  # Inline rules that extend the sequence
  custom_inline_rules = [
    {
      name        = "SequentialRule1"
      priority    = 50
      action      = "block"
      metric_name = "sequential_rule_1"
      statement_config = {
        byte_match_statement = {
          search_string         = "malicious"
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
      name        = "SequentialRule2"
      priority    = 40  # Conflicts with AWSManagedRulesSQLiRuleSet - should cause validation error
      action      = "allow"
      metric_name = "sequential_rule_2"
      statement_config = {
        byte_match_statement = {
          search_string         = "/api/health"
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

# ============================================================================
# OUTPUTS - Priority Validation Test Results
# ============================================================================

# WAF ARNs for each test case
output "waf_duplicate_rule_groups_arn" {
  description = "ARN of WAF with duplicate rule group priorities (should fail validation)"
  value       = module.waf_duplicate_rule_groups.web_acl_arn
}

output "waf_duplicate_aws_managed_arn" {
  description = "ARN of WAF with duplicate AWS managed rule priorities (should fail validation)"
  value       = module.waf_duplicate_aws_managed.web_acl_arn
}

output "waf_mixed_conflicts_arn" {
  description = "ARN of WAF with mixed priority conflicts (should fail validation)"
  value       = module.waf_mixed_priority_conflicts.web_acl_arn
}

output "waf_inline_conflicts_arn" {
  description = "ARN of WAF with inline rule conflicts (should fail validation)"
  value       = module.waf_inline_rule_conflicts.web_acl_arn
}

output "waf_edge_cases_arn" {
  description = "ARN of WAF with edge case conflicts (should fail validation)"
  value       = module.waf_edge_case_conflicts.web_acl_arn
}

output "waf_valid_priorities_arn" {
  description = "ARN of WAF with valid priorities (should pass validation)"
  value       = module.waf_valid_priorities.web_acl_arn
}

output "waf_sequential_conflicts_arn" {
  description = "ARN of WAF with sequential conflicts (should fail validation)"
  value       = module.waf_sequential_conflicts.web_acl_arn
}

# Priority validation summary
output "priority_validation_summary" {
  description = "Summary of priority validation test cases"
  value = {
    test_cases = {
      duplicate_rule_groups = {
        description = "Tests duplicate priorities in custom rule groups"
        expected_result = "VALIDATION_ERROR"
        conflicts = [
          "security-group-1 (priority 100) vs security-group-2 (priority 100)"
        ]
      }
      
      duplicate_aws_managed = {
        description = "Tests duplicate priorities in AWS managed rules"
        expected_result = "VALIDATION_ERROR"
        conflicts = [
          "AWSManagedRulesCommonRuleSet (priority 200) vs AWSManagedRulesSQLiRuleSet (priority 200)"
        ]
      }
      
      mixed_conflicts = {
        description = "Tests priority conflicts across different rule types"
        expected_result = "VALIDATION_ERROR"
        conflicts = [
          "custom-group-1 (priority 100) vs AWSManagedRulesCommonRuleSet (priority 100)",
          "AWSManagedRulesSQLiRuleSet (priority 300) vs BlockSpecificIP (priority 300)"
        ]
      }
      
      inline_conflicts = {
        description = "Tests multiple inline rule priority conflicts"
        expected_result = "VALIDATION_ERROR"
        conflicts = [
          "BlockMaliciousIPs (priority 500) vs BlockSQLInjection (priority 500)",
          "BlockSQLInjection (priority 500) vs RateLimitAPI (priority 500)"
        ]
      }
      
      edge_cases = {
        description = "Tests edge case priority conflicts"
        expected_result = "VALIDATION_ERROR"
        conflicts = [
          "edge-group-1 (priority 1) vs edge-group-2 (priority 1)",
          "edge-group-1 (priority 1) vs AWSManagedRulesCommonRuleSet (priority 1)"
        ]
      }
      
      valid_priorities = {
        description = "Tests valid priority configuration (control test)"
        expected_result = "SUCCESS"
        conflicts = []
      }
      
      sequential_conflicts = {
        description = "Tests conflicts in sequential priority assignments"
        expected_result = "VALIDATION_ERROR"
        conflicts = [
          "seq-group-2 (priority 20) vs AWSManagedRulesCommonRuleSet (priority 20)",
          "AWSManagedRulesSQLiRuleSet (priority 40) vs SequentialRule2 (priority 40)"
        ]
      }
    }
    
    validation_rules = [
      "All rule priorities must be unique across rule groups, AWS managed rules, and inline rules",
      "Priority values must be positive integers",
      "Lower priority values are evaluated first",
      "Priority conflicts will cause Terraform validation errors",
      "The WAF module includes built-in priority validation logic"
    ]
    
    testing_approach = {
      purpose = "Demonstrate comprehensive priority validation scenarios"
      method = "Multiple WAF configurations with intentional priority conflicts"
      expected_behavior = "Terraform should detect and report priority conflicts during validation"
      control_test = "waf_valid_priorities module should deploy successfully"
    }
  }
}