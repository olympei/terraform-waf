#!/bin/bash

# WAF Log Group ARN Validation Script
set -e

echo "🔍 WAF Log Group ARN Validation"
echo "================================"

# Check if AWS CLI is available
if ! command -v aws &> /dev/null; then
    echo "❌ AWS CLI is not installed or not in PATH"
    echo "   Please install AWS CLI: https://aws.amazon.com/cli/"
    exit 1
fi

# Get current AWS context
echo "📍 Getting current AWS context..."
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text 2>/dev/null || echo "ERROR")
REGION=$(aws configure get region 2>/dev/null || echo "ERROR")

if [[ "$ACCOUNT_ID" == "ERROR" ]]; then
    echo "❌ Unable to get AWS account ID. Please check your AWS credentials."
    exit 1
fi

if [[ "$REGION" == "ERROR" || -z "$REGION" ]]; then
    echo "❌ Unable to get AWS region. Please set your default region:"
    echo "   aws configure set region us-east-1"
    exit 1
fi

echo "   Account ID: $ACCOUNT_ID"
echo "   Region: $REGION"
echo ""

# Function to validate ARN format
validate_arn() {
    local arn="$1"
    local errors=0
    
    echo "🔍 Validating ARN: $arn"
    echo ""
    
    # Check if ARN is provided
    if [[ -z "$arn" ]]; then
        echo "❌ No ARN provided"
        return 1
    fi
    
    # Check basic format
    if [[ ! "$arn" =~ ^arn:aws:logs:[a-z0-9-]+:[0-9]{12}:log-group: ]]; then
        echo "❌ Invalid ARN format"
        echo "   Expected: arn:aws:logs:region:account-id:log-group:log-group-name"
        echo "   Received: $arn"
        echo ""
        echo "   Common issues:"
        echo "   - Missing 'log-group' prefix"
        echo "   - Wrong service (should be 'logs', not 'cloudwatch')"
        echo "   - Invalid region or account ID format"
        echo ""
        ((errors++))
    else
        echo "✅ ARN format is valid"
    fi
    
    # Extract components
    IFS=':' read -ra ARN_PARTS <<< "$arn"
    
    if [[ ${#ARN_PARTS[@]} -lt 6 ]]; then
        echo "❌ ARN has insufficient components (${#ARN_PARTS[@]}/6)"
        ((errors++))
        return $errors
    fi
    
    ARN_SERVICE="${ARN_PARTS[2]}"
    ARN_REGION="${ARN_PARTS[3]}"
    ARN_ACCOUNT="${ARN_PARTS[4]}"
    ARN_RESOURCE_TYPE="${ARN_PARTS[5]}"
    LOG_GROUP_NAME="${ARN_PARTS[6]}"
    
    echo "📋 ARN Components:"
    echo "   Service: $ARN_SERVICE"
    echo "   Region: $ARN_REGION"
    echo "   Account: $ARN_ACCOUNT"
    echo "   Resource Type: $ARN_RESOURCE_TYPE"
    echo "   Log Group: $LOG_GROUP_NAME"
    echo ""
    
    # Validate service
    if [[ "$ARN_SERVICE" != "logs" ]]; then
        echo "❌ Wrong service: '$ARN_SERVICE' (should be 'logs')"
        ((errors++))
    else
        echo "✅ Service is correct"
    fi
    
    # Validate resource type
    if [[ "$ARN_RESOURCE_TYPE" != "log-group" ]]; then
        echo "❌ Wrong resource type: '$ARN_RESOURCE_TYPE' (should be 'log-group')"
        ((errors++))
    else
        echo "✅ Resource type is correct"
    fi
    
    # Validate region
    if [[ "$ARN_REGION" != "$REGION" ]]; then
        echo "⚠️  Region mismatch: ARN has '$ARN_REGION', current region is '$REGION'"
        echo "   This will cause deployment to fail unless you deploy in region '$ARN_REGION'"
        ((errors++))
    else
        echo "✅ Region matches current deployment region"
    fi
    
    # Validate account
    if [[ "$ARN_ACCOUNT" != "$ACCOUNT_ID" ]]; then
        echo "⚠️  Account mismatch: ARN has '$ARN_ACCOUNT', current account is '$ACCOUNT_ID'"
        echo "   This will cause deployment to fail unless you deploy to account '$ARN_ACCOUNT'"
        ((errors++))
    else
        echo "✅ Account ID matches current AWS account"
    fi
    
    # Validate log group name format and AWS WAF naming requirement
    if [[ -z "$LOG_GROUP_NAME" ]]; then
        echo "❌ Log group name is empty"
        ((errors++))
    elif [[ "$LOG_GROUP_NAME" =~ [[:space:]] ]]; then
        echo "❌ Log group name contains spaces: '$LOG_GROUP_NAME'"
        ((errors++))
    elif [[ ! "$LOG_GROUP_NAME" =~ ^aws-waf-logs- ]]; then
        echo "❌ CRITICAL: Log group name must start with 'aws-waf-logs-' prefix!"
        echo "   Current name: '$LOG_GROUP_NAME'"
        echo "   Required prefix: 'aws-waf-logs-'"
        echo "   AWS WAF requires log destinations to have this prefix"
        echo "   Example: 'aws-waf-logs-my-waf' or 'aws-waf-logs-production'"
        ((errors++))
    elif [[ "$LOG_GROUP_NAME" =~ [^a-zA-Z0-9._/-] ]]; then
        echo "⚠️  Log group name contains special characters: '$LOG_GROUP_NAME'"
        echo "   Valid characters: letters, numbers, periods, underscores, hyphens, forward slashes"
    else
        echo "✅ Log group name format is valid with required 'aws-waf-logs-' prefix"
    fi
    
    # Check if log group exists
    echo ""
    echo "🔍 Checking if log group exists..."
    if aws logs describe-log-groups --log-group-name-prefix "$LOG_GROUP_NAME" --query "logGroups[?logGroupName=='$LOG_GROUP_NAME'].logGroupName" --output text 2>/dev/null | grep -q "^$LOG_GROUP_NAME$"; then
        echo "✅ Log group exists: $LOG_GROUP_NAME"
        
        # Get additional info about the log group
        LOG_GROUP_INFO=$(aws logs describe-log-groups --log-group-name-prefix "$LOG_GROUP_NAME" --query "logGroups[?logGroupName=='$LOG_GROUP_NAME']" --output json 2>/dev/null)
        RETENTION_DAYS=$(echo "$LOG_GROUP_INFO" | jq -r '.[0].retentionInDays // "Never expire"')
        CREATION_TIME=$(echo "$LOG_GROUP_INFO" | jq -r '.[0].creationTime' | xargs -I {} date -d @{} 2>/dev/null || echo "Unknown")
        
        echo "   Retention: $RETENTION_DAYS days"
        echo "   Created: $CREATION_TIME"
    else
        echo "❌ Log group does not exist: $LOG_GROUP_NAME"
        echo "   Create it with: aws logs create-log-group --log-group-name '$LOG_GROUP_NAME'"
        ((errors++))
    fi
    
    echo ""
    return $errors
}

# Function to generate correct ARN with required aws-waf-logs- prefix
generate_correct_arn() {
    local log_group_name="${1:-aws-waf-logs-my-waf}"
    
    # Ensure the name starts with aws-waf-logs- prefix
    if [[ ! "$log_group_name" =~ ^aws-waf-logs- ]]; then
        log_group_name="aws-waf-logs-$log_group_name"
    fi
    
    echo "arn:aws:logs:$REGION:$ACCOUNT_ID:log-group:$log_group_name"
}

# Main script logic
if [[ $# -eq 0 ]]; then
    echo "Usage: $0 <log-group-arn> [log-group-name]"
    echo ""
    echo "Examples:"
    echo "  $0 'arn:aws:logs:us-east-1:123456789012:log-group:aws-waf-logs-my-waf'"
    echo "  $0 'arn:aws:logs:us-east-1:123456789012:log-group:aws-waf-logs-production'"
    echo ""
    echo "Generate correct ARN for your current context:"
    echo "  Correct ARN: $(generate_correct_arn)"
    echo "  Custom name: $(generate_correct_arn 'my-custom-waf')"
    echo ""
    echo "⚠️  IMPORTANT: Log group names MUST start with 'aws-waf-logs-' prefix!"
    echo ""
    exit 1
fi

# Validate the provided ARN
validate_arn "$1"
VALIDATION_RESULT=$?

echo ""
echo "🎯 Quick Fix Commands:"
echo "====================="
echo ""

if [[ $VALIDATION_RESULT -eq 0 ]]; then
    echo "🎉 ARN validation passed! You can use this ARN in your Terraform configuration."
    echo ""
    echo "Terraform configuration:"
    echo "  existing_log_group_arn = \"$1\""
else
    echo "❌ ARN validation failed. Here are the fixes:"
    echo ""
    
    # Extract log group name for suggestions
    IFS=':' read -ra ARN_PARTS <<< "$1"
    if [[ ${#ARN_PARTS[@]} -ge 6 ]]; then
        SUGGESTED_LOG_GROUP="${ARN_PARTS[6]}"
    else
        SUGGESTED_LOG_GROUP="/aws/wafv2/my-waf"
    fi
    
    # Ensure suggested log group has proper prefix
    if [[ ! "$SUGGESTED_LOG_GROUP" =~ ^aws-waf-logs- ]]; then
        SUGGESTED_LOG_GROUP="aws-waf-logs-${SUGGESTED_LOG_GROUP#/aws/wafv2/}"
    fi
    
    echo "1. Create the log group with required prefix:"
    echo "   aws logs create-log-group --log-group-name '$SUGGESTED_LOG_GROUP'"
    echo ""
    
    echo "2. Use correct ARN format:"
    echo "   existing_log_group_arn = \"$(generate_correct_arn "$SUGGESTED_LOG_GROUP")\""
    echo ""
    
    echo "3. Or let the module create the log group:"
    echo "   create_log_group = true"
    echo "   log_group_name = \"$SUGGESTED_LOG_GROUP\""
fi

echo ""
echo "📋 Terraform Configuration Examples:"
echo "===================================="
echo ""

echo "Option 1 - Use existing log group:"
cat << EOF
module "waf" {
  source = "./modules/waf"
  
  name                   = "my-waf"
  scope                  = "REGIONAL"
  default_action         = "allow"
  create_log_group       = false
  existing_log_group_arn = "$(generate_correct_arn)"
  
  alb_arn_list = ["your-alb-arn"]
}
EOF

echo ""
echo "Option 2 - Let module create log group (with required prefix):"
cat << EOF
module "waf" {
  source = "./modules/waf"
  
  name                        = "my-waf"
  scope                       = "REGIONAL"
  default_action              = "allow"
  create_log_group            = true
  log_group_name              = "aws-waf-logs-my-waf"  # Required prefix!
  log_group_retention_in_days = 30
  
  alb_arn_list = ["your-alb-arn"]
}
EOF

echo ""
echo "Option 3 - Create log group separately (with required prefix):"
cat << EOF
resource "aws_cloudwatch_log_group" "waf_logs" {
  name              = "aws-waf-logs-my-waf"  # Required prefix!
  retention_in_days = 30
}

module "waf" {
  source = "./modules/waf"
  
  name                   = "my-waf"
  scope                  = "REGIONAL"
  default_action         = "allow"
  create_log_group       = false
  existing_log_group_arn = aws_cloudwatch_log_group.waf_logs.arn
  
  alb_arn_list = ["your-alb-arn"]
}
EOF

echo ""
echo "🔧 Additional Debugging:"
echo "========================"
echo ""
echo "Test Terraform plan:"
echo "  terraform plan -var=\"existing_log_group_arn=$(generate_correct_arn)\""
echo ""
echo "List existing WAF log groups:"
echo "  aws logs describe-log-groups --log-group-name-prefix '/aws/wafv2/'"
echo ""
echo "Enable Terraform debug logging:"
echo "  export TF_LOG=DEBUG"
echo "  terraform apply"

exit $VALIDATION_RESULT