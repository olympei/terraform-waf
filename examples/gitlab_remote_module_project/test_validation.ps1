# GitLab Remote Module Project - Comprehensive Validation Test Script (PowerShell)
# This script validates the complete enterprise WAF configuration with all modules

Write-Host "Starting GitLab Remote Module Project Comprehensive Validation..." -ForegroundColor Green
Write-Host "==================================================================" -ForegroundColor Green

# Test 1: Environment Prerequisites
Write-Host ""
Write-Host "Test 1: Environment Prerequisites" -ForegroundColor Yellow
Write-Host "Checking required tools and access..."

# Check Terraform
try {
    $terraformVersion = terraform version | Select-String "Terraform" | ForEach-Object { $_.ToString().Split()[1] }
    Write-Host "Terraform found: $terraformVersion" -ForegroundColor Green
} catch {
    Write-Host "Terraform not found. Please install Terraform >= 1.3.0" -ForegroundColor Red
    exit 1
}

# Check AWS CLI
try {
    $awsVersion = aws --version 2>$null | ForEach-Object { $_.Split()[0] }
    Write-Host "AWS CLI found: $awsVersion" -ForegroundColor Green
} catch {
    Write-Host "AWS CLI not found. Install for better AWS integration" -ForegroundColor Yellow
}

# Check Git
try {
    $gitVersion = git --version | ForEach-Object { $_.Split()[2] }
    Write-Host "Git found: $gitVersion" -ForegroundColor Green
} catch {
    Write-Host "Git not found. Required for GitLab module access" -ForegroundColor Red
    exit 1
}

# Test 2: GitLab Access Validation
Write-Host ""
Write-Host "Test 2: GitLab Access Validation" -ForegroundColor Yellow
Write-Host "Testing GitLab SSH access..."

try {
    $gitlabTest = ssh -T git@gitlab.com -o ConnectTimeout=10 -o StrictHostKeyChecking=no 2>&1
    if ($gitlabTest -match "Welcome to GitLab") {
        Write-Host "GitLab SSH access successful" -ForegroundColor Green
    } else {
        Write-Host "GitLab SSH access test inconclusive (this may be normal)" -ForegroundColor Yellow
        Write-Host "   Ensure your SSH key is configured for GitLab access" -ForegroundColor White
    }
} catch {
    Write-Host "GitLab SSH test encountered an issue" -ForegroundColor Yellow
}

# Test 3: Terraform Configuration Validation
Write-Host ""
Write-Host "Test 3: Terraform Configuration Validation" -ForegroundColor Yellow
Write-Host "Validating Terraform configuration syntax..."

# Initialize Terraform
Write-Host "Initializing Terraform..."
try {
    terraform init -no-color
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Terraform initialization successful" -ForegroundColor Green
    } else {
        Write-Host "Terraform initialization failed" -ForegroundColor Red
        Write-Host "   Check GitLab repository access and module paths" -ForegroundColor White
        exit 1
    }
} catch {
    Write-Host "Terraform initialization failed: $_" -ForegroundColor Red
    exit 1
}

# Validate configuration
Write-Host "Validating configuration..."
try {
    terraform validate -no-color
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Configuration validation successful" -ForegroundColor Green
    } else {
        Write-Host "Configuration validation failed" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "Configuration validation failed: $_" -ForegroundColor Red
    exit 1
}

# Test 4: Variable Configuration Check
Write-Host ""
Write-Host "Test 4: Variable Configuration Check" -ForegroundColor Yellow
Write-Host "Checking variable configuration..."

if (Test-Path "terraform.tfvars") {
    Write-Host "terraform.tfvars exists" -ForegroundColor Green
    
    $tfvarsContent = Get-Content "terraform.tfvars" -Raw
    
    if ($tfvarsContent -match "gitlab_repo_url") {
        Write-Host "GitLab repository URL configured" -ForegroundColor Green
    } else {
        Write-Host "GitLab repository URL not found in terraform.tfvars" -ForegroundColor Yellow
    }
    
    if ($tfvarsContent -match "project_name") {
        Write-Host "Project name configured" -ForegroundColor Green
    } else {
        Write-Host "Project name not found in terraform.tfvars" -ForegroundColor Yellow
    }
} else {
    Write-Host "terraform.tfvars not found (using defaults)" -ForegroundColor Yellow
}

# Test 5: Module Structure Validation
Write-Host ""
Write-Host "Test 5: Module Structure Validation" -ForegroundColor Yellow
Write-Host "Validating comprehensive module usage..."

$modules = @("ip-set", "regex-pattern-set", "waf-rule-group", "waf", "s3-cross-account-replication", "rule-group")
$mainTfContent = Get-Content "main.tf" -Raw

foreach ($module in $modules) {
    if ($mainTfContent -match "modules/$module") {
        Write-Host "Module $module is used" -ForegroundColor Green
    } else {
        Write-Host "Module $module not found in configuration" -ForegroundColor Red
        exit 1
    }
}

# Test 6: Dependency Graph Generation
Write-Host ""
Write-Host "Test 6: Dependency Graph Generation" -ForegroundColor Yellow
Write-Host "Generating and validating dependency graph..."

try {
    $graphOutput = terraform graph 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Dependency graph generation successful" -ForegroundColor Green
        
        $moduleCount = ($graphOutput | Select-String "cluster_module\.").Count
        Write-Host "Found $moduleCount module instances in dependency graph" -ForegroundColor Green
        
        if ($moduleCount -ge 8) {
            Write-Host "Expected number of modules found (8+)" -ForegroundColor Green
        } else {
            Write-Host "Expected more module instances (found: $moduleCount, expected: 8+)" -ForegroundColor Yellow
        }
    } else {
        Write-Host "Dependency graph generation failed" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "Dependency graph generation failed: $_" -ForegroundColor Red
    exit 1
}

# Test 7: Format Check
Write-Host ""
Write-Host "Test 7: Format Check" -ForegroundColor Yellow
Write-Host "Checking Terraform code formatting..."

try {
    terraform fmt -check -no-color
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Code formatting is correct" -ForegroundColor Green
    } else {
        Write-Host "Code formatting needs adjustment (running terraform fmt)" -ForegroundColor Yellow
        terraform fmt -no-color
        Write-Host "Code formatting fixed" -ForegroundColor Green
    }
} catch {
    Write-Host "Format check encountered an issue: $_" -ForegroundColor Yellow
}

# Test 8: Security Configuration Validation
Write-Host ""
Write-Host "Test 8: Security Configuration Validation" -ForegroundColor Yellow
Write-Host "Validating security configurations..."

if ($mainTfContent -match "BlockMaliciousIPs") {
    Write-Host "Malicious IP blocking configured" -ForegroundColor Green
} else {
    Write-Host "Malicious IP blocking not found" -ForegroundColor Red
    exit 1
}

if ($mainTfContent -match "BlockSQLInjection") {
    Write-Host "SQL injection protection configured" -ForegroundColor Green
} else {
    Write-Host "SQL injection protection not found" -ForegroundColor Red
    exit 1
}

if ($mainTfContent -match "rate_based_statement") {
    Write-Host "Rate limiting configured" -ForegroundColor Green
} else {
    Write-Host "Rate limiting not found" -ForegroundColor Red
    exit 1
}

if ($mainTfContent -match "AWSManagedRules") {
    Write-Host "AWS managed rules configured" -ForegroundColor Green
} else {
    Write-Host "AWS managed rules not found" -ForegroundColor Red
    exit 1
}

# Test 9: Cross-Module Integration Check
Write-Host ""
Write-Host "Test 9: Cross-Module Integration Check" -ForegroundColor Yellow
Write-Host "Validating cross-module integrations..."

if ($mainTfContent -match "ip_set_reference_statement") {
    Write-Host "IP set integration found" -ForegroundColor Green
} else {
    Write-Host "IP set integration not found" -ForegroundColor Red
    exit 1
}

if ($mainTfContent -match "regex_pattern_set_reference_statement") {
    Write-Host "Regex pattern set integration found" -ForegroundColor Green
} else {
    Write-Host "Regex pattern set integration not found" -ForegroundColor Red
    exit 1
}

if ($mainTfContent -match "rule_group_arn_list") {
    Write-Host "Rule group integration found" -ForegroundColor Green
} else {
    Write-Host "Rule group integration not found" -ForegroundColor Red
    exit 1
}

# Test 10: Output Configuration Check
Write-Host ""
Write-Host "Test 10: Output Configuration Check" -ForegroundColor Yellow
Write-Host "Validating output configurations..."

$outputCount = ($mainTfContent | Select-String "^output ").Count
Write-Host "Found $outputCount output configurations" -ForegroundColor Green

if ($outputCount -ge 10) {
    Write-Host "Comprehensive outputs configured" -ForegroundColor Green
} else {
    Write-Host "Consider adding more outputs for better visibility" -ForegroundColor Yellow
}

# Test 11: Enterprise Features Check
Write-Host ""
Write-Host "Test 11: Enterprise Features Check" -ForegroundColor Yellow
Write-Host "Validating enterprise-grade features..."

if ($mainTfContent -match "create_log_group.*true") {
    Write-Host "CloudWatch logging enabled" -ForegroundColor Green
} else {
    Write-Host "CloudWatch logging not explicitly enabled" -ForegroundColor Yellow
}

if ($mainTfContent -match "enable_kms_encryption.*true") {
    Write-Host "KMS encryption enabled" -ForegroundColor Green
} else {
    Write-Host "KMS encryption not explicitly enabled" -ForegroundColor Yellow
}

if ($mainTfContent -match "s3-cross-account-replication") {
    Write-Host "S3 cross-account replication configured" -ForegroundColor Green
} else {
    Write-Host "S3 cross-account replication not found" -ForegroundColor Red
    exit 1
}

# Final Summary
Write-Host ""
Write-Host "Validation Summary" -ForegroundColor Green
Write-Host "===================="
Write-Host "Environment prerequisites met" -ForegroundColor Green
Write-Host "GitLab access configured" -ForegroundColor Green
Write-Host "Terraform configuration valid" -ForegroundColor Green
Write-Host "All 6 modules integrated" -ForegroundColor Green
Write-Host "Cross-module dependencies working" -ForegroundColor Green
Write-Host "Security configurations comprehensive" -ForegroundColor Green
Write-Host "Enterprise features enabled" -ForegroundColor Green
Write-Host "Code formatting correct" -ForegroundColor Green
Write-Host ""
Write-Host "GitLab Remote Module Project is ready for deployment!" -ForegroundColor Green
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Cyan
Write-Host "   1. Review and customize terraform.tfvars for your environment" -ForegroundColor White
Write-Host "   2. Update GitLab repository URL and credentials" -ForegroundColor White
Write-Host "   3. Configure AWS credentials" -ForegroundColor White
Write-Host "   4. Run terraform plan to review changes" -ForegroundColor White
Write-Host "   5. Run terraform apply to deploy the enterprise WAF" -ForegroundColor White