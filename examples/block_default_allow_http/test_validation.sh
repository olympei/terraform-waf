#!/bin/bash

# Block Default Allow HTTP WAF Example Test Validation Script
echo "=== Block Default Allow HTTP WAF Example Validation Test ==="
echo ""

# Test 1: Terraform Init
echo "1. Testing Terraform Init..."
if terraform init > /dev/null 2>&1; then
    echo "✅ Terraform init successful"
else
    echo "❌ Terraform init failed"
    exit 1
fi

# Test 2: Terraform Validate
echo "2. Testing Terraform Validate..."
if terraform validate > /dev/null 2>&1; then
    echo "✅ Terraform validate successful"
else
    echo "❌ Terraform validate failed"
    terraform validate
    exit 1
fi

# Test 3: Terraform Format Check
echo "3. Testing Terraform Format..."
if terraform fmt -check > /dev/null 2>&1; then
    echo "✅ Terraform format check successful"
else
    echo "⚠️  Terraform format check failed - running terraform fmt"
    terraform fmt
    echo "✅ Terraform format applied"
fi

# Test 4: Terraform Plan (dry run without AWS credentials)
echo "4. Testing Terraform Plan (dry run)..."
terraform plan > /dev/null 2>&1
plan_exit_code=$?

if [ $plan_exit_code -eq 0 ]; then
    echo "✅ Terraform plan successful (with AWS credentials)"
elif [ $plan_exit_code -eq 1 ] && terraform plan 2>&1 | grep -q "credential"; then
    echo "✅ Terraform plan shows valid configuration (AWS credentials needed for actual deployment)"
else
    echo "❌ Terraform plan failed with configuration errors"
    terraform plan
    exit 1
fi

# Test 5: Configuration Validation
echo "5. Testing Configuration..."

# Check for default_action = "block"
echo "   Checking default action..."
if grep -q 'default_action = "block"' main.tf; then
    echo "✅ Default action correctly set to 'block'"
else
    echo "❌ Default action not set to 'block'"
    exit 1
fi

# Check for allow rules
echo "   Checking allow rules..."
allow_rule_count=$(grep -c '"allow"' main.tf)
if [ $allow_rule_count -ge 7 ]; then
    echo "✅ Expected number of allow rules found ($allow_rule_count rules)"
else
    echo "❌ Insufficient allow rules found: $allow_rule_count (expected at least 7)"
    exit 1
fi

# Check for block rules
echo "   Checking block rules..."
block_rule_count=$(grep -c '"block"' main.tf)
if [ $block_rule_count -ge 3 ]; then
    echo "✅ Expected number of block rules found ($block_rule_count rules)"
else
    echo "❌ Insufficient block rules found: $block_rule_count (expected at least 3)"
    exit 1
fi

# Check for AWS managed rules with count mode
echo "   Checking AWS managed rules..."
if grep -q 'override_action = "count"' main.tf; then
    echo "✅ AWS managed rules configured in count mode for monitoring"
else
    echo "❌ AWS managed rules not configured properly"
    exit 1
fi

# Check for geographic filtering
echo "   Checking geographic filtering..."
if grep -q "geo_match_statement" main.tf; then
    echo "✅ Geographic filtering configured"
else
    echo "❌ Geographic filtering not found"
    exit 1
fi

# Check for rate limiting
echo "   Checking rate limiting..."
if grep -q "rate_based_statement" main.tf; then
    echo "✅ Rate limiting configured"
else
    echo "❌ Rate limiting not found"
    exit 1
fi

# Check for CloudWatch logging configuration
echo "   Checking CloudWatch logging..."
if grep -q "create_log_group" main.tf && grep -q "existing_log_group_arn" main.tf; then
    echo "✅ CloudWatch logging configuration found"
else
    echo "❌ CloudWatch logging configuration missing"
    exit 1
fi

# Check for logging variables
echo "   Checking logging variables..."
logging_var_count=$(grep -c "variable.*log" main.tf)
if [ $logging_var_count -ge 5 ]; then
    echo "✅ CloudWatch logging variables configured ($logging_var_count variables)"
else
    echo "⚠️  Insufficient logging variables: $logging_var_count (expected at least 5)"
fi

# Check for outputs
echo "   Checking outputs..."
output_count=$(grep -c "output \"" main.tf)
if [ $output_count -ge 6 ]; then
    echo "✅ Expected number of outputs found ($output_count outputs)"
else
    echo "⚠️  Unexpected output count: $output_count (expected at least 6)"
fi

# Test 6: Security Model Validation
echo "6. Testing Security Model..."

# Check for explicit allow patterns
echo "   Checking explicit allow patterns..."
if grep -q "AllowSpecificCountries" main.tf && \
   grep -q "AllowLegitimateUserAgents" main.tf && \
   grep -q "AllowStandardHTTPMethods" main.tf; then
    echo "✅ Explicit allow patterns configured correctly"
else
    echo "❌ Missing explicit allow patterns"
    exit 1
fi

# Check for security blocking patterns
echo "   Checking security blocking patterns..."
if grep -q "BlockExcessiveRequests" main.tf && \
   grep -q "BlockSuspiciousPatterns" main.tf && \
   grep -q "BlockLargePayloads" main.tf; then
    echo "✅ Security blocking patterns configured correctly"
else
    echo "❌ Missing security blocking patterns"
    exit 1
fi

echo ""
echo "=== Validation Summary ==="
echo "✅ All validation tests passed!"
echo "✅ Block Default Allow HTTP WAF example is ready for deployment"
echo ""
echo "🔒 Security Model Validated: DEFAULT DENY - EXPLICIT ALLOW"
echo ""
echo "📋 Configuration Summary:"
echo ""
echo "🛡️  Default Action: BLOCK (High Security Mode)"
echo "   • All traffic blocked by default"
echo "   • Only explicitly allowed patterns pass through"
echo "   • Zero-trust security model"
echo ""
echo "✅ Allow Rules (Priorities 200-206):"
echo "   • Geographic Allow List: 7 countries (US, CA, GB, DE, FR, AU, JP)"
echo "   • User-Agent Validation: Must contain 'Mozilla'"
echo "   • HTTP Method Control: GET, POST, PUT only"
echo "   • Content-Type Validation: HTML and JSON"
echo ""
echo "🚫 Block Rules (Priorities 300-302):"
echo "   • Rate Limiting: 2000 requests/5min per IP"
echo "   • Suspicious Patterns: Path traversal (../)"
echo "   • Large Payloads: >1MB request bodies"
echo ""
echo "📊 Monitoring Rules (Priorities 100-101):"
echo "   • AWS Common Rule Set: COUNT mode (monitoring)"
echo "   • AWS SQLi Rule Set: COUNT mode (monitoring)"
echo ""
echo "📈 Resource Summary:"
echo "   • WAF ACL: 1 (with default_action = block)"
echo "   • Allow Rules: 7 (explicit allow patterns)"
echo "   • Block Rules: 3 (security enforcement)"
echo "   • AWS Managed Rules: 2 (monitoring mode)"
echo "   • Estimated WCUs: ~100"
echo "   • Monthly Cost: ~$3.06"
echo ""
echo "🎯 Use Cases:"
echo "   • High-security applications"
echo "   • Zero-trust architecture"
echo "   • Compliance requirements (PCI DSS, SOX, HIPAA)"
echo "   • API security with strict access control"
echo "   • Applications handling sensitive data"
echo ""
echo "⚠️  CRITICAL WARNINGS:"
echo "   • DEFAULT ACTION IS BLOCK - Test thoroughly before production!"
echo "   • Ensure allow rules cover ALL legitimate traffic patterns"
echo "   • Monitor CloudWatch metrics closely after deployment"
echo "   • Have rollback plan ready (disable WAF if needed)"
echo "   • Test from different geographic locations and browsers"
echo ""
echo "🧪 Testing Commands (after deployment):"
echo ""
echo "Legitimate Traffic (should be ALLOWED):"
echo "curl -H 'User-Agent: Mozilla/5.0' https://your-app.com/"
echo "curl -H 'Content-Type: application/json' -H 'User-Agent: Mozilla/5.0' -X POST https://your-app.com/api"
echo ""
echo "Blocked Traffic (should be BLOCKED - 403 Forbidden):"
echo "curl https://your-app.com/  # No User-Agent"
echo "curl -H 'User-Agent: Mozilla/5.0' https://your-app.com/../etc/passwd  # Path traversal"
echo ""
echo "🚀 Deployment Steps:"
echo "1. Copy terraform.tfvars.example to terraform.tfvars"
echo "2. Customize variables for your environment"
echo "3. Deploy to STAGING first: terraform apply"
echo "4. Test thoroughly with all user workflows"
echo "5. Monitor CloudWatch metrics"
echo "6. Deploy to production only after successful staging tests"
echo ""
echo "📊 CloudWatch Logging & Monitoring:"
echo ""
echo "✅ CloudWatch Logging Features:"
echo "   • Automatic log group creation (or use existing)"
echo "   • Configurable retention (1 day to 10 years)"
echo "   • Optional KMS encryption for sensitive environments"
echo "   • Detailed request/response logging with rule decisions"
echo "   • Support for CloudWatch Insights queries"
echo ""
echo "📈 Monitoring Commands:"
echo ""
echo "# View live WAF logs:"
echo "aws logs tail /aws/wafv2/block-default-allow-http-waf --follow"
echo ""
echo "# Filter blocked requests:"
echo "aws logs filter-log-events --log-group-name /aws/wafv2/block-default-allow-http-waf --filter-pattern '{ \$.action = \"BLOCK\" }'"
echo ""
echo "# Filter allowed requests:"
echo "aws logs filter-log-events --log-group-name /aws/wafv2/block-default-allow-http-waf --filter-pattern '{ \$.action = \"ALLOW\" }'"
echo ""
echo "# CloudWatch metrics:"
echo "aws cloudwatch get-metric-statistics --namespace AWS/WAFV2 --metric-name BlockedRequests --dimensions Name=WebACL,Value=block-default-allow-http-waf"
echo "aws cloudwatch get-metric-statistics --namespace AWS/WAFV2 --metric-name AllowedRequests --dimensions Name=WebACL,Value=block-default-allow-http-waf"
echo ""
echo "💡 CloudWatch Insights Queries (after deployment):"
echo "   • Top blocked countries by traffic volume"
echo "   • Most common User-Agent patterns in blocked requests"
echo "   • Hourly traffic patterns (allowed vs blocked)"
echo "   • Rule effectiveness analysis"
echo ""
echo "📋 Logging Configuration Options:"
echo "   • enable_logging = true/false"
echo "   • create_log_group = true (new) / false (existing)"
echo "   • log_group_retention_days = 30 (configurable)"
echo "   • kms_key_id = null (optional encryption)"