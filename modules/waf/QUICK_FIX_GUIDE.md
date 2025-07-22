# WAF Logging Error - Quick Fix Guide

## Error: "putting WAFv2 LOGGING CONFIGURATION, The ARN isn't valid"

### 🚨 Immediate Fix Steps

#### Step 1: Check Your Current AWS Context
```bash
# Get your current account ID and region
aws sts get-caller-identity --query Account --output text
aws configure get region
```

#### Step 2: Validate Your Log Group ARN Format
Your ARN should look like this:
```
arn:aws:logs:REGION:ACCOUNT_ID:log-group:LOG_GROUP_NAME
```

**Example of correct ARN**:
```
arn:aws:logs:us-east-1:123456789012:log-group:/aws/wafv2/my-waf
```

#### Step 3: Common Fixes

##### Fix 1: ARN Format Issues
```hcl
# ❌ WRONG - Missing log-group prefix
existing_log_group_arn = "arn:aws:logs:us-east-1:123456789012:/aws/wafv2/my-waf"

# ✅ CORRECT - Proper format
existing_log_group_arn = "arn:aws:logs:us-east-1:123456789012:log-group:/aws/wafv2/my-waf"
```

##### Fix 2: Wrong Service Name
```hcl
# ❌ WRONG - Using 'cloudwatch' instead of 'logs'
existing_log_group_arn = "arn:aws:cloudwatch:us-east-1:123456789012:log-group:/aws/wafv2/my-waf"

# ✅ CORRECT - Using 'logs'
existing_log_group_arn = "arn:aws:logs:us-east-1:123456789012:log-group:/aws/wafv2/my-waf"
```

##### Fix 3: Region/Account Mismatch
```bash
# Check if log group exists in your current region/account
aws logs describe-log-groups --log-group-name-prefix "/aws/wafv2/"
```

#### Step 4: Quick Solutions

##### Solution A: Let the Module Create the Log Group
```hcl
module "waf" {
  source = "./modules/waf"
  
  name             = "my-waf"
  scope            = "REGIONAL"
  default_action   = "allow"
  
  # Let module create log group
  create_log_group            = true
  log_group_name              = "/aws/wafv2/my-waf"
  log_group_retention_in_days = 30
  
  alb_arn_list = ["your-alb-arn"]
}
```

##### Solution B: Create Log Group First, Then Reference
```hcl
# Create log group first
resource "aws_cloudwatch_log_group" "waf_logs" {
  name              = "/aws/wafv2/my-waf"
  retention_in_days = 30
}

# Then use it in WAF module
module "waf" {
  source = "./modules/waf"
  
  name                   = "my-waf"
  scope                  = "REGIONAL"
  default_action         = "allow"
  create_log_group       = false
  existing_log_group_arn = aws_cloudwatch_log_group.waf_logs.arn
  
  alb_arn_list = ["your-alb-arn"]
}
```

##### Solution C: Use Data Source for Existing Log Group
```hcl
# Reference existing log group
data "aws_cloudwatch_log_group" "existing" {
  name = "/aws/wafv2/my-existing-log-group"
}

module "waf" {
  source = "./modules/waf"
  
  name                   = "my-waf"
  scope                  = "REGIONAL"
  default_action         = "allow"
  create_log_group       = false
  existing_log_group_arn = data.aws_cloudwatch_log_group.existing.arn
  
  alb_arn_list = ["your-alb-arn"]
}
```

### 🔧 Validation Script

Save this as `validate_log_group_arn.sh`:

```bash
#!/bin/bash

# WAF Log Group ARN Validation Script
set -e

echo "🔍 WAF Log Group ARN Validation"
echo "================================"

# Get current AWS context
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
REGION=$(aws configure get region)

echo "📍 Current AWS Context:"
echo "   Account ID: $ACCOUNT_ID"
echo "   Region: $REGION"
echo ""

# Function to validate ARN format
validate_arn() {
    local arn="$1"
    
    echo "🔍 Validating ARN: $arn"
    
    # Check basic format
    if [[ ! "$arn" =~ ^arn:aws:logs:[a-z0-9-]+:[0-9]{12}:log-group: ]]; then
        echo "❌ Invalid ARN format"
        echo "   Expected: arn:aws:logs:region:account-id:log-group:log-group-name"
        return 1
    fi
    
    # Extract components
    IFS=':' read -ra ARN_PARTS <<< "$arn"
    ARN_REGION="${ARN_PARTS[3]}"
    ARN_ACCOUNT="${ARN_PARTS[4]}"
    LOG_GROUP_NAME="${ARN_PARTS[6]}"
    
    echo "   Service: ${ARN_PARTS[2]}"
    echo "   Region: $ARN_REGION"
    echo "   Account: $ARN_ACCOUNT"
    echo "   Log Group: $LOG_GROUP_NAME"
    
    # Validate region
    if [[ "$ARN_REGION" != "$REGION" ]]; then
        echo "⚠️  Region mismatch: ARN has '$ARN_REGION', current region is '$REGION'"
    fi
    
    # Validate account
    if [[ "$ARN_ACCOUNT" != "$ACCOUNT_ID" ]]; then
        echo "⚠️  Account mismatch: ARN has '$ARN_ACCOUNT', current account is '$ACCOUNT_ID'"
    fi
    
    # Check if log group exists
    if aws logs describe-log-groups --log-group-name-prefix "$LOG_GROUP_NAME" --query 'logGroups[0].logGroupName' --output text 2>/dev/null | grep -q "$LOG_GROUP_NAME"; then
        echo "✅ Log group exists"
    else
        echo "❌ Log group does not exist: $LOG_GROUP_NAME"
        echo "   Create it with: aws logs create-log-group --log-group-name '$LOG_GROUP_NAME'"
    fi
    
    echo ""
}

# Example usage
if [[ $# -eq 0 ]]; then
    echo "Usage: $0 <log-group-arn>"
    echo ""
    echo "Example:"
    echo "  $0 'arn:aws:logs:us-east-1:123456789012:log-group:/aws/wafv2/my-waf'"
    echo ""
    echo "Or generate a correct ARN for your current context:"
    echo "  Correct ARN: arn:aws:logs:$REGION:$ACCOUNT_ID:log-group:/aws/wafv2/my-waf"
    exit 1
fi

validate_arn "$1"

echo "🎯 Quick Fix Commands:"
echo "====================="
echo ""
echo "1. Create log group:"
echo "   aws logs create-log-group --log-group-name '/aws/wafv2/my-waf'"
echo ""
echo "2. Use correct ARN in Terraform:"
echo "   existing_log_group_arn = \"arn:aws:logs:$REGION:$ACCOUNT_ID:log-group:/aws/wafv2/my-waf\""
echo ""
echo "3. Or let module create log group:"
echo "   create_log_group = true"
echo "   log_group_name = \"/aws/wafv2/my-waf\""
```

Make it executable:
```bash
chmod +x validate_log_group_arn.sh
```

### 🚀 Test Your Fix

#### Test 1: Validate ARN Format
```bash
./validate_log_group_arn.sh "arn:aws:logs:us-east-1:123456789012:log-group:/aws/wafv2/my-waf"
```

#### Test 2: Terraform Plan
```bash
terraform plan -var="existing_log_group_arn=arn:aws:logs:us-east-1:123456789012:log-group:/aws/wafv2/my-waf"
```

#### Test 3: Check Log Group Exists
```bash
aws logs describe-log-groups --log-group-name-prefix "/aws/wafv2/"
```

### 📋 Checklist

Before running `terraform apply`, ensure:

- [ ] ARN format is correct: `arn:aws:logs:region:account-id:log-group:log-group-name`
- [ ] Region in ARN matches your deployment region
- [ ] Account ID in ARN matches your AWS account
- [ ] Log group actually exists (or `create_log_group = true`)
- [ ] Log group name contains only valid characters
- [ ] You have proper IAM permissions for WAF and CloudWatch Logs

### 🆘 Still Having Issues?

If you're still experiencing problems:

1. **Check IAM Permissions**:
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:DescribeLogGroups",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "wafv2:PutLoggingConfiguration",
        "wafv2:GetLoggingConfiguration"
      ],
      "Resource": "*"
    }
  ]
}
```

2. **Enable Debug Logging**:
```bash
export TF_LOG=DEBUG
terraform apply
```

3. **Use Module's Auto-Creation**:
```hcl
module "waf" {
  source = "./modules/waf"
  
  name             = "my-waf"
  scope            = "REGIONAL"
  default_action   = "allow"
  create_log_group = true  # Let module handle everything
  
  alb_arn_list = ["your-alb-arn"]
}
```

This should resolve the "ARN isn't valid" error for WAF logging configuration.