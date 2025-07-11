variable "alb_arn_list" {
  type = list(string)
  default = []
}

variable "name" {
  default = "invalid-priority-waf"
}

variable "scope" {
  default = "REGIONAL"
}

variable "default_action" {
  default = "allow"
}

variable "tags" {
  default = {
    Environment = "test"
  }
}

module "waf_acl" {
  source         = "../../modules/waf_acl"
  name           = var.name
  scope          = var.scope
  default_action = var.default_action
  alb_arn_list   = var.alb_arn_list
  tags           = var.tags

  custom_inline_rules = [
    {
      name         = "duplicate_sqli",
      priority     = 100,
      action       = "block",
      rule_type    = "SQLI",
      statement    = "sqli_match_statement { field_to_match { body {} } text_transformations { priority = 0 type = \"NONE\" } }",
      metric_name  = "duplicate_sqli"
    }
  ]

  rule_group_arn_list = [
    {
      arn      = "arn:aws:wafv2:us-east-1:123456789012:regional/rulegroup/sample-group/abc123",
      priority = 100
    }
  ]
}