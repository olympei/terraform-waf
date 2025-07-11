# Example: Hybrid Custom Rules

This example demonstrates how to use both:
- High-level `type`-based WAF rule definition
- Raw `statement`-based WAF rule definition

## Usage

```bash
cd examples/custom_rules_hybrid
terraform init
terraform plan
```

## Expected Behavior

Terraform should render both types of rules into the WAF rule group correctly.