terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

module "waf" {
  source  = "terraform-aws-waf/waf/local"
  version = "1.0.0"

  acl_name     = "example-waf"
  scope        = "REGIONAL"
  metric_name  = "example-metric"
  description  = "Managed by GitLab module"

  tags = {
    env = "dev"
  }
}

module "waf_rule_group" {
  source  = "terraform-aws-waf/waf_rule_group/local"
  version = "1.0.0"

  rule_group_name = "example-group"
  scope           = "REGIONAL"
  capacity        = 50

  custom_rules = [
    {
      name            = "BlockSQLi"
      priority        = 0
      metric_name     = "SQLiBlock"
      type            = "sqli"
      field_to_match  = "body"
      action          = "block"
    }
  ]
}

module "regex_pattern_set" {
  source  = "terraform-aws-waf/regex_pattern_set/local"
  version = "1.0.0"

  name   = "email-regex"
  scope  = "REGIONAL"
  regex_strings = ["[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+"]
}

module "ip_set" {
  source  = "terraform-aws-waf/ip_set/local"
  version = "1.0.0"

  name     = "block-ips"
  scope    = "REGIONAL"
  ip_addresses = ["203.0.113.0/24", "192.0.2.0/24"]
}