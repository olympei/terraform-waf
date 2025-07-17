provider "aws" {
  region = "us-east-1"
}

module "waf_acl" {
  source        = "../../modules/waf"
  name          = "my-decoupled-waf"
  scope         = "REGIONAL"
  default_action = "allow"
  rule_group_arn_list = []
  alb_arn_list   = []
  aws_managed_rule_groups = []
}

module "sql_injection_rule_group" {
  source = "../../modules/rule_group"
  scope  = "REGIONAL"
}