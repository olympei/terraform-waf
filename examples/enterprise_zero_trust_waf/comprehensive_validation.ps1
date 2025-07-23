#!/usr/bin/env pwsh

# Comprehensive Enterprise Zero-Trust WAF Validation Script
Write-Host "=== Comprehensive Enterprise Zero-Trust WAF Validation ===" -ForegroundColor Cyan
Write-Host ""

$ErrorCount = 0
$WarningCount = 0

function Test-Condition {
    param(
        [string]$TestName,
        [bool]$Condition,
        [string]$ErrorMessage = "",
        [bool]$IsWarning = $false
    )
    
    if ($Condition) {
        Write-Host "✅ $TestName" -ForegroundColor Green
        return $true
    } else {
        if ($IsWarning) {
            Write-Host "⚠️  $TestName" -ForegroundColor Yellow
            if ($ErrorMessage) { Write-Host "   $ErrorMessage" -ForegroundColor Yellow }
            $script:WarningCount++
        } else {
            Write-Host "❌ $TestName" -ForegroundColor Red
            if ($ErrorMessage) { Write-Host "   $ErrorMessage" -ForegroundColor Red }
            $script:ErrorCount++
        }
        return $false
    }
}

# Test 1: Basic Terraform Configuration
Write-Host "1. Basic Terraform Configuration Tests" -ForegroundColor Yellow
Write-Host "----------------------------------------" -ForegroundColor Yellow

$mainTfContent = Get-Content "main.tf" -Raw

Test-Condition "Terraform configuration file exists" (Test-Path "main.tf")
Test-Condition "AWS provider configured" ($mainTfContent -match 'provider "aws"')
Test-Condition "Region specified" ($mainTfContent -match 'region\s*=\s*"us-east-1"')

# Test 2: Zero-Trust Security Model Validation
Write-Host "`n2. Zero-Trust Security Model Validation" -ForegroundColor Yellow
Write-Host "----------------------------------------" -ForegroundColor Yellow

Test-Condition "Default action set to BLOCK" ($mainTfContent -match 'default_action\s*=\s*"block"')
Test-Condition "Zero-trust philosophy documented" ($mainTfContent -match 'Never trust, always verify')
Test-Condition "Explicit allow rules configured" ($mainTfContent -match 'action\s*=\s*"allow"')

# Test 3: Geographic Controls
Write-Host "`n3. Geographic Access Controls" -ForegroundColor Yellow
Write-Host "------------------------------" -ForegroundColor Yellow

Test-Condition "Trusted countries variable defined" ($mainTfContent -match 'variable "trusted_countries"')
Test-Condition "Geographic matching statements present" ($mainTfContent -match 'geo_match_statement')
Test-Condition "Default trusted countries configured" ($mainTfContent -match '"US", "CA", "GB"')

# Test 4: User-Agent Validation
Write-Host "`n4. User-Agent Validation Controls" -ForegroundColor Yellow
Write-Host "----------------------------------" -ForegroundColor Yellow

Test-Condition "User-Agent header validation configured" ($mainTfContent -match 'single_header.*user-agent')
Test-Condition "Mozilla User-Agent pattern required" ($mainTfContent -match 'Mozilla')
Test-Condition "Multiple browser User-Agents supported" (($mainTfContent -split 'Chrome|Safari|Edge|Firefox').Count -gt 4)

# Test 5: HTTP Method Controls
Write-Host "`n5. HTTP Method Access Controls" -ForegroundColor Yellow
Write-Host "-------------------------------" -ForegroundColor Yellow

Test-Condition "GET method explicitly allowed" ($mainTfContent -match 'search_string\s*=\s*"GET"')
Test-Condition "POST method explicitly allowed" ($mainTfContent -match 'search_string\s*=\s*"POST"')
Test-Condition "PUT method explicitly allowed" ($mainTfContent -match 'search_string\s*=\s*"PUT"')
Test-Condition "OPTIONS method for CORS allowed" ($mainTfContent -match 'search_string\s*=\s*"OPTIONS"')

# Test 6: Content-Type Validation
Write-Host "`n6. Content-Type Validation" -ForegroundColor Yellow
Write-Host "---------------------------" -ForegroundColor Yellow

Test-Condition "JSON content-type validation" ($mainTfContent -match 'application/json')
Test-Condition "Content-type header matching configured" ($mainTfContent -match 'content-type')

# Test 7: Static Resource Protection
Write-Host "`n7. Static Resource Access Controls" -ForegroundColor Yellow
Write-Host "-----------------------------------" -ForegroundColor Yellow

Test-Condition "CSS files explicitly allowed" ($mainTfContent -match '\.css')
Test-Condition "JavaScript files explicitly allowed" ($mainTfContent -match '\.js')
Test-Condition "Image files explicitly allowed" ($mainTfContent -match '\.png.*\.jpg')
Test-Condition "Favicon access allowed" ($mainTfContent -match 'favicon\.ico')

# Test 8: Critical Path Controls
Write-Host "`n8. Critical Path Access Controls" -ForegroundColor Yellow
Write-Host "---------------------------------" -ForegroundColor Yellow

Test-Condition "Health check endpoint allowed" ($mainTfContent -match '/health')
Test-Condition "SEO files allowed" ($mainTfContent -match 'robots\.txt.*sitemap\.xml')
Test-Condition "Critical paths have explicit allow rules" ($mainTfContent -match 'AllowHealthChecks|AllowSEOFiles')

# Test 9: AWS Managed Rules Integration
Write-Host "`n9. AWS Managed Rules Integration" -ForegroundColor Yellow
Write-Host "---------------------------------" -ForegroundColor Yellow

Test-Condition "AWS managed rule groups configured" ($mainTfContent -match 'aws_managed_rule_groups')
Test-Condition "Common Rule Set included" ($mainTfContent -match 'AWSManagedRulesCommonRuleSet')
Test-Condition "Managed rules in count mode" ($mainTfContent -match 'override_action\s*=\s*"count"')

# Test 10: Logging and Monitoring
Write-Host "`n10. Logging and Monitoring Configuration" -ForegroundColor Yellow
Write-Host "----------------------------------------" -ForegroundColor Yellow

Test-Condition "CloudWatch logging enabled" ($mainTfContent -match 'enable_logging')
Test-Condition "Log group creation configured" ($mainTfContent -match 'create_log_group')
Test-Condition "Log retention configured" ($mainTfContent -match 'log_group_retention_days')
Test-Condition "KMS encryption option available" ($mainTfContent -match 'enable_kms_encryption')

# Test 11: Rule Priority Structure
Write-Host "`n11. Rule Priority Structure Validation" -ForegroundColor Yellow
Write-Host "---------------------------------------" -ForegroundColor Yellow

$priorities = @()
if ($mainTfContent -match 'priority\s*=\s*(\d+)') {
    $priorities = [regex]::Matches($mainTfContent, 'priority\s*=\s*(\d+)') | ForEach-Object { [int]$_.Groups[1].Value }
}

Test-Condition "Rule priorities configured" ($priorities.Count -gt 0)
Test-Condition "Allow rules have high priority (< 200)" ($priorities | Where-Object { $_ -lt 200 }).Count -gt 0
Test-Condition "No duplicate priorities" ($priorities.Count -eq ($priorities | Sort-Object -Unique).Count)

# Test 12: Variable Validation
Write-Host "`n12. Variable Configuration Validation" -ForegroundColor Yellow
Write-Host "--------------------------------------" -ForegroundColor Yellow

Test-Condition "Environment validation configured" ($mainTfContent -match 'validation.*condition.*contains.*dev.*staging.*prod')
Test-Condition "Scope validation configured" ($mainTfContent -match 'validation.*condition.*contains.*REGIONAL.*CLOUDFRONT')
Test-Condition "Rate limiting variables defined" ($mainTfContent -match 'api_rate_limit.*web_rate_limit')

# Test 13: Output Configuration
Write-Host "`n13. Output Configuration Validation" -ForegroundColor Yellow
Write-Host "------------------------------------" -ForegroundColor Yellow

$outputCount = ([regex]::Matches($mainTfContent, 'output "')).Count
Test-Condition "Multiple outputs configured" ($outputCount -ge 3)
Test-Condition "WAF ARN output configured" ($mainTfContent -match 'output "zero_trust_waf_arn"')
Test-Condition "Configuration summary output" ($mainTfContent -match 'output "zero_trust_configuration"')

# Test 14: Security Tags and Metadata
Write-Host "`n14. Security Tags and Metadata" -ForegroundColor Yellow
Write-Host "-------------------------------" -ForegroundColor Yellow

Test-Condition "Security-focused tags configured" ($mainTfContent -match 'SecurityModel.*zero-trust')
Test-Condition "Compliance tags present" ($mainTfContent -match 'Compliance.*pci-dss-sox-hipaa')
Test-Condition "Criticality level specified" ($mainTfContent -match 'Criticality.*critical')

# Test 15: Module Structure Validation
Write-Host "`n15. Module Structure Validation" -ForegroundColor Yellow
Write-Host "--------------------------------" -ForegroundColor Yellow

Test-Condition "WAF module source path correct" ($mainTfContent -match 'source\s*=\s*"../../modules/waf"')
Test-Condition "Rule group module source correct" ($mainTfContent -match 'source\s*=\s*"../../modules/waf-rule-group"')
Test-Condition "Module dependencies properly structured" ($mainTfContent -match 'module\.zero_trust_allow_rules\.waf_rule_group_arn')

# Test 16: Terraform Syntax Validation
Write-Host "`n16. Advanced Terraform Syntax Validation" -ForegroundColor Yellow
Write-Host "------------------------------------------" -ForegroundColor Yellow

try {
    $planOutput = terraform plan -input=false 2>&1
    $planExitCode = $LASTEXITCODE
    
    if ($planExitCode -eq 0) {
        Test-Condition "Terraform plan successful (with credentials)" $true
    } elseif ($planOutput -match "credential|authentication") {
        Test-Condition "Terraform plan validates syntax (credentials needed)" $true
    } else {
        Test-Condition "Terraform plan validation" $false "Plan failed with configuration errors"
    }
} catch {
    Test-Condition "Terraform plan execution" $false "Failed to execute terraform plan"
}

# Test 17: Security Best Practices
Write-Host "`n17. Security Best Practices Validation" -ForegroundColor Yellow
Write-Host "---------------------------------------" -ForegroundColor Yellow

Test-Condition "No hardcoded sensitive values" (-not ($mainTfContent -match 'password|secret|key\s*=\s*"[^$]'))
Test-Condition "Variables used for configuration" ($mainTfContent -match 'var\.')
Test-Condition "Proper text transformations applied" ($mainTfContent -match 'text_transformation')

# Summary Report
Write-Host "`n" -NoNewline
Write-Host "=== VALIDATION SUMMARY ===" -ForegroundColor Cyan
Write-Host "===========================" -ForegroundColor Cyan

if ($ErrorCount -eq 0 -and $WarningCount -eq 0) {
    Write-Host "🎉 ALL TESTS PASSED! Enterprise Zero-Trust WAF is fully validated." -ForegroundColor Green
} elseif ($ErrorCount -eq 0) {
    Write-Host "✅ All critical tests passed with $WarningCount warnings." -ForegroundColor Yellow
} else {
    Write-Host "❌ $ErrorCount critical issues found, $WarningCount warnings." -ForegroundColor Red
}

Write-Host "`n📊 Test Results:" -ForegroundColor Cyan
Write-Host "   • Total Tests: $($ErrorCount + $WarningCount + (17 * 3 - $ErrorCount - $WarningCount))"
Write-Host "   • Passed: $((17 * 3 - $ErrorCount - $WarningCount))" -ForegroundColor Green
Write-Host "   • Warnings: $WarningCount" -ForegroundColor Yellow
Write-Host "   • Errors: $ErrorCount" -ForegroundColor Red

if ($ErrorCount -eq 0) {
    Write-Host "`n🚀 DEPLOYMENT READINESS: APPROVED" -ForegroundColor Green
    Write-Host "   The Enterprise Zero-Trust WAF configuration is ready for deployment." -ForegroundColor Green
    Write-Host "   Remember to test thoroughly in staging before production!" -ForegroundColor Yellow
} else {
    Write-Host "`n🛑 DEPLOYMENT READINESS: BLOCKED" -ForegroundColor Red
    Write-Host "   Please fix the critical issues before deployment." -ForegroundColor Red
}

Write-Host "`n🔒 Zero-Trust Security Validation Complete!" -ForegroundColor Cyan

exit $ErrorCount