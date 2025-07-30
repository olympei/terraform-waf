#!/bin/bash

# Test script for Basic WAF rules
# This script helps verify that the XSS and Size Restriction rules are properly configured

set -e

echo "🧪 Basic WAF Rules Test Script"
echo "=============================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if terraform is available
if ! command -v terraform &> /dev/null; then
    echo -e "${RED}❌ Terraform is not installed or not in PATH${NC}"
    exit 1
fi

# Check if AWS CLI is available
if ! command -v aws &> /dev/null; then
    echo -e "${YELLOW}⚠️  AWS CLI is not installed. Some tests will be skipped.${NC}"
    AWS_CLI_AVAILABLE=false
else
    AWS_CLI_AVAILABLE=true
fi

echo -e "${GREEN}✅ Prerequisites check passed${NC}"
echo ""

# Test 1: Terraform Configuration Validation
echo "🔍 Test 1: Terraform Configuration Validation"
echo "---------------------------------------------"

if terraform validate; then
    echo -e "${GREEN}✅ Terraform configuration is valid${NC}"
else
    echo -e "${RED}❌ Terraform configuration validation failed${NC}"
    exit 1
fi
echo ""

# Test 2: Terraform Plan (without applying)
echo "🔍 Test 2: Terraform Plan Generation"
echo "------------------------------------"

if terraform plan -out=test.tfplan > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Terraform plan generated successfully${NC}"
    
    # Check if the plan contains our custom rules
    if terraform show -json test.tfplan | jq -r '.planned_values.root_module.resources[].values.rule[]?.name' 2>/dev/null | grep -q "CrossSiteScripting_BODY"; then
        echo -e "${GREEN}✅ CrossSiteScripting_BODY rule found in plan${NC}"
    else
        echo -e "${RED}❌ CrossSiteScripting_BODY rule not found in plan${NC}"
    fi
    
    if terraform show -json test.tfplan | jq -r '.planned_values.root_module.resources[].values.rule[]?.name' 2>/dev/null | grep -q "SizeRestrictions_BODY"; then
        echo -e "${GREEN}✅ SizeRestrictions_BODY rule found in plan${NC}"
    else
        echo -e "${RED}❌ SizeRestrictions_BODY rule not found in plan${NC}"
    fi
    
    # Clean up plan file
    rm -f test.tfplan
else
    echo -e "${RED}❌ Terraform plan generation failed${NC}"
    exit 1
fi
echo ""

# Test 3: Rule Configuration Verification
echo "🔍 Test 3: Rule Configuration Verification"
echo "------------------------------------------"

# Check XSS rule configuration
echo "Checking CrossSiteScripting_BODY rule configuration:"
if grep -q "CrossSiteScripting_BODY" main.tf; then
    echo -e "${GREEN}✅ Rule name found${NC}"
    
    if grep -A 20 "CrossSiteScripting_BODY" main.tf | grep -q "xss_match_statement"; then
        echo -e "${GREEN}✅ XSS match statement configured${NC}"
    else
        echo -e "${RED}❌ XSS match statement not found${NC}"
    fi
    
    if grep -A 20 "CrossSiteScripting_BODY" main.tf | grep -q "body = {}"; then
        echo -e "${GREEN}✅ Body field inspection configured${NC}"
    else
        echo -e "${RED}❌ Body field inspection not configured${NC}"
    fi
    
    if grep -A 20 "CrossSiteScripting_BODY" main.tf | grep -q "HTML_ENTITY_DECODE"; then
        echo -e "${GREEN}✅ HTML entity decode transformation configured${NC}"
    else
        echo -e "${RED}❌ HTML entity decode transformation not configured${NC}"
    fi
else
    echo -e "${RED}❌ CrossSiteScripting_BODY rule not found${NC}"
fi

echo ""
echo "Checking SizeRestrictions_BODY rule configuration:"
if grep -q "SizeRestrictions_BODY" main.tf; then
    echo -e "${GREEN}✅ Rule name found${NC}"
    
    if grep -A 20 "SizeRestrictions_BODY" main.tf | grep -q "size_constraint_statement"; then
        echo -e "${GREEN}✅ Size constraint statement configured${NC}"
    else
        echo -e "${RED}❌ Size constraint statement not found${NC}"
    fi
    
    if grep -A 20 "SizeRestrictions_BODY" main.tf | grep -q "8192"; then
        echo -e "${GREEN}✅ 8KB size limit configured${NC}"
    else
        echo -e "${RED}❌ 8KB size limit not configured${NC}"
    fi
    
    if grep -A 20 "SizeRestrictions_BODY" main.tf | grep -q "GT"; then
        echo -e "${GREEN}✅ Greater than comparison configured${NC}"
    else
        echo -e "${RED}❌ Greater than comparison not configured${NC}"
    fi
else
    echo -e "${RED}❌ SizeRestrictions_BODY rule not found${NC}"
fi
echo ""

# Test 4: Priority Configuration
echo "🔍 Test 4: Rule Priority Configuration"
echo "-------------------------------------"

XSS_PRIORITY=$(grep -A 5 "CrossSiteScripting_BODY" main.tf | grep "priority" | grep -o '[0-9]\+' || echo "not_found")
SIZE_PRIORITY=$(grep -A 5 "SizeRestrictions_BODY" main.tf | grep "priority" | grep -o '[0-9]\+' || echo "not_found")

if [ "$XSS_PRIORITY" = "300" ]; then
    echo -e "${GREEN}✅ CrossSiteScripting_BODY priority is 300${NC}"
else
    echo -e "${RED}❌ CrossSiteScripting_BODY priority is not 300 (found: $XSS_PRIORITY)${NC}"
fi

if [ "$SIZE_PRIORITY" = "301" ]; then
    echo -e "${GREEN}✅ SizeRestrictions_BODY priority is 301${NC}"
else
    echo -e "${RED}❌ SizeRestrictions_BODY priority is not 301 (found: $SIZE_PRIORITY)${NC}"
fi
echo ""

# Test 5: Output Configuration
echo "🔍 Test 5: Output Configuration"
echo "------------------------------"

if grep -q "custom_rules_details" main.tf; then
    echo -e "${GREEN}✅ Custom rules details output configured${NC}"
else
    echo -e "${RED}❌ Custom rules details output not configured${NC}"
fi

if grep -q "basic_waf_summary" main.tf; then
    echo -e "${GREEN}✅ Basic WAF summary output configured${NC}"
else
    echo -e "${RED}❌ Basic WAF summary output not configured${NC}"
fi
echo ""

# Test 6: Documentation Check
echo "🔍 Test 6: Documentation Check"
echo "------------------------------"

if [ -f "README.md" ]; then
    echo -e "${GREEN}✅ README.md exists${NC}"
    
    if grep -q "CrossSiteScripting_BODY" README.md; then
        echo -e "${GREEN}✅ XSS rule documented${NC}"
    else
        echo -e "${RED}❌ XSS rule not documented${NC}"
    fi
    
    if grep -q "SizeRestrictions_BODY" README.md; then
        echo -e "${GREEN}✅ Size restriction rule documented${NC}"
    else
        echo -e "${RED}❌ Size restriction rule not documented${NC}"
    fi
else
    echo -e "${RED}❌ README.md not found${NC}"
fi
echo ""

# Summary
echo "📋 Test Summary"
echo "==============="
echo -e "${GREEN}✅ All configuration tests completed${NC}"
echo ""
echo "🚀 Next Steps:"
echo "1. Review the configuration in main.tf"
echo "2. Customize variables in terraform.tfvars if needed"
echo "3. Run 'terraform plan' to see what will be created"
echo "4. Run 'terraform apply' to deploy the WAF"
echo "5. Test the rules with actual HTTP requests"
echo ""
echo "📚 For more information, see README.md"

# Optional: If deployed, test actual WAF
if [ "$AWS_CLI_AVAILABLE" = true ] && [ -n "${WAF_NAME:-}" ]; then
    echo ""
    echo "🔍 Optional: Live WAF Testing"
    echo "----------------------------"
    echo "To test the deployed WAF rules, set WAF_NAME environment variable:"
    echo "export WAF_NAME=your-waf-name"
    echo ""
    echo "Then run this script again to perform live tests."
fi