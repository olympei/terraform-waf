provider "aws" {
  region = "us-east-1"
}

module "regex" {
  source        = "../../../modules/regex_pattern_set"
  name          = "dev-regex"
  scope         = "REGIONAL"
  regex_strings = ["(?i)drop", "(?i)malware"]
  tags = {
    Environment = "dev"
  }
}

module "ipset" {
  source     = "../../../modules/ip_set"
  name       = "dev-ipset"
  scope      = "REGIONAL"
  addresses  = ["203.0.113.0/24"]
  tags = {
    Environment = "dev"
  }
}

module "waf_rule_group" {
  source              = "../../../modules/waf_rule_group"
  rule_group_name     = "dev-waf-group"
  name                = "dev-waf-group"
  scope               = "REGIONAL"
  capacity            = 100
  metric_name         = "devMetrics"
  use_rendered_rules  = false
  tags                = {
    Environment = "dev"
  }

  custom_rules = [
    {
      name              = "RegexBlock"
      priority          = 0
      metric_name       = "regexBlock"
      type              = "regex"
      regex_pattern_set = module.regex.arn
      field_to_match    = "body"
      action            = "block"
    },
    {
      name         = "IPBlock"
      priority     = 1
      metric_name  = "ipBlock"
      type         = "ip_block"
      ip_set_arn   = module.ipset.arn
      action       = "block"
    }
  ]
}