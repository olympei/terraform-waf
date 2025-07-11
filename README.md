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