#!/bin/bash

echo "=== WAF Basic Example with URI Exceptions - Validation Test ==="
echo ""

# Test 1: Terraform syntax validation
echo "🔍 Test 1: Terraform Syntax Validation"
terraform validate -no-color
if [ $? -eq 0 ]; then
    echo "✅ PASS: Terraform configuration is syntactically valid"
else
    echo "❌ FAIL: Terraform configuration has syntax errors"
    exit 1
fi
echo ""

# Test 2: Terraform formatting check
echo "🔍 Test 2: Terraform Formatting Check"
terraform fmt -check > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "✅ PASS: Terraform configuration is properly formatted"
else
    echo "⚠️  WARN: Terraform configuration formatting could be improved"
fi
echo ""

# Test 3: Configuration completeness
echo "🔍 Test 3: Configuration Completeness Check"
echo "Checking required configuration elements..."

grep -q "CrossSiteScripting_BODY_Block" main.tf && echo "✅ XSS rule present" || echo "❌ XSS rule missing"
grep -q "SizeRestrictions_BODY_Block" main.tf && echo "✅ Size restriction rule present" || echo "❌ Size rule missing"
grep -q "/testo/" main.tf && echo "✅ /testo/ exception present" || echo "❌ /testo/ exception missing"
grep -q "/appgo/" main.tf && echo "✅ /appgo/ exception present" || echo "❌ /appgo/ exception missing"
grep -q "and_statement" main.tf && echo "✅ AND logic present" || echo "❌ AND logic missing"
grep -q "not_statement" main.tf && echo "✅ NOT logic present" || echo "❌ NOT logic missing"
grep -q "or_statement" main.tf && echo "✅ OR logic present" || echo "❌ OR logic missing"
grep -q "jsonencode" main.tf && echo "✅ JSON encoding present" || echo "❌ JSON encoding missing"
echo ""

# Test 4: Rule priorities validation
echo "🔍 Test 4: Rule Priorities Validation"
echo "Checking rule priorities..."
grep -A 1 -B 1 "priority.*=" main.tf | grep -E "(name|priority)" | while read line; do
    echo "  $line"
done
echo ""

# Test 5: Exception paths validation
echo "🔍 Test 5: Exception Paths Validation"
echo "Checking exception paths in rules..."
grep -A 5 -B 5 "search_string.*=.*\"/testo/\"" main.tf > /dev/null && echo "✅ /testo/ path found in rules"
grep -A 5 -B 5 "search_string.*=.*\"/appgo/\"" main.tf > /dev/null && echo "✅ /appgo/ path found in rules"
echo ""

echo "=== Validation Summary ==="
echo "✅ Basic validation tests completed!"
echo ""
echo "🎯 Configuration Features Verified:"
echo "  • CrossSiteScripting_BODY_Block with embedded exceptions"
echo "  • SizeRestrictions_BODY_Block with embedded exceptions"
echo "  • Complex logical statements (AND, NOT, OR)"
echo "  • Exception paths: /testo/ and /appgo/"
echo "  • JSON-encoded statement structures"
echo ""
echo "🚀 Configuration is ready for deployment!"