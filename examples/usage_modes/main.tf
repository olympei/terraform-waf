module "waf_rule_group_template" {
  source = "../../modules/waf_rule_group"

  name     = "template-rule-group"
  scope    = "REGIONAL"
  tags     = { Environment = "dev" }

  use_templatefile_rendering = true

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
      name         = "AllowRegexPath"
      priority     = 1
      metric_name  = "AllowRegex"
      type         = "regex"
      field_to_match = "uri_path"
      regex_pattern_set = "arn:aws:wafv2:us-east-1:123456789012:regional/regexset/myset"
      action       = "allow"
    }
  ]
}

module "waf_rule_group_raw" {
  source = "../../modules/waf_rule_group"

  name     = "manual-statement-group"
  scope    = "REGIONAL"
  tags     = { Environment = "dev" }

  use_templatefile_rendering = false

  custom_rules = [
    {
      name         = "BlockSQLInjection"
      priority     = 0
      metric_name  = "ManualSQLi"
      statement    = <<EOT
sqli_match_statement {
  field_to_match {
    body {}
  }
  text_transformations {
    priority = 0
    type     = "NONE"
  }
}
EOT
      action = "block"
    }
  ]
}