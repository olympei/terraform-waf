#!/bin/bash

# GitLab Module Registry Usage - Validation Test Script
# This script validates the Terraform configuration and module references

set -e

echo "🚀 Starting GitLab Module Registry Usage Validation..."
echo "=================================================="

# Test 1: Terraform Initialization
echo "📦 Test 1: Terraform Initialization"
terraform init -no-color
if [ $? -eq 0 ]; then
    echo "✅ Terraform initialization successful"
else
    echo "❌ Terraform initialization failed"
    exit 1
fi

# Test 2: Configuration Validation
echo ""
echo "🔍 Test 2: Configuration Validation"
terraform validate -no-color
if [ $? -eq 0 ]; then
    echo "✅ Configuration validation successful"
else
    echo "❌ Configuration validation failed"
    exit 1
fi

# Test 3: Format Check
echo ""
echo "📝 Test 3: Format Check"
terraform fmt -check -no-color
if [ $? -eq 0 ]; then
    echo "✅ Code formatting is correct"
else
    echo "⚠️  Code formatting needs adjustment (running terraform fmt)"
    terraform fmt -no-color
    echo "✅ Code formatting fixed"
fi

# Test 4: Module Structure Validation
echo ""
echo "🏗️  Test 4: Module Structure Validation"
echo "Checking module references..."

# Check if all referenced modules exist
modules=("waf" "waf-rule-group" "regex-pattern-set" "ip-set")
for module in "${modules[@]}"; do
    if [ -d "../../modules/$module" ]; then
        echo "✅ Module $module exists"
    else
        echo "❌ Module $module not found"
        exit 1
    fi
done

# Test 5: Dependency Graph Generation
echo ""
echo "🔗 Test 5: Dependency Graph Generation"
terraform graph > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "✅ Dependency graph generation successful"
else
    echo "❌ Dependency graph generation failed"
    exit 1
fi

# Test 6: Variable Validation
echo ""
echo "📋 Test 6: Variable Validation"
if [ -f "terraform.tfvars.json" ]; then
    echo "✅ terraform.tfvars.json exists"
    # Validate JSON syntax
    python -m json.tool terraform.tfvars.json > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "✅ terraform.tfvars.json has valid JSON syntax"
    else
        echo "❌ terraform.tfvars.json has invalid JSON syntax"
        exit 1
    fi
else
    echo "⚠️  terraform.tfvars.json not found (optional)"
fi

echo ""
echo "🎉 All validation tests passed!"
echo "=================================================="
echo "✅ GitLab Module Registry Usage configuration is valid"
echo "✅ All module references are correct"
echo "✅ Configuration is ready for deployment"
echo ""
echo "📝 Next Steps:"
echo "   1. Configure AWS credentials"
echo "   2. Run 'terraform plan' to review changes"
echo "   3. Run 'terraform apply' to deploy resources"
echo ""
echo "🔗 For GitLab Module Registry usage:"
echo "   Update module sources to use GitLab registry URLs"
echo "   Example: git::https://gitlab.com/your-namespace/terraform-waf-modules.git//modules/waf?ref=v1.0.0"