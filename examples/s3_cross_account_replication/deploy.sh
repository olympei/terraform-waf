#!/bin/bash

# S3 Cross-Account Replication Deployment Script
# This script helps deploy the S3 cross-account replication infrastructure

set -e

echo "🚀 S3 Cross-Account Replication Deployment"
echo "=========================================="

# Check if terraform.tfvars exists
if [ ! -f "terraform.tfvars" ]; then
    echo "❌ terraform.tfvars not found!"
    echo "📝 Please copy terraform.tfvars.example to terraform.tfvars and update with your values"
    echo "   cp terraform.tfvars.example terraform.tfvars"
    exit 1
fi

# Check if Terraform is installed
if ! command -v terraform &> /dev/null; then
    echo "❌ Terraform is not installed!"
    echo "📥 Please install Terraform: https://www.terraform.io/downloads.html"
    exit 1
fi

# Initialize Terraform
echo "🔧 Initializing Terraform..."
terraform init

# Validate configuration
echo "✅ Validating Terraform configuration..."
terraform validate

# Plan deployment
echo "📋 Creating deployment plan..."
terraform plan -out=tfplan

# Ask for confirmation
echo ""
read -p "🤔 Do you want to apply this plan? (y/N): " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "🚀 Applying Terraform configuration..."
    terraform apply tfplan
    
    echo ""
    echo "✅ Deployment completed successfully!"
    echo "📊 You can now check the outputs:"
    terraform output
    
    echo ""
    echo "🔍 Next steps:"
    echo "1. Test replication by uploading a file to the source bucket"
    echo "2. Check the destination bucket for the replicated object"
    echo "3. Monitor replication metrics in CloudWatch"
else
    echo "❌ Deployment cancelled"
    rm -f tfplan
fi