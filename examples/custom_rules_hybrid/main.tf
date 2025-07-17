provider "aws" {
  region = "us-east-1"
}

module "custom_rule_group" {
  source = "../../modules/waf_rule_group"

  rule_group_name = "custom-rule-group-hybrid"
  name           = "custom-rule-group-hybrid"
  scope          = "REGIONAL"
  capacity       = 200
  metric_name    = "CustomRuleGroupHybrid"
  tags = {
    Environment = "dev"
  }

  custom_rules = [
    # Simple type-based rule (original approach)
    {
      name           = "BlockSQLi"
      priority       = 0
      metric_name    = "SQLiRule"
      type           = "sqli"
      field_to_match = "body"
      action         = "block"
    },
    
    # Advanced statement_config rule (new approach)
    {
      name         = "BlockSQLInjection"
      priority     = 1
      metric_name  = "block_sqli"
      action       = "block"
      statement_config = {
        type                          = "sqli"
        field_to_match               = "body"
        text_transformation_priority = 0
        text_transformation_type     = "NONE"
      }
    },
    
    # Rate-based rule using statement_config
    {
      name         = "RateLimitRule"
      priority     = 2
      metric_name  = "rate_limit"
      action       = "block"
      statement_config = {
        type               = "rate_based"
        rate_limit         = 2000
        aggregate_key_type = "IP"
      }
    },
    
    # Geo-blocking rule using statement_config
    {
      name         = "GeoBlockRule"
      priority     = 3
      metric_name  = "geo_block"
      action       = "block"
      statement_config = {
        type          = "geo_match"
        country_codes = ["CN", "RU", "KP"]
      }
    },
    
    # Size constraint rule using statement_config
    {
      name         = "SizeConstraintRule"
      priority     = 4
      metric_name  = "size_constraint"
      action       = "block"
      statement_config = {
        type                = "size_constraint"
        field_to_match      = "body"
        comparison_operator = "GT"
        size               = 8192
      }
    }
  ]
}