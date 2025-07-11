provider "aws" {
  region = "us-east-1"
}

module "waf_acl" {
  source   = "../../modules/waf_acl"
  waf_name = "my-decoupled-waf"
  scope    = "REGIONAL"
}

module "sql_injection_rule_group" {
  source = "../../modules/rule_group"
  scope  = "REGIONAL"
}