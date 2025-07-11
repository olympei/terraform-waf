module "custom_rule_group" {
  source = "../../modules/waf_rule_group"

  name        = "custom-rule-group-hybrid"
  scope       = "REGIONAL"
  description = "Hybrid definition rule group"
  tags = {
    Environment = "dev"
  }

  custom_rules = [
    {
      name         = "BlockSQLi"
      priority     = 0
      metric_name  = "SQLiRule"
      type         = "sqli"
      field_to_match = "body"
      action       = "block"
    },
    {
      name         = "BlockSQLInjection"
      priority     = 1
      statement    = "sqli_match_statement { field_to_match { body {} } text_transformations { priority = 0 type = \"NONE\" } }"
      action       = "block"
      metric_name  = "block_sqli"
    }
  ]
}