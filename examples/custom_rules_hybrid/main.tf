provider "aws" {
  region = "us-east-1"
}

module "custom_rule_group" {
  source = "../../modules/waf_rule_group"

  rule_group_name = "custom-rule-group-hybrid"
  name           = "custom-rule-group-hybrid"
  scope          = "REGIONAL"
  capacity       = 100
  metric_name    = "CustomRuleGroupHybrid"
  tags = {
    Environment = "dev"
  }

  custom_rules = [
    {
      name           = "BlockSQLi"
      priority       = 0
      metric_name    = "SQLiRule"
      type           = "sqli"
      field_to_match = "body"
      action         = "block"
    },
    {
      name           = "BlockXSS"
      priority       = 1
      metric_name    = "XSSRule"
      type           = "xss"
      field_to_match = "uri_path"
      action         = "block"
    }
  ]
}