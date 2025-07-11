# Test Case: Invalid Rule Priority Conflict

This test is expected to fail due to duplicate `priority = 100` in both an inline rule and a rule group.

## Reproduce

```bash
cd examples/invalid_priority
terraform init
terraform plan
```

## Expected Error

```
Error: Duplicate priorities detected across inline and rule group rules. All WAF rule priorities must be unique.
```