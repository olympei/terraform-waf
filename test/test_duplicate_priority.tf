module "invalid_group" {
  source         = "../modules/waf_rule_group"
  rule_group_name = "fail-group"
  scope          = "REGIONAL"
  capacity       = 100
  metric_name    = "fail"
  custom_rules = [
    {
      name         = "SQLi-1"
      priority     = 10
      action       = "block"
      statement    = "sqli_match_statement { field_to_match { body {} } text_transformations { priority = 0 type = \"NONE\" } }"
      metric_name  = "sqli-1"
    },
    {
      name         = "SQLi-2"
      priority     = 10
      action       = "block"
      statement    = "sqli_match_statement { field_to_match { body {} } text_transformations { priority = 0 type = \"NONE\" } }"
      metric_name  = "sqli-2"
    }
  ]
}