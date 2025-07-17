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

# Variables for demonstration
variable "custom_rules" {
  description = "Custom rules for WAF rule group"
  type = list(object({
    name           = string
    priority       = number
    metric_name    = string
    type           = string
    field_to_match = string
    action         = string
  }))
  default = [
    {
      name           = "BlockSQLi"
      priority       = 10
      metric_name    = "block_sqli"
      type           = "sqli"
      field_to_match = "body"
      action         = "block"
    },
    {
      name           = "BlockXSS"
      priority       = 20
      metric_name    = "block_xss"
      type           = "xss"
      field_to_match = "uri_path"
      action         = "block"
    }
  ]
}

# Example using GitLab module registry (hypothetical)
# In a real scenario, these would be published to a GitLab module registry

# WAF Module
module "waf" {
  # In real usage, this would be from GitLab module registry:
  # source = "git::https://gitlab.com/your-namespace/terraform-waf-modules.git//modules/waf?ref=v1.0.0"
  
  # For this example, using local modules
  source = "../../modules/waf"

  name                    = "gitlab-registry-waf"
  scope                   = "REGIONAL"
  default_action          = "allow"
  aws_managed_rule_groups = []
  rule_group_arn_list     = [
    {
      arn      = module.waf_rule_group.waf_rule_group_arn
      name     = "custom-rule-group"
      priority = 100
    }
  ]
  custom_inline_rules = []
  alb_arn_list       = []
  
  tags = {
    Environment = "dev"
    Source      = "GitLab Module Registry"
  }
}

# WAF Rule Group Module
module "waf_rule_group" {
  # In real usage, this would be from GitLab module registry:
  # source = "git::https://gitlab.com/your-namespace/terraform-waf-modules.git//modules/waf_rule_group?ref=v1.0.0"
  
  # For this example, using local modules
  source = "../../modules/waf_rule_group"

  rule_group_name = "gitlab-registry-rule-group"
  name           = "gitlab-registry-rule-group"
  scope          = "REGIONAL"
  capacity       = 100
  metric_name    = "GitLabRuleGroup"
  custom_rules   = var.custom_rules
  
  tags = {
    Environment = "dev"
    Source      = "GitLab Module Registry"
  }
}

# Regex Pattern Set Module
module "regex_pattern_set" {
  # In real usage, this would be from GitLab module registry:
  # source = "git::https://gitlab.com/your-namespace/terraform-waf-modules.git//modules/regex_pattern_set?ref=v1.0.0"
  
  # For this example, using local modules
  source = "../../modules/regex_pattern_set"

  name          = "gitlab-regex-patterns"
  scope         = "REGIONAL"
  regex_strings = ["(?i)select.*from", "(?i)union.*select", "(?i)drop.*table"]
  
  tags = {
    Environment = "dev"
    Source      = "GitLab Module Registry"
  }
}

# IP Set Module
module "ip_set" {
  # In real usage, this would be from GitLab module registry:
  # source = "git::https://gitlab.com/your-namespace/terraform-waf-modules.git//modules/ip_set?ref=v1.0.0"
  
  # For this example, using local modules
  source = "../../modules/ip_set"

  name                = "gitlab-blocked-ips"
  scope               = "REGIONAL"
  ip_address_version  = "IPV4"
  addresses           = ["192.0.2.0/24", "198.51.100.0/24", "203.0.113.0/24"]
  
  tags = {
    Environment = "dev"
    Source      = "GitLab Module Registry"
  }
}

# Outputs
output "waf_arn" {
  description = "ARN of the WAF Web ACL"
  value       = module.waf.web_acl_arn
}

output "waf_rule_group_arn" {
  description = "ARN of the WAF Rule Group"
  value       = module.waf_rule_group.waf_rule_group_arn
}

output "regex_pattern_set_arn" {
  description = "ARN of the Regex Pattern Set"
  value       = module.regex_pattern_set.arn
}

output "ip_set_arn" {
  description = "ARN of the IP Set"
  value       = module.ip_set.arn
}