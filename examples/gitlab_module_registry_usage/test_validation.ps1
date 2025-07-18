# GitLab Module Registry Usage - Validation Test Script (PowerShell)
# This script validates the Terraform configuration and module references

Write-Host "Starting GitLab Module Registry Usage Validation..." -ForegroundColor Green
Write-Host "==================================================" -ForegroundColor Green

# Test 1: Terraform Initialization
Write-Host ""
Write-Host "Test 1: Terraform Initialization" -ForegroundColor Yellow
try {
    terraform init -no-color
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Terraform initialization successful" -ForegroundColor Green
    } else {
        Write-Host "Terraform initialization failed" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "Terraform initialization failed: $_" -ForegroundColor Red
    exit 1
}

# Test 2: Configuration Validation
Write-Host ""
Write-Host "Test 2: Configuration Validation" -ForegroundColor Yellow
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

# Test 3: Format Check
Write-Host ""
Write-Host "Test 3: Format Check" -ForegroundColor Yellow
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

# Test 4: Module Structure Validation
Write-Host ""
Write-Host "Test 4: Module Structure Validation" -ForegroundColor Yellow
Write-Host "Checking module references..."

$modules = @("waf", "waf-rule-group", "regex-pattern-set", "ip-set")
foreach ($module in $modules) {
    $modulePath = "..\..\modules\$module"
    if (Test-Path $modulePath -PathType Container) {
        Write-Host "Module $module exists" -ForegroundColor Green
    } else {
        Write-Host "Module $module not found" -ForegroundColor Red
        exit 1
    }
}

# Test 5: Dependency Graph Generation
Write-Host ""
Write-Host "Test 5: Dependency Graph Generation" -ForegroundColor Yellow
try {
    terraform graph | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Dependency graph generation successful" -ForegroundColor Green
    } else {
        Write-Host "Dependency graph generation failed" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "Dependency graph generation failed: $_" -ForegroundColor Red
    exit 1
}

# Test 6: Variable Validation
Write-Host ""
Write-Host "Test 6: Variable Validation" -ForegroundColor Yellow
if (Test-Path "terraform.tfvars.json") {
    Write-Host "terraform.tfvars.json exists" -ForegroundColor Green
    try {
        $jsonContent = Get-Content "terraform.tfvars.json" -Raw | ConvertFrom-Json
        Write-Host "terraform.tfvars.json has valid JSON syntax" -ForegroundColor Green
    } catch {
        Write-Host "terraform.tfvars.json has invalid JSON syntax" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "terraform.tfvars.json not found (optional)" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "All validation tests passed!" -ForegroundColor Green
Write-Host "==================================================" -ForegroundColor Green
Write-Host "GitLab Module Registry Usage configuration is valid" -ForegroundColor Green
Write-Host "All module references are correct" -ForegroundColor Green
Write-Host "Configuration is ready for deployment" -ForegroundColor Green
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Cyan
Write-Host "   1. Configure AWS credentials" -ForegroundColor White
Write-Host "   2. Run terraform plan to review changes" -ForegroundColor White
Write-Host "   3. Run terraform apply to deploy resources" -ForegroundColor White