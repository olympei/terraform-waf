provider "aws" {
  region = "us-east-1"
}

module "regex" {
  source        = "../../modules/regex-pattern-set"
  name          = "bad-input-regex"
  scope         = "REGIONAL"
  regex_strings = ["(?i)malicious", "(?i)drop table"]
  tags = {
    Environment = "dev"
  }
}

module "ipset" {
  source     = "../../modules/ip-set"
  name       = "blocked-ips"
  scope      = "REGIONAL"
  addresses  = ["203.0.113.0/24", "192.0.2.0/24"]
  tags = {
    Environment = "dev"
  }
}

module "waf_rule_group" {
  source              = "../../modules/waf-rule-group"
  rule_group_name     = "dev-rules"
  name                = "dev-rules"
  scope               = "REGIONAL"
  capacity            = 100
  metric_name         = "devWAFGroup"
  use_rendered_rules  = false
  tags                = {
    Environment = "dev"
  }

  custom_rules = [
    {
      name              = "RegexBlock"
      priority          = 1
      metric_name       = "regex_block"
      type              = "regex"
      field_to_match    = "body"
      regex_pattern_set = module.regex.arn
      action            = "block"
    },
    {
      name         = "BlockIPs"
      priority     = 2
      metric_name  = "ip_block"
      type         = "ip_block"
      ip_set_arn   = module.ipset.arn
      action       = "block"
    }
  ]
}
