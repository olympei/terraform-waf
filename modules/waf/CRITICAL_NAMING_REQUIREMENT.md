# 🚨 CRITICAL: AWS WAF Log Group Naming Requirement

## The Root Cause of "The ARN isn't valid" Error

The most common cause of the WAF logging configuration error is **missing the required `aws-waf-logs-` prefix** in the log group name.

## ⚠️ AWS Requirement

According to AWS documentation, **ALL** WAF log destinations must be prefixed with `aws-waf-logs-`:

> **log_destination_configs** - (Required) Configuration block that allows you to associate Amazon Kinesis Data Firehose, Cloudwatch Log log group, or S3 bucket Amazon Resource Names (ARNs) with the web ACL. 
> 
> **Note: data firehose, log group, or bucket name must be prefixed with aws-waf-logs-**, e.g. aws-waf-logs-example-firehose, aws-waf-logs-example-log-group, or aws-waf-logs-example-bucket

## 🔧 Quick Fix

### ❌ WRONG (Will Fail)
```hcl
resource "aws_cloudwatch_log_group" "waf_logs" {
  name = "/aws/wafv2/my-waf"  # Missing required prefix
}

module "waf" {
  source = "./modules/waf"
  
  existing_log_group_arn = aws_cloudwatch_log_group.waf_logs.arn
}
```

### ✅ CORRECT (Will Work)
```hcl
resource "aws_cloudwatch_log_group" "waf_logs" {
  name = "aws-waf-logs-my-waf"  # Required prefix!
}

module "waf" {
  source = "./modules/waf"
  
  existing_log_group_arn = aws_cloudwatch_log_group.waf_logs.arn
}
```

## 🎯 All Valid Naming Examples

### CloudWatch Log Groups
- `aws-waf-logs-production`
- `aws-waf-logs-my-application`
- `aws-waf-logs-web-firewall`
- `aws-waf-logs-api-protection`

### Kinesis Data Firehose
- `aws-waf-logs-firehose-stream`
- `aws-waf-logs-analytics-stream`

### S3 Buckets
- `aws-waf-logs-storage-bucket`
- `aws-waf-logs-archive-bucket`

## 🚀 Module Auto-Fix

The enhanced WAF module now automatically handles this requirement:

```hcl
module "waf" {
  source = "./modules/waf"
  
  name             = "my-waf"
  scope            = "REGIONAL"
  default_action   = "allow"
  create_log_group = true  # Module automatically adds aws-waf-logs- prefix
  
  alb_arn_list = ["your-alb-arn"]
}
```

The module will create: `aws-waf-logs-my-waf`

## 🔍 Validation

Use the validation script to check your ARN:

```bash
./validate_log_group_arn.sh "arn:aws:logs:us-east-1:123456789012:log-group:aws-waf-logs-my-waf"
```

## 📋 Complete ARN Format

```
arn:aws:logs:REGION:ACCOUNT_ID:log-group:aws-waf-logs-LOG_GROUP_NAME
```

**Example**:
```
arn:aws:logs:us-east-1:123456789012:log-group:aws-waf-logs-production-waf
```

## 🛠️ Migration Guide

If you have existing log groups without the prefix:

### Step 1: Create New Log Group
```bash
aws logs create-log-group --log-group-name "aws-waf-logs-my-waf"
```

### Step 2: Update Terraform Configuration
```hcl
# Old (will fail)
existing_log_group_arn = "arn:aws:logs:us-east-1:123456789012:log-group:/aws/wafv2/my-waf"

# New (will work)
existing_log_group_arn = "arn:aws:logs:us-east-1:123456789012:log-group:aws-waf-logs-my-waf"
```

### Step 3: Apply Changes
```bash
terraform plan
terraform apply
```

### Step 4: Clean Up Old Log Group (Optional)
```bash
aws logs delete-log-group --log-group-name "/aws/wafv2/my-waf"
```

## 🎉 Result

After applying the naming requirement:
- ✅ WAF logging configuration will succeed
- ✅ Clear error messages if naming is still incorrect
- ✅ Automatic prefix handling in the module
- ✅ Validation tools to prevent future issues

## 📞 Still Having Issues?

1. **Run the validation script**: `./validate_log_group_arn.sh "your-arn"`
2. **Check the error message**: The enhanced module provides specific guidance
3. **Use module auto-creation**: Set `create_log_group = true`
4. **Verify AWS credentials**: Ensure you have proper permissions

The `aws-waf-logs-` prefix requirement is the #1 cause of WAF logging failures. Following this naming convention will resolve most issues immediately.