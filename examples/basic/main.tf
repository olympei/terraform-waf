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

  # No custom inline rules for basic example
  custom_inline_rules = []

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
      inline_rules = "None (basic example)"
    }
    use_cases = [
      "Quick WAF deployment",
      "Basic web application protection",
      "AWS managed rules only",
      "Simple configuration"
    ]
  }
}