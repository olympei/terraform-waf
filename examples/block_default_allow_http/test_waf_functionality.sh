#!/bin/bash

# WAF Functionality Testing Script
# Run this script AFTER deploying the WAF to test if it's working correctly
# Usage: ./test_waf_functionality.sh https://your-application.com

if [ $# -eq 0 ]; then
    echo "Usage: $0 <your-application-url>"
    echo "Example: $0 https://my-app.example.com"
    exit 1
fi

APP_URL="$1"
echo "=== WAF Functionality Testing ==="
echo "Testing WAF configuration for: $APP_URL"
echo ""

# Test 1: Legitimate request (should be ALLOWED)
echo "🧪 Test 1: Legitimate browser request (should be ALLOWED)"
echo "Command: curl -s -o /dev/null -w '%{http_code}' -H 'User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36' -H 'Accept: text/html' '$APP_URL'"

response=$(curl -s -o /dev/null -w '%{http_code}' \
  -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36" \
  -H "Accept: text/html" \
  "$APP_URL")

if [ "$response" = "200" ] || [ "$response" = "301" ] || [ "$response" = "302" ]; then
    echo "✅ PASS: Legitimate request allowed (HTTP $response)"
else
    echo "❌ FAIL: Legitimate request blocked or error (HTTP $response)"
    echo "   This might indicate the WAF is blocking legitimate traffic!"
fi
echo ""

# Test 2: Request without User-Agent (should be BLOCKED)
echo "🧪 Test 2: Request without User-Agent (should be BLOCKED)"
echo "Command: curl -s -o /dev/null -w '%{http_code}' '$APP_URL'"

response=$(curl -s -o /dev/null -w '%{http_code}' "$APP_URL")

if [ "$response" = "403" ]; then
    echo "✅ PASS: Request without User-Agent blocked (HTTP $response)"
elif [ "$response" = "200" ] || [ "$response" = "301" ] || [ "$response" = "302" ]; then
    echo "⚠️  WARNING: Request without User-Agent was allowed (HTTP $response)"
    echo "   The WAF might not be properly configured or associated"
else
    echo "❓ UNKNOWN: Unexpected response (HTTP $response)"
fi
echo ""

# Test 3: Suspicious path traversal (should be BLOCKED)
echo "🧪 Test 3: Path traversal attack (should be BLOCKED)"
echo "Command: curl -s -o /dev/null -w '%{http_code}' -H 'User-Agent: Mozilla/5.0' '$APP_URL/../etc/passwd'"

response=$(curl -s -o /dev/null -w '%{http_code}' \
  -H "User-Agent: Mozilla/5.0" \
  "$APP_URL/../etc/passwd")

if [ "$response" = "403" ]; then
    echo "✅ PASS: Path traversal attack blocked (HTTP $response)"
elif [ "$response" = "404" ]; then
    echo "⚠️  INFO: Path traversal returned 404 (might be blocked by app, not WAF)"
elif [ "$response" = "200" ]; then
    echo "❌ FAIL: Path traversal attack was allowed (HTTP $response)"
    echo "   This is a security concern!"
else
    echo "❓ INFO: Path traversal response (HTTP $response)"
fi
echo ""

# Test 4: JSON API request (should be ALLOWED)
echo "🧪 Test 4: JSON API request (should be ALLOWED)"
echo "Command: curl -s -o /dev/null -w '%{http_code}' -H 'User-Agent: Mozilla/5.0' -H 'Content-Type: application/json' -X POST '$APP_URL/api'"

response=$(curl -s -o /dev/null -w '%{http_code}' \
  -H "User-Agent: Mozilla/5.0" \
  -H "Content-Type: application/json" \
  -X POST \
  "$APP_URL/api" 2>/dev/null)

if [ "$response" = "200" ] || [ "$response" = "404" ] || [ "$response" = "405" ]; then
    echo "✅ PASS: JSON API request allowed (HTTP $response)"
    if [ "$response" = "404" ]; then
        echo "   Note: 404 means WAF allowed it, but endpoint doesn't exist"
    fi
    if [ "$response" = "405" ]; then
        echo "   Note: 405 means WAF allowed it, but method not allowed by app"
    fi
elif [ "$response" = "403" ]; then
    echo "❌ FAIL: JSON API request blocked (HTTP $response)"
    echo "   This might indicate the WAF is blocking legitimate API traffic!"
else
    echo "❓ INFO: JSON API request response (HTTP $response)"
fi
echo ""

# Test 5: Unusual HTTP method (should be BLOCKED)
echo "🧪 Test 5: Unusual HTTP method TRACE (should be BLOCKED)"
echo "Command: curl -s -o /dev/null -w '%{http_code}' -H 'User-Agent: Mozilla/5.0' -X TRACE '$APP_URL'"

response=$(curl -s -o /dev/null -w '%{http_code}' \
  -H "User-Agent: Mozilla/5.0" \
  -X TRACE \
  "$APP_URL" 2>/dev/null)

if [ "$response" = "403" ]; then
    echo "✅ PASS: TRACE method blocked (HTTP $response)"
elif [ "$response" = "405" ]; then
    echo "⚠️  INFO: TRACE method returned 405 (blocked by app, not WAF)"
elif [ "$response" = "200" ]; then
    echo "❌ FAIL: TRACE method was allowed (HTTP $response)"
    echo "   This might be a security concern!"
else
    echo "❓ INFO: TRACE method response (HTTP $response)"
fi
echo ""

# Test 6: Rate limiting test (basic check)
echo "🧪 Test 6: Basic rate limiting test (10 rapid requests)"
echo "Command: Making 10 rapid requests to test rate limiting..."

blocked_count=0
allowed_count=0

for i in {1..10}; do
    response=$(curl -s -o /dev/null -w '%{http_code}' \
      -H "User-Agent: Mozilla/5.0" \
      "$APP_URL" 2>/dev/null)
    
    if [ "$response" = "403" ]; then
        ((blocked_count++))
    elif [ "$response" = "200" ] || [ "$response" = "301" ] || [ "$response" = "302" ]; then
        ((allowed_count++))
    fi
    
    # Small delay to avoid overwhelming
    sleep 0.1
done

echo "   Results: $allowed_count allowed, $blocked_count blocked"
if [ $allowed_count -gt 0 ]; then
    echo "✅ INFO: Rate limiting allows normal traffic"
else
    echo "⚠️  WARNING: All requests blocked - check WAF configuration"
fi
echo ""

# Summary
echo "=== Test Summary ==="
echo ""
echo "🎯 Expected Results for Properly Configured WAF:"
echo "   • Test 1 (Legitimate request): ✅ ALLOWED (200/301/302)"
echo "   • Test 2 (No User-Agent): ✅ BLOCKED (403)"
echo "   • Test 3 (Path traversal): ✅ BLOCKED (403)"
echo "   • Test 4 (JSON API): ✅ ALLOWED (200/404/405)"
echo "   • Test 5 (TRACE method): ✅ BLOCKED (403)"
echo "   • Test 6 (Rate limiting): ✅ Normal traffic allowed"
echo ""
echo "📊 Next Steps:"
echo ""
echo "If tests show unexpected results:"
echo "1. Check WAF association with your load balancer/CloudFront"
echo "2. Review CloudWatch WAF metrics:"
echo "   aws cloudwatch get-metric-statistics \\"
echo "     --namespace AWS/WAFV2 \\"
echo "     --metric-name BlockedRequests \\"
echo "     --dimensions Name=WebACL,Value=block-default-allow-http-waf"
echo ""
echo "3. Check WAF sampled requests:"
echo "   aws wafv2 get-sampled-requests \\"
echo "     --web-acl-arn <your-waf-arn> \\"
echo "     --rule-metric-name AllowLegitimateUserAgents \\"
echo "     --scope REGIONAL \\"
echo "     --time-window StartTime=<start>,EndTime=<end> \\"
echo "     --max-items 100"
echo ""
echo "4. If legitimate traffic is blocked, consider:"
echo "   • Expanding allowed countries list"
echo "   • Adjusting User-Agent matching patterns"
echo "   • Adding more content-type allow rules"
echo "   • Using count mode initially for testing"
echo ""
echo "⚠️  Remember: This WAF uses DEFAULT BLOCK mode"
echo "   All traffic is blocked unless explicitly allowed!"
echo ""
echo "For more detailed testing, monitor your application logs"
echo "and CloudWatch WAF metrics during normal user activity."