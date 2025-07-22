#!/bin/bash

# Test script for Database Client Access in Zero-Trust WAF
# This script demonstrates how to test the dbclient header functionality

set -e

echo "🧪 Testing Database Client Access in Zero-Trust WAF"
echo "=================================================="

# Configuration
TARGET_URL="${1:-https://your-alb-endpoint.com/api/test}"
echo "Target URL: $TARGET_URL"
echo ""

# Test 1: Request without dbclient header (should be blocked)
echo "Test 1: Request without dbclient header (Expected: BLOCKED)"
echo "-----------------------------------------------------------"
curl -v -X GET "$TARGET_URL" \
  -H "Content-Type: application/json" \
  -w "\nHTTP Status: %{http_code}\n" \
  --connect-timeout 10 \
  --max-time 30 || echo "Request blocked as expected"
echo ""

# Test 2: Request with dbclient in x-client-type header (should be allowed)
echo "Test 2: Request with x-client-type: dbclient (Expected: ALLOWED)"
echo "----------------------------------------------------------------"
curl -v -X GET "$TARGET_URL" \
  -H "x-client-type: dbclient" \
  -H "Content-Type: application/json" \
  -w "\nHTTP Status: %{http_code}\n" \
  --connect-timeout 10 \
  --max-time 30 || echo "Request may have been blocked"
echo ""

# Test 3: Request with dbclient in user-agent header (should be allowed)
echo "Test 3: Request with user-agent containing dbclient (Expected: ALLOWED)"
echo "-----------------------------------------------------------------------"
curl -v -X GET "$TARGET_URL" \
  -H "user-agent: MyApp/1.0 dbclient" \
  -H "Content-Type: application/json" \
  -w "\nHTTP Status: %{http_code}\n" \
  --connect-timeout 10 \
  --max-time 30 || echo "Request may have been blocked"
echo ""

# Test 4: Request with dbclient in x-application header (should be allowed)
echo "Test 4: Request with x-application: dbclient-v2.1 (Expected: ALLOWED)"
echo "---------------------------------------------------------------------"
curl -v -X GET "$TARGET_URL" \
  -H "x-application: dbclient-v2.1" \
  -H "Content-Type: application/json" \
  -w "\nHTTP Status: %{http_code}\n" \
  --connect-timeout 10 \
  --max-time 30 || echo "Request may have been blocked"
echo ""

# Test 5: Request with dbclient in authorization header (should be allowed)
echo "Test 5: Request with authorization containing dbclient (Expected: ALLOWED)"
echo "-------------------------------------------------------------------------"
curl -v -X GET "$TARGET_URL" \
  -H "authorization: Bearer token-dbclient-xyz123" \
  -H "Content-Type: application/json" \
  -w "\nHTTP Status: %{http_code}\n" \
  --connect-timeout 10 \
  --max-time 30 || echo "Request may have been blocked"
echo ""

# Test 6: POST request with dbclient header (should be allowed)
echo "Test 6: POST request with dbclient header (Expected: ALLOWED)"
echo "------------------------------------------------------------"
curl -v -X POST "$TARGET_URL" \
  -H "x-client-type: dbclient" \
  -H "Content-Type: application/json" \
  -d '{"query": "SELECT * FROM users", "client": "dbclient"}' \
  -w "\nHTTP Status: %{http_code}\n" \
  --connect-timeout 10 \
  --max-time 30 || echo "Request may have been blocked"
echo ""

# Test 7: Request from blocked country (should be blocked even with dbclient)
echo "Test 7: Request with dbclient but from blocked country (Expected: BLOCKED)"
echo "-------------------------------------------------------------------------"
echo "Note: This test requires VPN or proxy from a blocked country"
echo "The WAF rule requires BOTH dbclient header AND trusted country"
echo ""

echo "🎯 Test Summary:"
echo "==============="
echo "✅ Requests WITH 'dbclient' in headers from trusted countries should be ALLOWED"
echo "❌ Requests WITHOUT 'dbclient' in headers should be BLOCKED"
echo "❌ Requests from non-trusted countries should be BLOCKED (even with dbclient)"
echo ""
echo "📊 Monitor CloudWatch Logs to verify rule behavior:"
echo "   - allow_dbclient_traffic metric should increment for successful requests"
echo "   - Default block action should catch requests without proper headers"
echo ""
echo "🔧 Troubleshooting:"
echo "   - Ensure ALB is associated with the WAF"
echo "   - Check that your IP is from a trusted country: ${TRUSTED_COUNTRIES:-US,CA,GB,DE,FR,AU,JP,NL,SE,CH}"
echo "   - Verify WAF logging is enabled to see detailed request analysis"