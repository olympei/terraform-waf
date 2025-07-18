provider "aws" {
  region = "us-east-1"
}

# Variables for configuration
variable "rule_group_name" {
  description = "Name of the WAF rule group"
  type        = string
  default     = "rendered-rules-group"
}

variable "use_templatefile_rendering" {
  description = "Whether to use templatefile rendering for rules"
  type        = bool
  default     = false
}

variable "custom_rules" {
  description = "Custom rules for the WAF rule group"
  type = list(object({
    name        = string
    priority    = number
    action      = string
    metric_name = string
    type        = optional(string)
    field_to_match = optional(string, "body")
  }))
  default = [
    {
      name        = "BlockSQLi"
      priority    = 1
      action      = "block"
      metric_name = "block_sql_metric"
      type        = "sqli"
      field_to_match = "body"
    },
    {
      name        = "BlockXSS"
      priority    = 2
      action      = "block"
      metric_name = "block_xss_metric"
      type        = "xss"
      field_to_match = "uri_path"
    }
  ]
}

# Example 1: Standard rule group with type-based rules
module "standard_waf_group" {
  source = "../../modules/waf-rule-group"

  rule_group_name = "${var.rule_group_name}-standard"
  name           = "${var.rule_group_name}-standard"
  scope          = "REGIONAL"
  capacity       = 100
  metric_name    = "standard_group_metric"
  custom_rules   = var.custom_rules
  
  tags = {
    Environment = "rendered"
    Type        = "Standard"
  }
}

# Example 2: Template-rendered rule group
module "template_waf_group" {
  source = "../../modules/waf-rule-group"

  rule_group_name           = "${var.rule_group_name}-template"
  name                     = "${var.rule_group_name}-template"
  scope                    = "REGIONAL"
  capacity                 = 100
  metric_name              = "template_group_metric"
  use_templatefile_rendering = true
  custom_rules             = var.custom_rules
  
  tags = {
    Environment = "rendered"
    Type        = "Template"
  }
}

# Example 3: Advanced rules with statement_config
module "advanced_waf_group" {
  source = "../../modules/waf-rule-group"

  rule_group_name = "${var.rule_group_name}-advanced"
  name           = "${var.rule_group_name}-advanced"
  scope          = "REGIONAL"
  capacity       = 150
  metric_name    = "advanced_group_metric"
  
  custom_rules = [
    {
      name         = "AdvancedSQLi"
      priority     = 1
      action       = "block"
      metric_name  = "advanced_sqli"
      statement_config = {
        type                          = "sqli"
        field_to_match               = "body"
        text_transformation_priority = 0
        text_transformation_type     = "NONE"
      }
    },
    {
      name         = "RateLimit"
      priority     = 2
      action       = "block"
      metric_name  = "rate_limit"
      statement_config = {
        type               = "rate_based"
        rate_limit         = 2000
        aggregate_key_type = "IP"
      }
    }
  ]
  
  tags = {
    Environment = "rendered"
    Type        = "Advanced"
  }
}
# Outputs
output "standard_waf_group_arn" {
  description = "ARN of the standard WAF rule group"
  value       = module.standard_waf_group.waf_rule_group_arn
}

output "template_waf_group_arn" {
  description = "ARN of the template-rendered WAF rule group"
  value       = module.template_waf_group.waf_rule_group_arn
}

output "advanced_waf_group_arn" {
  description = "ARN of the advanced WAF rule group"
  value       = module.advanced_waf_group.waf_rule_group_arn
}