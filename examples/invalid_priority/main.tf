provider "aws" {
  region = "us-east-1"
}

variable "alb_arn_list" {
  type    = list(string)
  default = []
}

variable "name" {
  default = "invalid-priority-waf"
}

variable "scope" {
  default = "REGIONAL"
}

variable "default_action" {
  default = "allow"
}

variable "tags" {
  default = {
    Environment = "test"
  }
}

# This example demonstrates priority validation
# It should show validation errors when priorities conflict
module "waf_acl" {
  source                  = "../../modules/waf"
  name                   = var.name
  scope                  = var.scope
  default_action         = var.default_action
  alb_arn_list          = var.alb_arn_list
  aws_managed_rule_groups = []
  custom_inline_rules    = []  # Simplified - no custom inline rules for this test
  tags                   = var.tags

  # These rule groups have conflicting priorities - should trigger validation error
  rule_group_arn_list = [
    {
      arn      = "arn:aws:wafv2:us-east-1:123456789012:regional/rulegroup/sample-group-1/abc123"
      name     = "sample-group-1"
      priority = 100  # First rule group with priority 100
    },
    {
      arn      = "arn:aws:wafv2:us-east-1:123456789012:regional/rulegroup/sample-group-2/def456"
      name     = "sample-group-2"
      priority = 100  # Duplicate priority - should cause validation error
    }
  ]
}

# Alternative example with AWS managed rules having duplicate priorities
module "waf_acl_aws_managed" {
  source                  = "../../modules/waf"
  name                   = "${var.name}-aws-managed"
  scope                  = var.scope
  default_action         = var.default_action
  alb_arn_list          = var.alb_arn_list
  custom_inline_rules    = []
  rule_group_arn_list    = []
  tags                   = var.tags

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
    }
  ]
}