variable "alb_arn_list" {
  type = list(string)
  default = [
    "arn:aws:elasticloadbalancing:us-east-1:123456789012:loadbalancer/app/example-alb/50dc6c495c0c9188"
  ]
}

variable "name" {
  default = "example-waf"
}

variable "scope" {
  default = "REGIONAL"
}

variable "default_action" {
  default = "allow"
}

variable "tags" {
  default = {
    Environment = "prod"
  }
}

module "custom_rule_group" {
  source  = "../../modules/waf_rule_group"
  name    = "custom-sqli-group"
  scope   = var.scope
  rules = [
    {
      name         = "BlockSQLInjection",
      priority     = 1,
      statement    = "sqli_match_statement { field_to_match { body {} } text_transformations { priority = 0 type = \"NONE\" } }",
      action       = "block",
      metric_name  = "block_sqli"
    },
    {
      name         = "BlockXSS",
      priority     = 2,
      statement    = "xss_match_statement { field_to_match { uri_path {} } text_transformations { priority = 0 type = \"NONE\" } }",
      action       = "block",
      metric_name  = "block_xss"
    }
  ]
  tags = var.tags
}

module "waf_acl" {
  source              = "../../modules/waf_acl"
  name                = var.name
  scope               = var.scope
  default_action      = var.default_action
  rule_group_arn_list = [module.custom_rule_group.arn]
  alb_arn_list        = var.alb_arn_list
  tags                = var.tags
}