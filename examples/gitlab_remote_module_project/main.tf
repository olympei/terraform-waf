module "my_custom_waf_group" {
  source  = "git::ssh://git@gitlab.com/yourgroup/infrastructure/terraform-waf.git//modules/waf_rule_group?ref=main"

  rule_group_name = "my-custom-waf-group"
  metric_name     = "custom-group-metrics"
  scope           = "REGIONAL"
  capacity        = 50
  tags = {
    Environment = "dev"
    Owner       = "platform"
  }

  custom_rules = [
    {
      name           = "BlockSQLi"
      priority       = 10
      metric_name    = "sqli_rule"
      type           = "sqli"
      field_to_match = "body"
      action         = "block"
    },
    {
      name           = "AllowSafeIP"
      priority       = 20
      metric_name    = "safe_ip"
      type           = "ip_block"
      ip_set_arn     = "arn:aws:wafv2:region:account-id:ipset/safe-ip-set"
      action         = "allow"
    }
  ]
}

module "waf_acl" {
  source = "git::ssh://git@gitlab.com/yourgroup/infrastructure/terraform-waf.git//modules/waf?ref=main"

  acl_name     = "my-web-acl"
  scope        = "REGIONAL"
  metric_name  = "web-acl-metrics"
  description  = "Web ACL with custom rules"
  tags = {
    Project = "my-app"
  }

  rule_group_arn_list = [
    module.my_custom_waf_group.arn
  ]

  aws_managed_rule_groups = [
    {
      name         = "AWSManagedRulesCommonRuleSet"
      vendor_name  = "AWS"
      priority     = 100
    }
  ]
}