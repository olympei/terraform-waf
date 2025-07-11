# Terraform WAF Module

Reusable WAFv2 ACL and RuleGroup modules supporting dynamic rules, managed rules, and environment separation.

## Structure

- `modules/waf_acl`: Defines the Web ACL and associates rule groups + ALB
- `modules/waf_rule_group`: Creates custom rule groups, supports dynamic or rendered rules
- `examples/`: Demo configurations
- `waf_envs_multi/`: Split dev/prod environments
- `target-project/`: Shows module reuse from another project

## Usage

Refer to any example under `examples/` or environment folder for module usage.

```bash
cd examples/basic
terraform init
terraform plan
terraform apply
```


<!-- 
  dynamic "rule" {
    for_each = var.custom_rules
    content {
      name     = rule.value.name
      priority = rule.value.priority
      action {
        ${rule.value.action} {}
      }
      statement {
        ${rule.value.statement}
      }
      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = rule.value.metric_name
        sampled_requests_enabled   = true
      }
    }
  } -->