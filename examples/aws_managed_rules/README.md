# AWS Managed Rules Example

This example demonstrates how to use the WAF module with AWS Managed Rule Groups. AWS Managed Rules are pre-configured rule sets maintained by AWS that protect against common web exploits and vulnerabilities.

## Features Demonstrated

### AWS Managed Rule Groups Included

1. **AWSManagedRulesCommonRuleSet** (Priority 100)
   - Provides protection against OWASP Top 10 security risks
   - Override Action: `none` (blocks matching requests)
   - Covers common attack patterns and vulnerabilities

2. **AWSManagedRulesAmazonIpReputationList** (Priority 101)
   - Blocks requests from IP addresses with poor reputation
   - Override Action: `count` (logs but doesn't block - for monitoring)
   - Based on Amazon's threat intelligence

3. **AWSManagedRulesSQLiRuleSet** (Priority 102)
   - Specialized protection against SQL injection attacks
   - Override Action: `none` (blocks matching requests)
   - Advanced SQL injection detection patterns

## Configuration Files

### main.tf
Contains the main WAF module configuration with AWS managed rule groups.

### aws_managed.tfvars.json
JSON file containing the AWS managed rule group definitions:
```json
{
  "aws_managed_rule_groups": [
    {
      "name": "AWSManagedRulesCommonRuleSet",
      "vendor_name": "AWS",
      "priority": 100,
      "override_action": "none"
    },
    {
      "name": "AWSManagedRulesAmazonIpReputationList",
      "vendor_name": "AWS",
      "priority": 101,
      "override_action": "count"
    },
    {
      "name": "AWSManagedRulesSQLiRuleSet",
      "vendor_name": "AWS",
      "priority": 102,
      "override_action": "none"
    }
  ]
}
```

## Override Actions

- **none**: The rule group's actions are applied (blocks/allows as configured)
- **count**: Only counts matches without blocking (useful for monitoring)

## Usage

### Deploy with tfvars file:
```bash
terraform init
terraform plan -var-file="aws_managed.tfvars.json"
terraform apply -var-file="aws_managed.tfvars.json"
```

### Deploy with inline variables:
```bash
terraform init
terraform plan
terraform apply
```

## Resources Created

- 1 WAF Web ACL with 3 AWS Managed Rule Groups
- CloudWatch metrics for each rule group
- Proper priority management (100, 101, 102)
- Production-ready configuration with tags

## Available AWS Managed Rule Groups

Common AWS Managed Rule Groups you can use:

- `AWSManagedRulesCommonRuleSet` - OWASP Top 10 protection
- `AWSManagedRulesAmazonIpReputationList` - IP reputation blocking
- `AWSManagedRulesSQLiRuleSet` - SQL injection protection
- `AWSManagedRulesLinuxRuleSet` - Linux-specific protections
- `AWSManagedRulesUnixRuleSet` - Unix-specific protections
- `AWSManagedRulesWindowsRuleSet` - Windows-specific protections
- `AWSManagedRulesKnownBadInputsRuleSet` - Known malicious inputs
- `AWSManagedRulesAnonymousIpList` - Anonymous IP blocking
- `AWSManagedRulesBotControlRuleSet` - Bot protection

## Cost Considerations

AWS Managed Rules have additional costs:
- Rule group evaluation charges
- Request processing charges
- CloudWatch metrics charges

Monitor your AWS WAF billing for cost optimization.

## Monitoring

Each rule group creates CloudWatch metrics:
- `AWSManaged-AWSManagedRulesCommonRuleSet`
- `AWSManaged-AWSManagedRulesAmazonIpReputationList`
- `AWSManaged-AWSManagedRulesSQLiRuleSet`

Use these metrics to monitor blocked requests and adjust override actions as needed.