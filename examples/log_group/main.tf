# Example: terraform.tfvars.json - Using auto-created log group and KMS key
```json
{
  "name": "example-waf",
  "scope": "REGIONAL",
  "default_action": "allow",
  "create_log_group": true,
  "log_group_retention_in_days": 90,
  "tags": {
    "Environment": "dev"
  }
}
```

---

# Example: terraform.tfvars.json - Using existing log group and provided KMS key
```json
{
  "name": "example-waf",
  "scope": "REGIONAL",
  "default_action": "allow",
  "create_log_group": false,
  "existing_log_group_arn": "arn:aws:logs:us-east-1:123456789012:log-group:/aws/wafv2/my-existing-log-group",
  "kms_key_id": "arn:aws:kms:us-east-1:123456789012:key/abc12345-d678-90ef-gh12-ijkl345678mn",
  "tags": {
    "Environment": "prod"
  }
}
``