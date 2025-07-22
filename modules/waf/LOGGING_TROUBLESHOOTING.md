# WAF Logging Configuration Troubleshooting Guide

## Common Error: "The ARN isn't valid" for WAF Logging Configuration

### Problem Description
When using an existing CloudWatch Log Group with the WAF module, you may encounter the error:
```
Error: putting WAFv2 LOGGING CONFIGURATION, The ARN isn't valid
```

### Root Causes and Solutions

#### 1. Invalid Log Group ARN Format

**Problem**: The provided `existing_log_group_arn` doesn't match the expected CloudWatch Log Group ARN format.

**Expected Format**:
```
arn:aws:logs:region:account-id:log-group:aws-waf-logs-*
```

**⚠️ CRITICAL AWS REQUIREMENT**: Log group name MUST start with `aws-waf-logs-` prefix!

**Examples of Valid ARNs**:
```
arn:aws:logs:us-east-1:123456789012:log-group:aws-waf-logs-my-waf
arn:aws:logs:eu-west-1:123456789012:log-group:aws-waf-logs-production
arn:aws:logs:ap-southeast-1:123456789012:log-group:aws-waf-logs-example-firehose
```

**Examples of Invalid ARNs**:
```
# Missing aws-waf-logs- prefix (MOST COMMON ISSUE!)
arn:aws:logs:us-east-1:123456789012:log-group:/aws/wafv2/my-waf
arn:aws:logs:us-east-1:123456789012:log-group:my-waf

# Missing log-group prefix
arn:aws:logs:us-east-1:123456789012:aws-waf-logs-my-waf

# Wrong service (should be 'logs', not 'cloudwatch')
arn:aws:cloudwatch:us-east-1:123456789012:log-group:aws-waf-logs-my-waf

# Missing region or account ID
arn:aws:logs::123456789012:log-group:aws-waf-logs-my-waf
arn:aws:logs:us-east-1::log-group:aws-waf-logs-my-waf

# Malformed structure
aws-waf-logs-my-waf
my-log-group
```

**Solution**: Ensure your ARN follows the correct format with required prefix:
```hcl
module "waf" {
  source = "./modules/waf"
  
  name                    = "my-waf"
  scope                   = "REGIONAL"
  default_action          = "allow"
  create_log_group        = false
  existing_log_group_arn  = "arn:aws:logs:us-east-1:123456789012:log-group:aws-waf-logs-my-existing-log-group"
}
```

#### 2. Log Group Doesn't Exist

**Problem**: The specified log group ARN points to a non-existent log group.

**Verification**: Check if the log group exists:
```bash
aws logs describe-log-groups --log-group-name-prefix "/aws/wafv2/my-waf"
```

**Solution**: Create the log group first or use `create_log_group = true`:
```bash
# Create log group manually
aws logs create-log-group --log-group-name "/aws/wafv2/my-waf"

# Or let the module create it
module "waf" {
  source = "./modules/waf"
  
  name             = "my-waf"
  scope            = "REGIONAL"
  default_action   = "allow"
  create_log_group = true  # Let module create the log group
}
```

#### 3. Incorrect Region in ARN

**Problem**: The region in the ARN doesn't match the region where the WAF is being deployed.

**Example Issue**:
```hcl
# WAF deployed in us-west-2, but log group ARN specifies us-east-1
provider "aws" {
  region = "us-west-2"
}

module "waf" {
  source = "./modules/waf"
  
  existing_log_group_arn = "arn:aws:logs:us-east-1:123456789012:log-group:/aws/wafv2/my-waf"
}
```

**Solution**: Ensure the region in the ARN matches your deployment region:
```hcl
module "waf" {
  source = "./modules/waf"
  
  existing_log_group_arn = "arn:aws:logs:us-west-2:123456789012:log-group:/aws/wafv2/my-waf"
}
```

#### 4. Incorrect Account ID in ARN

**Problem**: The account ID in the ARN doesn't match your AWS account.

**Get Your Account ID**:
```bash
aws sts get-caller-identity --query Account --output text
```

**Solution**: Use the correct account ID in the ARN:
```hcl
module "waf" {
  source = "./modules/waf"
  
  existing_log_group_arn = "arn:aws:logs:us-east-1:YOUR_ACCOUNT_ID:log-group:/aws/wafv2/my-waf"
}
```

#### 5. Missing Required 'aws-waf-logs-' Prefix (MOST COMMON!)

**Problem**: The log group name doesn't start with the required `aws-waf-logs-` prefix.

**AWS Requirement**: All WAF log destinations must be prefixed with `aws-waf-logs-`:
- CloudWatch Log Group: `aws-waf-logs-example-log-group`
- Kinesis Data Firehose: `aws-waf-logs-example-firehose`
- S3 Bucket: `aws-waf-logs-example-bucket`

**Invalid Examples**:
```
# Missing prefix
arn:aws:logs:us-east-1:123456789012:log-group:/aws/wafv2/my-waf
arn:aws:logs:us-east-1:123456789012:log-group:my-waf-logs

# Wrong prefix
arn:aws:logs:us-east-1:123456789012:log-group:waf-logs-my-waf
```

**Solution**: Add the required prefix to your log group name:
```hcl
module "waf" {
  source = "./modules/waf"
  
  name                   = "my-waf"
  scope                  = "REGIONAL"
  default_action         = "allow"
  create_log_group       = true
  log_group_name         = "aws-waf-logs-my-waf"  # Required prefix!
  
  alb_arn_list = ["your-alb-arn"]
}
```

#### 6. Log Group Name Contains Invalid Characters

**Problem**: The log group name in the ARN contains characters that aren't allowed.

**Valid Characters**: Letters, numbers, periods (.), underscores (_), hyphens (-), and forward slashes (/)

**Invalid Examples**:
```
# Contains spaces
arn:aws:logs:us-east-1:123456789012:log-group:my waf logs

# Contains special characters
arn:aws:logs:us-east-1:123456789012:log-group:my-waf@logs
```

**Solution**: Use only valid characters in log group names:
```hcl
module "waf" {
  source = "./modules/waf"
  
  existing_log_group_arn = "arn:aws:logs:us-east-1:123456789012:log-group:/aws/wafv2/my-waf-logs"
}
```

### Debugging Steps

#### Step 1: Validate ARN Format
```bash
# Check if your ARN matches the expected pattern
echo "arn:aws:logs:us-east-1:123456789012:log-group:/aws/wafv2/my-waf" | \
grep -E "^arn:aws:logs:[a-z0-9-]+:[0-9]{12}:log-group:"
```

#### Step 2: Verify Log Group Exists
```bash
# Extract log group name from ARN and check if it exists
LOG_GROUP_NAME="/aws/wafv2/my-waf"
aws logs describe-log-groups --log-group-name-prefix "$LOG_GROUP_NAME"
```

#### Step 3: Check Permissions
Ensure your IAM user/role has the necessary permissions:
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "logs:DescribeLogGroups",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "wafv2:PutLoggingConfiguration"
      ],
      "Resource": [
        "arn:aws:logs:*:*:log-group:/aws/wafv2/*",
        "arn:aws:wafv2:*:*:webacl/*/*"
      ]
    }
  ]
}
```

#### Step 4: Test with Terraform Plan
```bash
terraform plan -var="existing_log_group_arn=arn:aws:logs:us-east-1:123456789012:log-group:/aws/wafv2/my-waf"
```

### Working Examples

#### Example 1: Using Existing Log Group (with required prefix)
```hcl
# First, create the log group with required aws-waf-logs- prefix
resource "aws_cloudwatch_log_group" "waf_logs" {
  name              = "aws-waf-logs-my-enterprise-waf"  # Required prefix!
  retention_in_days = 365
  
  tags = {
    Environment = "production"
    Purpose     = "WAF logging"
  }
}

# Then reference it in the WAF module
module "waf" {
  source = "./modules/waf"
  
  name                    = "my-enterprise-waf"
  scope                   = "REGIONAL"
  default_action          = "allow"
  create_log_group        = false
  existing_log_group_arn  = aws_cloudwatch_log_group.waf_logs.arn
  
  alb_arn_list = [
    "arn:aws:elasticloadbalancing:us-east-1:123456789012:loadbalancer/app/my-alb/1234567890123456"
  ]
}
```

#### Example 2: Let Module Create Log Group (with required prefix)
```hcl
module "waf" {
  source = "./modules/waf"
  
  name                        = "my-enterprise-waf"
  scope                       = "REGIONAL"
  default_action              = "allow"
  create_log_group            = true
  log_group_name              = "aws-waf-logs-my-enterprise-waf"  # Required prefix!
  log_group_retention_in_days = 365
  kms_key_id                  = null  # Auto-create KMS key
  
  alb_arn_list = [
    "arn:aws:elasticloadbalancing:us-east-1:123456789012:loadbalancer/app/my-alb/1234567890123456"
  ]
}
```

#### Example 3: Cross-Account Log Group (Advanced)
```hcl
# For cross-account logging, ensure proper permissions are set
module "waf" {
  source = "./modules/waf"
  
  name                    = "cross-account-waf"
  scope                   = "REGIONAL"
  default_action          = "allow"
  create_log_group        = false
  existing_log_group_arn  = "arn:aws:logs:us-east-1:LOGGING_ACCOUNT_ID:log-group:/aws/wafv2/centralized-logs"
  
  alb_arn_list = [
    "arn:aws:elasticloadbalancing:us-east-1:123456789012:loadbalancer/app/my-alb/1234567890123456"
  ]
}
```

### Prevention Tips

1. **Use Data Sources**: Get log group ARN dynamically:
```hcl
data "aws_cloudwatch_log_group" "existing" {
  name = "/aws/wafv2/my-existing-log-group"
}

module "waf" {
  source = "./modules/waf"
  
  existing_log_group_arn = data.aws_cloudwatch_log_group.existing.arn
}
```

2. **Validate ARNs in Terraform**:
```hcl
locals {
  log_group_arn = "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/wafv2/my-waf"
}

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

module "waf" {
  source = "./modules/waf"
  
  existing_log_group_arn = local.log_group_arn
}
```

3. **Use Consistent Naming**:
```hcl
locals {
  waf_name = "my-enterprise-waf"
  log_group_name = "/aws/wafv2/${local.waf_name}"
}

resource "aws_cloudwatch_log_group" "waf_logs" {
  name = local.log_group_name
}

module "waf" {
  source = "./modules/waf"
  
  name                   = local.waf_name
  existing_log_group_arn = aws_cloudwatch_log_group.waf_logs.arn
}
```

### Quick Fix Commands

If you're experiencing this issue right now, try these quick fixes:

```bash
# 1. Check your current AWS account and region
aws sts get-caller-identity
aws configure get region

# 2. List existing log groups to find the correct ARN
aws logs describe-log-groups --query 'logGroups[?contains(logGroupName, `waf`)].{Name:logGroupName,Arn:arn}'

# 3. Create a new log group if needed
aws logs create-log-group --log-group-name "/aws/wafv2/my-waf-$(date +%s)"

# 4. Validate your Terraform configuration
terraform validate
terraform plan
```

This should resolve the "ARN isn't valid" error for WAF logging configuration.