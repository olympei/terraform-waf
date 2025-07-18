#!/bin/bash

# Enterprise WAF Security Testing Script
# Run this script AFTER deploying the enterprise WAF to validate security controls
# Usage: ./test_enterprise_security.sh https://your-application.com

if [ $# -eq 0 ]; then
    echo "Usage: $0 <your-application-url>"
    echo "Example: $0 https://my-enterprise-app.example.com"
    exit 1
fi

APP_URL="$1"
echo "=== Enterprise WAF Security Testing ==="
echo "Testing enterprise security controls for: $APP_URL"
echo ""

# Test Results Summary
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0
WARNING_TESTS=0

run_test() {
    local test_name="$1"
    local expected_result="$2"
    local command="$3"
    local description="$4"
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    echo "🧪 Test $TOTAL_TESTS: $test_name"
    echo "   Expected: $expected_result"
    echo "   Command: $command"
    
    response=$(eval "$command" 2>/dev/null)
    
    case "$expected_result" in
        "ALLOWED")
            if [ "$response" = "200" ] || [ "$response" = "301" ] || [ "$response" = "302" ]; then
                echo "   ✅ PASS: Request allowed (HTTP $response)"
                PASSED_TESTS=$((PASSED_TESTS + 1))
            else
                echo "   ❌ FAIL: Request blocked or error (HTTP $response)"
                echo "   ⚠️  This might indicate legitimate traffic is being blocked!"
                FAILED_TESTS=$((FAILED_TESTS + 1))
            fi
            ;;
        "BLOCKED")
            if [ "$response" = "403" ]; then
                echo "   ✅ PASS: Request blocked by WAF (HTTP $response)"
                PASSED_TESTS=$((PASSED_TESTS + 1))
            elif [ "$response" = "404" ]; then
                echo "   ⚠️  WARNING: Request returned 404 (might be blocked by app, not WAF)"
                WARNING_TESTS=$((WARNING_TESTS + 1))
            elif [ "$response" = "200" ] || [ "$response" = "301" ] || [ "$response" = "302" ]; then
                echo "   ❌ FAIL: Security vulnerability - request was allowed (HTTP $response)"
                echo "   🚨 SECURITY ISSUE: $description"
                FAILED_TESTS=$((FAILED_TESTS + 1))
            else
                echo "   ❓ UNKNOWN: Unexpected response (HTTP $response)"
                WARNING_TESTS=$((WARNING_TESTS + 1))
            fi
            ;;
    esac
    echo "   Description: $description"
    echo ""
}

echo "🔒 Testing Enterprise Security Controls"
echo "======================================"
echo ""

# Layer 1: Legitimate Traffic Tests (Should be ALLOWED)
echo "📋 Layer 1: Legitimate Traffic Validation"
echo "----------------------------------------"

run_test "Legitimate Browser Request" "ALLOWED" \
    "curl -s -o /dev/null -w '%{http_code}' -H 'User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36' -H 'Accept: text/html' '$APP_URL'" \
    "Standard browser request should be allowed"

run_test "JSON API Request" "ALLOWED" \
    "curl -s -o /dev/null -w '%{http_code}' -H 'User-Agent: Mozilla/5.0' -H 'Content-Type: application/json' -H 'Accept: application/json' -X POST '$APP_URL/api/health'" \
    "Legitimate API requests should be allowed"

run_test "Standard Form Submission" "ALLOWED" \
    "curl -s -o /dev/null -w '%{http_code}' -H 'User-Agent: Mozilla/5.0' -H 'Content-Type: application/x-www-form-urlencoded' -X POST -d 'username=test&action=login' '$APP_URL/login'" \
    "Standard form submissions should be allowed"

# Layer 2: SQL Injection Tests (Should be BLOCKED)
echo "📋 Layer 2: SQL Injection Protection"
echo "-----------------------------------"

run_test "Basic SQL Injection" "BLOCKED" \
    "curl -s -o /dev/null -w '%{http_code}' -H 'User-Agent: Mozilla/5.0' '$APP_URL/search?q=admin%27%20OR%20%271%27=%271'" \
    "Basic SQL injection attempts should be blocked"

run_test "Advanced SQL Injection" "BLOCKED" \
    "curl -s -o /dev/null -w '%{http_code}' -H 'User-Agent: Mozilla/5.0' '$APP_URL/api/users?id=1%20UNION%20SELECT%20*%20FROM%20users'" \
    "Advanced SQL injection attempts should be blocked"

run_test "SQL Injection in POST Body" "BLOCKED" \
    "curl -s -o /dev/null -w '%{http_code}' -H 'User-Agent: Mozilla/5.0' -H 'Content-Type: application/json' -X POST -d '{\"query\":\"SELECT * FROM users WHERE id=1 OR 1=1\"}' '$APP_URL/api/search'" \
    "SQL injection in POST body should be blocked"

# Layer 3: XSS Protection Tests (Should be BLOCKED)
echo "📋 Layer 3: XSS Protection"
echo "-------------------------"

run_test "Basic XSS Attack" "BLOCKED" \
    "curl -s -o /dev/null -w '%{http_code}' -H 'User-Agent: Mozilla/5.0' '$APP_URL/search?q=%3Cscript%3Ealert%28%27xss%27%29%3C/script%3E'" \
    "Basic XSS attacks should be blocked"

run_test "Advanced XSS Attack" "BLOCKED" \
    "curl -s -o /dev/null -w '%{http_code}' -H 'User-Agent: Mozilla/5.0' -X POST -H 'Content-Type: application/x-www-form-urlencoded' -d 'comment=%3Cimg%20src=x%20onerror=alert%281%29%3E' '$APP_URL/comments'" \
    "Advanced XSS attacks should be blocked"

# Layer 4: Path Traversal Tests (Should be BLOCKED)
echo "📋 Layer 4: Path Traversal Protection"
echo "------------------------------------"

run_test "Basic Path Traversal" "BLOCKED" \
    "curl -s -o /dev/null -w '%{http_code}' -H 'User-Agent: Mozilla/5.0' '$APP_URL/../../../etc/passwd'" \
    "Path traversal attempts should be blocked"

run_test "Encoded Path Traversal" "BLOCKED" \
    "curl -s -o /dev/null -w '%{http_code}' -H 'User-Agent: Mozilla/5.0' '$APP_URL/%2e%2e%2f%2e%2e%2f%2e%2e%2fetc%2fpasswd'" \
    "URL-encoded path traversal should be blocked"

# Layer 5: Command Injection Tests (Should be BLOCKED)
echo "📋 Layer 5: Command Injection Protection"
echo "---------------------------------------"

run_test "Command Injection" "BLOCKED" \
    "curl -s -o /dev/null -w '%{http_code}' -H 'User-Agent: Mozilla/5.0' '$APP_URL/api/ping?host=google.com%3Bcat%20/etc/passwd'" \
    "Command injection attempts should be blocked"

# Layer 6: File Upload Protection Tests (Should be BLOCKED)
echo "📋 Layer 6: File Upload Protection"
echo "---------------------------------"

run_test "PHP File Upload" "BLOCKED" \
    "curl -s -o /dev/null -w '%{http_code}' -H 'User-Agent: Mozilla/5.0' '$APP_URL/uploads/shell.php'" \
    "Access to PHP files should be blocked"

run_test "Malicious File Access" "BLOCKED" \
    "curl -s -o /dev/null -w '%{http_code}' -H 'User-Agent: Mozilla/5.0' '$APP_URL/uploads/backdoor.php?cmd=whoami'" \
    "Malicious file execution should be blocked"

# Layer 7: Bot Detection Tests (Should be BLOCKED)
echo "📋 Layer 7: Bot Detection"
echo "------------------------"

run_test "Bot User-Agent" "BLOCKED" \
    "curl -s -o /dev/null -w '%{http_code}' -H 'User-Agent: malicious-bot/1.0' '$APP_URL/'" \
    "Requests with bot User-Agents should be blocked"

run_test "Scanner Detection" "BLOCKED" \
    "curl -s -o /dev/null -w '%{http_code}' -H 'User-Agent: nmap-scanner' '$APP_URL/'" \
    "Security scanner requests should be blocked"

# Layer 8: Admin Panel Protection Tests (Should be BLOCKED)
echo "📋 Layer 8: Admin Panel Protection"
echo "---------------------------------"

run_test "Admin Panel Access" "BLOCKED" \
    "curl -s -o /dev/null -w '%{http_code}' -H 'User-Agent: Mozilla/5.0' '$APP_URL/admin/'" \
    "Admin panel access should be blocked"

run_test "Database Admin Access" "BLOCKED" \
    "curl -s -o /dev/null -w '%{http_code}' -H 'User-Agent: Mozilla/5.0' '$APP_URL/phpmyadmin/'" \
    "Database admin tool access should be blocked"

# Layer 9: Sensitive File Protection Tests (Should be BLOCKED)
echo "📋 Layer 9: Sensitive File Protection"
echo "------------------------------------"

run_test "Backup File Access" "BLOCKED" \
    "curl -s -o /dev/null -w '%{http_code}' -H 'User-Agent: Mozilla/5.0' '$APP_URL/database.sql.bak'" \
    "Backup file access should be blocked"

run_test "Environment File Access" "BLOCKED" \
    "curl -s -o /dev/null -w '%{http_code}' -H 'User-Agent: Mozilla/5.0' '$APP_URL/.env'" \
    "Environment file access should be blocked"

# Layer 10: Data Leakage Protection Tests (Should be BLOCKED)
echo "📋 Layer 10: Data Leakage Protection"
echo "-----------------------------------"

run_test "API Key Exposure" "BLOCKED" \
    "curl -s -o /dev/null -w '%{http_code}' -H 'User-Agent: Mozilla/5.0' '$APP_URL/api/data?api_key=secret123'" \
    "API key exposure should be blocked"

run_test "Password Exposure" "BLOCKED" \
    "curl -s -o /dev/null -w '%{http_code}' -H 'User-Agent: Mozilla/5.0' '$APP_URL/login?username=admin&password=secret123'" \
    "Password exposure should be blocked"

# Layer 11: Large Payload Tests (Should be BLOCKED)
echo "📋 Layer 11: Large Payload Protection"
echo "------------------------------------"

run_test "Large Payload Attack" "BLOCKED" \
    "curl -s -o /dev/null -w '%{http_code}' -H 'User-Agent: Mozilla/5.0' -X POST -H 'Content-Type: application/json' -d '{\"data\":\"$(head -c 3000000 /dev/zero | tr '\0' 'A')\"}' '$APP_URL/api/upload'" \
    "Large payload attacks should be blocked"

# Layer 12: Rate Limiting Tests
echo "📋 Layer 12: Rate Limiting Protection"
echo "------------------------------------"

echo "🧪 Test: Rate Limiting (Making 120 rapid requests)"
echo "   Expected: First requests allowed, then blocked after threshold"
echo "   Command: Making 120 rapid requests..."

allowed_count=0
blocked_count=0
error_count=0

for i in {1..120}; do
    response=$(curl -s -o /dev/null -w '%{http_code}' -H "User-Agent: Mozilla/5.0" "$APP_URL" 2>/dev/null)
    
    case "$response" in
        "200"|"301"|"302") allowed_count=$((allowed_count + 1)) ;;
        "403") blocked_count=$((blocked_count + 1)) ;;
        *) error_count=$((error_count + 1)) ;;
    esac
    
    # Small delay to avoid overwhelming
    sleep 0.05
done

TOTAL_TESTS=$((TOTAL_TESTS + 1))
echo "   Results: $allowed_count allowed, $blocked_count blocked, $error_count errors"

if [ $blocked_count -gt 0 ]; then
    echo "   ✅ PASS: Rate limiting is working ($blocked_count requests blocked)"
    PASSED_TESTS=$((PASSED_TESTS + 1))
elif [ $allowed_count -gt 100 ]; then
    echo "   ⚠️  WARNING: Rate limiting may not be working (all $allowed_count requests allowed)"
    WARNING_TESTS=$((WARNING_TESTS + 1))
else
    echo "   ❓ UNKNOWN: Unexpected rate limiting behavior"
    WARNING_TESTS=$((WARNING_TESTS + 1))
fi
echo ""

# Test Summary
echo "=== Enterprise Security Test Summary ==="
echo ""
echo "📊 Test Results:"
echo "   Total Tests: $TOTAL_TESTS"
echo "   ✅ Passed: $PASSED_TESTS"
echo "   ❌ Failed: $FAILED_TESTS"
echo "   ⚠️  Warnings: $WARNING_TESTS"
echo ""

# Calculate success rate
if [ $TOTAL_TESTS -gt 0 ]; then
    success_rate=$(( (PASSED_TESTS * 100) / TOTAL_TESTS ))
    echo "📈 Success Rate: $success_rate%"
else
    success_rate=0
fi

echo ""
echo "🎯 Security Assessment:"

if [ $success_rate -ge 90 ]; then
    echo "   🟢 EXCELLENT: Enterprise WAF is providing comprehensive security"
elif [ $success_rate -ge 80 ]; then
    echo "   🟡 GOOD: Enterprise WAF is providing good security with minor issues"
elif [ $success_rate -ge 70 ]; then
    echo "   🟠 FAIR: Enterprise WAF needs attention - some security gaps detected"
else
    echo "   🔴 POOR: Enterprise WAF has significant security issues - immediate attention required"
fi

echo ""
echo "📋 Next Steps:"

if [ $FAILED_TESTS -gt 0 ]; then
    echo ""
    echo "🚨 SECURITY ISSUES DETECTED:"
    echo "   • Review failed tests above"
    echo "   • Check WAF rule configuration"
    echo "   • Verify WAF is properly associated with load balancer"
    echo "   • Review CloudWatch WAF logs for details"
    echo ""
    echo "   Immediate Actions:"
    echo "   1. Check WAF association:"
    echo "      aws wafv2 list-web-acls --scope REGIONAL"
    echo "   2. Review WAF logs:"
    echo "      aws logs tail /aws/wafv2/enterprise-secure-waf --follow"
    echo "   3. Check blocked requests:"
    echo "      aws logs filter-log-events --log-group-name /aws/wafv2/enterprise-secure-waf --filter-pattern '{ \$.action = \"BLOCK\" }'"
fi

if [ $WARNING_TESTS -gt 0 ]; then
    echo ""
    echo "⚠️  WARNINGS DETECTED:"
    echo "   • Some tests returned unexpected results"
    echo "   • Monitor application behavior and WAF logs"
    echo "   • Consider adjusting WAF rules if needed"
fi

if [ $success_rate -ge 90 ]; then
    echo ""
    echo "✅ ENTERPRISE WAF VALIDATION SUCCESSFUL"
    echo ""
    echo "🔍 Recommended Monitoring:"
    echo "   • Set up CloudWatch alarms for blocked requests"
    echo "   • Monitor WAF metrics daily"
    echo "   • Review security logs weekly"
    echo "   • Conduct monthly security assessments"
    echo ""
    echo "📊 Monitoring Commands:"
    echo "   terraform output security_monitoring_commands"
fi

echo ""
echo "📚 For detailed analysis:"
echo "   • Review CloudWatch WAF metrics"
echo "   • Analyze WAF logs with CloudWatch Insights"
echo "   • Set up automated security alerting"
echo "   • Create security dashboards"
echo ""
echo "🔗 Additional Resources:"
echo "   • AWS WAF Developer Guide: https://docs.aws.amazon.com/waf/"
echo "   • CloudWatch WAF Metrics: https://docs.aws.amazon.com/waf/latest/developerguide/monitoring-cloudwatch.html"
echo "   • WAF Security Best Practices: https://docs.aws.amazon.com/waf/latest/developerguide/security-best-practices.html"

# Exit with appropriate code
if [ $FAILED_TESTS -gt 0 ]; then
    exit 1
elif [ $WARNING_TESTS -gt 0 ]; then
    exit 2
else
    exit 0
fi