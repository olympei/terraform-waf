# WAF Log Group Example

This example demonstrates the various logging configurations available with the WAF module. It shows how to set up CloudWatch logging for WAF Web ACLs with different approaches including auto-created log groups, custom log groups, existing log groups, and no logging.

## Logging Scenarios Demonstrated

### 1. Auto-Created Log Group with KMS Encryption
- **Module**: `waf_with_auto_log_group`
- **Log Group**: Auto-generated name (`/aws/wafv2/{waf-name}`)
- **KMS Key**: Auto-created for encryption
- **Retention**: Configurable (default: 90 days)
- **Use Case**: Simple setup with automatic resource creation

### 2. Custom Log Group Name
- **Module**: `waf_with_custom_log_group`
- **Log Group**: Custom name (`/aws/wafv2/custom-log-group`)
- **KMS Key**: Auto-created or user-provided
- **Retention**: Configurable (example: 30 days)
- **Use Case**: Specific naming requirements or different retention policies

### 3. Existing Log Group
- **Module**: `waf_with_existing_log_group`
- **Log Group**: Uses pre-existing CloudWatch log group
- **KMS Key**: Uses existing encryption setup
- **Retention**: Managed externally
- **Use Case**: Integration with existing logging infrastructure

### 4. No Logging
- **Module**: `waf_without_logging`
- **Log Group**: None created
- **KMS Key**: None created
- **Use Case**: WAF without logging requirements

## Resources Created

### Scenario 1: Auto-Created Log Group
```
- aws_wafv2_web_acl
- aws_cloudwatch_log_group (auto-named)
- aws_kms_key (for encryption)
- aws_wafv2_web_acl_logging_configuration
- null_resource (priority validation)
```

### Scenario 2: Custom Log Group
```
- aws_wafv2_web_acl
- aws_cloudwatch_log_group (custom name)
- aws_kms_key (for encryption)
- aws_wafv2_web_acl_logging_configuration
- null_resource (priority validation)
```

### Scenario 3: Existing Log Group
```
- aws_wafv2_web_acl
- null_resource (priority validation)
```

### Scenario 4: No Logging
```
- aws_wafv2_web_acl
- null_resource (priority validation)
```

## Configuration Options

### Variables

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `name` | string | `"log-group-example-waf"` | Base name for WAF resources |
| `scope` | string | `"REGIONAL"` | WAF scope (REGIONAL or CLOUDFRONT) |
| `default_action` | string | `"allow"` | Default WAF action (allow or block) |
| `create_log_group` | bool | `true` | Whether to create CloudWatch log group |
| `log_group_name` | string | `null` | Custom log group name (optional) |
| `existing_log_group_arn` | string | `null` | ARN of existing log group |
| `log_group_retention_in_days` | number | `90` | Log retention period in days |
| `kms_key_id` | string | `null` | KMS key for encryption (optional) |
| `tags` | map(string) | `{}` | Tags to apply to resources |

### Log Group Configuration Patterns

#### Auto-Created Log Group
```hcl
create_log_group           = true
log_group_name             = null  # Auto-generates name
log_group_retention_in_days = 90
kms_key_id                 = null  # Auto-creates KMS key
```

#### Custom Named Log Group
```hcl
create_log_group           = true
log_group_name             = "/aws/wafv2/my-custom-log-group"
log_group_retention_in_days = 30
kms_key_id                 = "arn:aws:kms:us-east-1:123456789012:key/abc123"
```

#### Existing Log Group
```hcl
create_log_group           = false
existing_log_group_arn     = "arn:aws:logs:us-east-1:123456789012:log-group:/aws/wafv2/existing-group"
```

#### No Logging
```hcl
create_log_group           = false
existing_log_group_arn     = null
```

## Usage

### 1. Default Configuration
```bash
terraform init
terraform plan
terraform apply
```

### 2. Using tfvars.json Files

#### Auto-Created Log Group
```bash
terraform plan -var-file="auto-log-group.tfvars.json"
terraform apply -var-file="auto-log-group.tfvars.json"
```

#### Existing Log Group
```bash
terraform plan -var-file="existing-log-group.tfvars.json"
terraform apply -var-file="existing-log-group.tfvars.json"
```

### 3. Custom Variables
```bash
terraform plan -var="name=my-waf" -var="log_group_retention_in_days=60"
terraform apply -var="name=my-waf" -var="log_group_retention_in_days=60"
```

## Configuration Files

### auto-log-group.tfvars.json
```json
{
  "name": "example-waf",
  "scope": "REGIONAL",
  "default_action": "allow",
  "create_log_group": true,
  "log_group_retention_in_days": 90,
  "tags": {
    "Environment": "dev",
    "Purpose": "Auto Log Group Demo"
  }
}
```

### existing-log-group.tfvars.json
```json
{
  "name": "example-waf",
  "scope": "REGIONAL",
  "default_action": "allow",
  "create_log_group": false,
  "existing_log_group_arn": "arn:aws:logs:us-east-1:123456789012:log-group:/aws/wafv2/my-existing-log-group",
  "kms_key_id": "arn:aws:kms:us-east-1:123456789012:key/abc12345-d678-90ef-gh12-ijkl345678mn",
  "tags": {
    "Environment": "prod",
    "Purpose": "Existing Log Group Demo"
  }
}
```

## Outputs

The example provides four outputs for the different WAF configurations:

- `waf_auto_log_group_arn`: WAF with auto-created log group
- `waf_custom_log_group_arn`: WAF with custom log group name
- `waf_existing_log_group_arn`: WAF using existing log group
- `waf_no_logging_arn`: WAF without logging

## Log Group Naming Convention

### Auto-Generated Names
- Pattern: `/aws/wafv2/{waf-name}`
- Example: `/aws/wafv2/log-group-example-waf-auto`

### Custom Names
- Pattern: User-defined
- Example: `/aws/wafv2/custom-log-group`
- Recommendation: Follow AWS CloudWatch naming conventions

## KMS Encryption

### Auto-Created KMS Keys
- **Description**: "KMS key for encrypting WAF logs"
- **Key Rotation**: Enabled
- **Key Usage**: ENCRYPT_DECRYPT
- **Tags**: Inherited from WAF configuration

### User-Provided KMS Keys
- Specify existing KMS key ARN in `kms_key_id` variable
- Ensure key policy allows CloudWatch Logs service access

## Cost Considerations

### CloudWatch Logs Costs
- **Ingestion**: $0.50 per GB ingested
- **Storage**: $0.03 per GB per month
- **Data Transfer**: Standard AWS data transfer rates

### KMS Costs
- **Key Usage**: $0.03 per 10,000 requests
- **Key Storage**: $1.00 per key per month

### Optimization Tips
1. **Retention Periods**: Use appropriate retention (7, 30, 90 days)
2. **Log Filtering**: Filter unnecessary log entries
3. **Regional Deployment**: Deploy only in required regions
4. **Monitoring**: Use CloudWatch metrics to monitor costs

## Monitoring and Alerting

### CloudWatch Metrics
Each WAF creates the following metrics:
- `AllowedRequests`: Requests allowed by WAF
- `BlockedRequests`: Requests blocked by WAF
- `CountedRequests`: Requests counted by rules
- `PassedRequests`: Requests passed to origin

### Log Analysis
WAF logs contain detailed information:
- **Timestamp**: When request was processed
- **Action**: Action taken (ALLOW, BLOCK, COUNT)
- **Rule**: Which rule matched
- **Request Details**: Headers, URI, method, etc.

### Sample Log Entry
```json
{
  "timestamp": 1545677810729,
  "formatVersion": 1,
  "webaclId": "arn:aws:wafv2:us-east-1:123456789012:regional/webacl/ExampleWebACL/473e64fd-f30b-4765-81a0-62ad96dd167a",
  "terminatingRuleId": "DefaultAction",
  "terminatingRuleType": "REGULAR",
  "action": "ALLOW",
  "httpSourceName": "ALB",
  "httpSourceId": "123456789012-app/my-loadbalancer/50dc6c495c0c9188",
  "ruleGroupList": [],
  "rateBasedRuleList": [],
  "nonTerminatingMatchingRules": [],
  "httpRequest": {
    "clientIp": "192.0.2.44",
    "country": "US",
    "headers": [
      {
        "name": "Host",
        "value": "localhost:1989"
      }
    ],
    "uri": "/",
    "args": "",
    "httpVersion": "HTTP/1.1",
    "httpMethod": "GET",
    "requestId": "rid"
  }
}
```

## Security Best Practices

### Log Group Security
1. **Encryption**: Always use KMS encryption for sensitive logs
2. **Access Control**: Restrict CloudWatch Logs access with IAM
3. **Retention**: Set appropriate retention periods
4. **Monitoring**: Monitor log access and modifications

### KMS Key Security
1. **Key Policies**: Restrict key usage to necessary services
2. **Key Rotation**: Enable automatic key rotation
3. **Access Logging**: Enable CloudTrail for key usage monitoring
4. **Cross-Account**: Carefully manage cross-account key access

## Troubleshooting

### Common Issues

#### Log Group Creation Fails
- **Cause**: Insufficient IAM permissions
- **Solution**: Ensure CloudWatch Logs permissions in IAM policy

#### KMS Encryption Fails
- **Cause**: Invalid KMS key or insufficient permissions
- **Solution**: Verify KMS key exists and has proper policy

#### Logging Configuration Fails
- **Cause**: WAF and log group in different regions
- **Solution**: Ensure WAF and log group are in same region

#### High Costs
- **Cause**: High log volume or long retention
- **Solution**: Optimize retention periods and implement log filtering

### Debugging Steps
1. **Check IAM Permissions**: Verify CloudWatch and KMS permissions
2. **Validate Resources**: Ensure all resources exist and are accessible
3. **Review Logs**: Check CloudTrail for API errors
4. **Test Connectivity**: Verify network connectivity between services

This example provides a comprehensive foundation for implementing WAF logging in various scenarios, from simple auto-created setups to complex existing infrastructure integrations.