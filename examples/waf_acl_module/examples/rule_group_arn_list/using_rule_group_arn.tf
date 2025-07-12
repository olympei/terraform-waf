# Example: terraform.tfvars.json - Using rule group ARNs and calling waf_acl module
```json
{
  "name": "example-waf",
  "scope": "REGIONAL",
  "default_action": "allow",
  "rule_group_arn_list": [
    "arn:aws:wafv2:us-east-1:123456789012:regional/rulegroup/sql-injection-group/abcd1234-efgh-5678-ijkl-9876mnopqrst",
    "arn:aws:wafv2:us-east-1:123456789012:regional/rulegroup/ip-block-group/abcd5678-efgh-1234-ijkl-9876mnopqrst"
  ],
  "alb_arn_list": [
    "arn:aws:elasticloadbalancing:us-east-1:123456789012:loadbalancer/app/example-alb/50dc6c495c0c9188"
  ],
  "tags": {
    "Environment": "prod"
  }
}
```

# Example module call (main.tf)
```hcl
module "waf_acl" {
  source                = "../modules/waf_acl"
  name                  = var.name
  scope                 = var.scope
  default_action        = var.default_action
  rule_group_arn_list   = var.rule_group_arn_list
  alb_arn_list          = var.alb_arn_list
  tags                  = var.tags
}
```
