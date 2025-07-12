acl_name     = "my-web-acl"
scope        = "REGIONAL"
metric_name  = "web-acl-metrics"
description  = "Web ACL with custom rules"

tags = {
  Project = "my-app"
}

aws_managed_rule_groups = [
  {
    name         = "AWSManagedRulesCommonRuleSet"
    vendor_name  = "AWS"
    priority     = 100
  }
]