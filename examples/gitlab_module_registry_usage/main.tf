terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.3.0"
}

provider "aws" {
  region = "us-east-1"
}

module "waf" {
  source  = "terraform-aws-waf/waf/aws"
  version = "1.0.0"

  acl_name       = "example-waf"
  scope          = "REGIONAL"
  metric_name    = "example-metrics"
  tags           = { environment = "dev" }
}

module "waf_rule_group" {
  source  = "terraform-aws-waf/waf_rule_group/aws"
  version = "1.0.0"

  rule_group_name = "example-rule-group"
  scope           = "REGIONAL"
  custom_rules = [
    {
      name           = "BlockSQLi"
      priority       = 10
      metric_name    = "block_sqli"
      type           = "sqli"
      field_to_match = "body"
      action         = "block"
    }
  ]
  tags = { environment = "dev" }
}

module "regex_pattern_set" {
  source  = "terraform-aws-waf/regex_pattern_set/aws"
  version = "1.0.0"

  name     = "regex-attack-patterns"
  scope    = "REGIONAL"
  patterns = ["select", "drop", "union"]
  tags     = { environment = "dev" }
}





module "waf" {
  source  = "git::https://gitlab.com/your-namespace/your-repo.git//modules/waf?ref=v1.0.0"

  acl_name       = "my-waf"
  scope          = "REGIONAL"
  metric_name    = "waf-metrics"
  custom_rules   = var.custom_rules
  tags           = { environment = "dev" }
}

module "waf_rule_group" {
  source = "git::https://gitlab.com/your-namespace/your-repo.git//modules/waf_rule_group?ref=v1.0.0"

  rule_group_name = "my-rule-group"
  custom_rules    = var.custom_rules
  tags            = { environment = "dev" }
}

module "regex_pattern_set" {
  source = "git::https://gitlab.com/your-namespace/your-repo.git//modules/regex_pattern_set?ref=v1.0.0"

  name     = "regex-pattern"
  scope    = "REGIONAL"
  patterns = ["select", "union", "drop"]
  tags     = { environment = "dev" }
}

module "ip_set" {
  source = "git::https://gitlab.com/your-namespace/your-repo.git//modules/ip_set?ref=v1.0.0"

  name       = "block-ips"
  ip_version = "IPV4"
  addresses  = ["192.0.2.0/24", "198.51.100.0/24"]
  scope      = "REGIONAL"
  tags       = { environment = "dev" }
}
