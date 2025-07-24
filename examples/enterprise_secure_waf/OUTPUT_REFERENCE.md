# Enterprise Secure WAF - Output Reference

This document describes all the outputs available from the Enterprise Secure WAF configuration.

## CloudWatch Log Group Outputs

### `waf_log_group_name`
- **Description**: Name of the WAF CloudWatch log group (created or existing)
- **Value**: Returns the log group name regardless of whether it was created by this module or provided as existing
- **Example**: `/aws/wafv2/enterprise-secure-waf` or `my-existing-log-group`

### `waf_log_group_arn`
- **Description**: ARN of the WAF CloudWatch log group (created or existing)
- **Value**: Returns the full ARN of the log group
- **Example**: `arn:aws:logs:us-east-1:123456789012:log-group:/aws/wafv2/enterprise-secure-waf`

## KMS Key Outputs

### `waf_kms_key_id`
- **Description**: ID of the KMS key used for WAF log encryption (provided or created)
- **Value**: Returns the KMS key ID when encryption is enabled
- **Example**: `12345678-1234-1234-1234-123456789012` or `alias/my-waf-key`

### `waf_kms_key_arn`
- **Description**: ARN of the KMS key used for WAF log encryption (provided or created)
- **Value**: Returns the full ARN of the KMS key
- **Example**: `arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012`

## Configuration Summary Output

### `waf_logging_configuration_summary`
- **Description**: Comprehensive summary of WAF logging configuration
- **Value**: Object containing all logging configuration details

```hcl
{
  logging_enabled     = true/false
  log_group_created   = true/false  # Whether module created the log group
  existing_log_group  = true/false  # Whether using existing log group
  log_group_name      = "log-group-name"
  log_group_arn       = "arn:aws:logs:..."
  kms_encryption      = true/false
  kms_key_provided    = true/false  # Whether KMS key was provided
  kms_key_created     = true/false  # Whether module created KMS key
  kms_key_id          = "key-id"
  kms_key_arn         = "arn:aws:kms:..."
  retention_days      = 90
}
```

## WAF Resource Outputs

### `enterprise_waf_arn`
- **Description**: ARN of the enterprise WAF ACL
- **Example**: `arn:aws:wafv2:us-east-1:123456789012:regional/webacl/enterprise-secure-waf/12345678-1234-1234-1234-123456789012`

### `enterprise_waf_id`
- **Description**: ID of the enterprise WAF ACL
- **Example**: `12345678-1234-1234-1234-123456789012`

### `security_rule_group_arn`
- **Description**: ARN of the enterprise security rule group
- **Example**: `arn:aws:wafv2:us-east-1:123456789012:regional/rulegroup/enterprise-secure-waf-enterprise-security/12345678-1234-1234-1234-123456789012`

### `rate_limiting_rule_group_arn`
- **Description**: ARN of the rate limiting rule group
- **Example**: `arn:aws:wafv2:us-east-1:123456789012:regional/rulegroup/enterprise-secure-waf-rate-limiting/12345678-1234-1234-1234-123456789012`

## Usage Scenarios

### Scenario 1: Create New Log Group and KMS Key
```hcl
# Variables
enable_logging = true
create_log_group = true
enable_kms_encryption = true
kms_key_id = null  # Will create new KMS key

# Expected Outputs
waf_log_group_name = "/aws/wafv2/enterprise-secure-waf"
waf_log_group_arn = "arn:aws:logs:us-east-1:123456789012:log-group:/aws/wafv2/enterprise-secure-waf"
waf_kms_key_id = "12345678-1234-1234-1234-123456789012"  # Created by module
waf_kms_key_arn = "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"
```

### Scenario 2: Use Existing Log Group and KMS Key
```hcl
# Variables
enable_logging = true
create_log_group = false
existing_log_group_arn = "arn:aws:logs:us-east-1:123456789012:log-group:my-existing-waf-logs"
enable_kms_encryption = true
kms_key_id = "arn:aws:kms:us-east-1:123456789012:key/existing-key-id"

# Expected Outputs
waf_log_group_name = "my-existing-waf-logs"  # Extracted from ARN
waf_log_group_arn = "arn:aws:logs:us-east-1:123456789012:log-group:my-existing-waf-logs"
waf_kms_key_id = "arn:aws:kms:us-east-1:123456789012:key/existing-key-id"  # Provided
waf_kms_key_arn = "arn:aws:kms:us-east-1:123456789012:key/existing-key-id"
```

### Scenario 3: Logging Disabled
```hcl
# Variables
enable_logging = false

# Expected Outputs
waf_log_group_name = null
waf_log_group_arn = null
waf_kms_key_id = null
waf_kms_key_arn = null
```

## Accessing Outputs

After running `terraform apply`, you can access these outputs using:

```bash
# Get specific output
terraform output waf_log_group_name
terraform output waf_log_group_arn
terraform output waf_kms_key_id
terraform output waf_kms_key_arn

# Get all outputs
terraform output

# Get output in JSON format
terraform output -json waf_logging_configuration_summary
```

## Integration with Other Resources

These outputs can be used to integrate with other AWS resources:

```hcl
# Use WAF log group in CloudWatch alarms
resource "aws_cloudwatch_metric_alarm" "waf_blocked_requests" {
  alarm_name          = "waf-blocked-requests-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "BlockedRequests"
  namespace           = "AWS/WAFV2"
  period              = "300"
  statistic           = "Sum"
  threshold           = "100"
  alarm_description   = "This metric monitors WAF blocked requests"

  dimensions = {
    WebACL = module.enterprise_waf.web_acl_id
  }
}

# Use log group ARN in other logging configurations
resource "aws_kinesis_firehose_delivery_stream" "waf_logs" {
  name        = "waf-logs-stream"
  destination = "s3"

  cloudwatch_logging_options {
    enabled         = true
    log_group_name  = module.enterprise_secure_waf.waf_log_group_name
    log_stream_name = "waf-firehose"
  }
}
```