module "custom_waf_group" {
  source             = "../../modules/waf_rule_group"
  rule_group_name    = "custom-group"
  scope              = "REGIONAL"
  capacity           = 100
  metric_name        = "custom_group_metric"
  use_rendered_rules = false
  custom_rules = [
    {
      name         = "BlockSQLi"
      priority     = 1
      action       = "block"
      metric_name  = "block_sql_metric"
      statement    = <<EOT
sqli_match_statement {
  field_to_match { body {} }
  text_transformations {
    priority = 0
    type     = "NONE"
  }
}
EOT
    }
  ]
  tags = {
    Environment = "rendered"
  }
}