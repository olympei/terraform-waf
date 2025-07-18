# Enterprise Zero-Trust WAF Configuration

This example provides the most secure enterprise-grade WAF configuration using `default_action = "block"` with a **Zero-Trust security model**. It implements "Never trust, always verify" principles by blocking all traffic by default and only allowing explicitly verified legitimate web traffic.

## 🎯 Purpose

This zero-trust configuration is designed for:

1. **Maximum Security Environments**: Applications requiring the highest security posture
2. **Zero-Trust Architecture**: Implementation of zero-trust network principles
3. **Regulatory Compliance**: Strictest compliance requirements (PCI DSS Level 1, SOX, HIPAA)
4. **Critical Infrastructure**: Government, financial, and healthcare systems
5. **High-Value Targets**: Applications handling sensitive or classified data

## 🔒 Zero-Trust Security Model

### Core Principles

- **Never Trust, Always Verify**: No traffic is trusted by default
- **Explicit Allow Only**: Traffic must match specific allow patterns
- **Least Privilege Access**: Minimal access granted for legitimate needs
- **Continuous Verification**: Every request is validated
- **Default Deny**: Everything not explicitly allowed is blocked

### Security Philosophy

```
┌─────────────────────────────────────────────────────────────┐
│                    ZERO-TRUST WAF                           │
├─────────────────────────────────────────────────────────────┤
│ 1. EXPLICIT ALLOW (Priority 100)                           │
│    ├─ Geographic Verification                               │
│    ├─ User-Agent Validation                                 │
│    ├─ HTTP Method Verification                              │
│    ├─ Content-Type Validation                               │
│    └─ Resource Path Verification                            │
├─────────────────────────────────────────────────────────────┤
│ 2. THREAT BLOCKING (Priority 200)                          │
│    ├─ Rate Limiting                                         │
│    ├─ Injection Attack Prevention                           │
│    ├─ Path Traversal Protection                             │
│    ├─ Bot Detection                                         │
│    └─ Payload Size Limits                                   │
├─────────────────────────────────────────────────────────────┤
│ 3. MONITORING (Priority 300+)                              │
│    ├─ AWS Managed Rules (Count Mode)                       │
│    └─ Threat Intelligence                                   │
├─────────────────────────────────────────────────────────────┤
│ 4. DEFAULT ACTION: BLOCK                                   │
│    └─ All unmatched traffic → 403 Forbidden                │
└─────────────────────────────────────────────────────────────┘
```

## 🏗️ Architecture Overview

### Layer 1: Explicit Allow Rules (Priority 100)

**Purpose**: Allow only verified legitimate traffic patterns

#### Geographic Verification
- **Trusted Countries**: US, CA, GB, DE, FR, AU, JP, NL, SE, CH
- **Configurable**: Adjust based on business requirements
- **Zero-Trust**: Block all other geographic regions

#### User-Agent Validation
- **Legitimate Browsers**: Must contain "Mozilla"
- **Blocks**: Automated tools, bots, scripts
- **Zero-Trust**: No requests without proper User-Agent

#### HTTP Method Control
- **Allowed Methods**: GET, POST, PUT only
- **Blocks**: TRACE, DELETE, PATCH, OPTIONS, HEAD
- **Zero-Trust**: Strict method enforcement

#### Content-Type Validation
- **Allowed Types**: HTML, JSON, Form data
- **Blocks**: Unusual or suspicious content types
- **Zero-Trust**: Explicit content-type verification

#### Resource Path Verification
- **Static Resources**: CSS, JS, Images
- **API Endpoints**: /api/ paths
- **Health Checks**: /health endpoint
- **Zero-Trust**: Only known resource patterns allowed### La
yer 2: Security Rules (Priority 200)

**Purpose**: Block known threats before default block action

#### Advanced Threat Protection
1. **Rate Limiting**: 200 requests per 5 minutes per IP (strict)
2. **SQL Injection**: Advanced detection with URL decoding
3. **XSS Protection**: HTML entity decoding for evasion detection
4. **Path Traversal**: Directory traversal attempt blocking
5. **Malicious Files**: PHP and executable file blocking
6. **Bot Detection**: Automated bot and scanner blocking
7. **Large Payloads**: 1MB request size limit
8. **Header Manipulation**: Suspicious header detection

### Layer 3: AWS Managed Rules (Priority 300+)

**Purpose**: Monitor AWS threat intelligence (Count mode)

- **Common Rule Set**: OWASP Top 10 monitoring
- **SQL Injection Set**: Advanced SQLi monitoring  
- **Known Bad Inputs**: Exploit signature monitoring

*Note: Set to "count" mode for monitoring without blocking*

### Layer 4: Inline Rules (Priority 500+)

**Purpose**: Critical path-specific controls

- **Health Checks**: Allow /health endpoint
- **Favicon**: Allow /favicon.ico requests
- **Admin Blocking**: Block /admin paths

### Layer 5: Default Block

**Purpose**: Zero-trust enforcement - block everything else

- **Action**: Block (403 Forbidden)
- **Coverage**: All traffic not explicitly allowed
- **Philosophy**: "Deny by default, allow by exception"

## 🚀 Usage

### ⚠️ CRITICAL WARNING

**This configuration uses `default_action = "block"`**

- **ALL traffic is blocked by default**
- **Only explicitly allowed patterns pass through**
- **EXTENSIVE testing required before production**
- **Have rollback procedures ready**
- **Monitor CloudWatch metrics continuously**

### Prerequisites

- AWS CLI configured with appropriate credentials
- Terraform >= 1.0
- **Staging environment for thorough testing**
- **Rollback procedures documented**
- **24/7 monitoring capability**

### Deployment Process

#### Phase 1: Staging Deployment

1. **Deploy to staging**:
   ```bash
   cd examples/enterprise_zero_trust_waf
   terraform init
   terraform plan -var="environment=staging"
   terraform apply -var="environment=staging"
   ```

2. **Test extensively** (see testing section below)

3. **Monitor for 24-48 hours**

#### Phase 2: Production Deployment

1. **Only after successful staging validation**:
   ```bash
   terraform apply -var="environment=prod"
   ```

2. **Monitor immediately and continuously**

3. **Have rollback ready**:
   ```bash
   # Emergency rollback
   aws wafv2 disassociate-web-acl --resource-arn <ALB-ARN>
   ```

### Configuration Options

#### Trusted Countries Customization
```bash
# US and Canada only (high security)
terraform apply -var='trusted_countries=["US","CA"]'

# Extended trusted regions
terraform apply -var='trusted_countries=["US","CA","GB","DE","FR","AU","JP","NL","SE","CH","NO","DK"]'
```

#### Rate Limiting Adjustment
```bash
# Very strict (high security)
terraform apply -var="strict_rate_limit=50"

# Moderate (balanced security)
terraform apply -var="strict_rate_limit=500"
```## 🧪 
Critical Testing Strategy

### ⚠️ Testing is MANDATORY

**Zero-trust configurations require extensive testing**

### Pre-Production Testing Checklist

#### 1. Legitimate Traffic Validation
```bash
# Test standard browser requests
curl -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36" \
     -H "Accept: text/html" \
     https://staging-app.com/

# Test API requests
curl -H "User-Agent: Mozilla/5.0" \
     -H "Content-Type: application/json" \
     -X POST -d '{"test":"data"}' \
     https://staging-app.com/api/test

# Test form submissions
curl -H "User-Agent: Mozilla/5.0" \
     -H "Content-Type: application/x-www-form-urlencoded" \
     -X POST -d "username=test&password=test" \
     https://staging-app.com/login
```

#### 2. Geographic Testing
```bash
# Test from trusted countries (should be allowed)
curl -H "CF-IPCountry: US" -H "User-Agent: Mozilla/5.0" https://staging-app.com/
curl -H "CF-IPCountry: CA" -H "User-Agent: Mozilla/5.0" https://staging-app.com/

# Test from non-trusted countries (should be blocked)
curl -H "CF-IPCountry: CN" -H "User-Agent: Mozilla/5.0" https://staging-app.com/
```

#### 3. User-Agent Testing
```bash
# Legitimate User-Agent (should be allowed)
curl -H "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)" https://staging-app.com/

# No User-Agent (should be blocked)
curl https://staging-app.com/

# Bot User-Agent (should be blocked)
curl -H "User-Agent: malicious-bot/1.0" https://staging-app.com/
```

#### 4. HTTP Method Testing
```bash
# Allowed methods (should work)
curl -X GET -H "User-Agent: Mozilla/5.0" https://staging-app.com/
curl -X POST -H "User-Agent: Mozilla/5.0" https://staging-app.com/api/test
curl -X PUT -H "User-Agent: Mozilla/5.0" https://staging-app.com/api/update

# Blocked methods (should be blocked)
curl -X DELETE -H "User-Agent: Mozilla/5.0" https://staging-app.com/api/test
curl -X TRACE -H "User-Agent: Mozilla/5.0" https://staging-app.com/
```

#### 5. Content-Type Testing
```bash
# Allowed content types (should work)
curl -H "User-Agent: Mozilla/5.0" -H "Content-Type: application/json" https://staging-app.com/api/
curl -H "User-Agent: Mozilla/5.0" -H "Accept: text/html" https://staging-app.com/

# Unusual content types (should be blocked by default action)
curl -H "User-Agent: Mozilla/5.0" -H "Content-Type: application/octet-stream" https://staging-app.com/
```

#### 6. Resource Path Testing
```bash
# Allowed resources (should work)
curl -H "User-Agent: Mozilla/5.0" https://staging-app.com/styles.css
curl -H "User-Agent: Mozilla/5.0" https://staging-app.com/script.js
curl -H "User-Agent: Mozilla/5.0" https://staging-app.com/image.png
curl -H "User-Agent: Mozilla/5.0" https://staging-app.com/api/data

# Health check (should work)
curl -H "User-Agent: Mozilla/5.0" https://staging-app.com/health

# Blocked paths (should be blocked)
curl -H "User-Agent: Mozilla/5.0" https://staging-app.com/admin/
curl -H "User-Agent: Mozilla/5.0" https://staging-app.com/unknown-path
```

#### 7. Security Testing
```bash
# These should all be blocked
curl -H "User-Agent: Mozilla/5.0" "https://staging-app.com/search?q='; DROP TABLE users; --"
curl -H "User-Agent: Mozilla/5.0" "https://staging-app.com/../../../etc/passwd"
curl -H "User-Agent: Mozilla/5.0" "https://staging-app.com/shell.php"
```

### Monitoring During Testing

#### Real-Time Log Monitoring
```bash
# Monitor all WAF decisions
aws logs tail /aws/wafv2/enterprise-zero-trust-waf --follow

# Monitor blocked requests
aws logs filter-log-events \
  --log-group-name /aws/wafv2/enterprise-zero-trust-waf \
  --filter-pattern '{ $.action = "BLOCK" }'

# Monitor allowed requests
aws logs filter-log-events \
  --log-group-name /aws/wafv2/enterprise-zero-trust-waf \
  --filter-pattern '{ $.action = "ALLOW" }'
```

#### Key Metrics to Watch
```bash
# Default action blocks (traffic not explicitly allowed)
aws logs filter-log-events \
  --log-group-name /aws/wafv2/enterprise-zero-trust-waf \
  --filter-pattern '{ $.terminatingRuleId = "Default_Action" }'

# Allow rule effectiveness
aws logs filter-log-events \
  --log-group-name /aws/wafv2/enterprise-zero-trust-waf \
  --filter-pattern '{ $.terminatingRuleId = "AllowTrustedCountries" || $.terminatingRuleId = "AllowLegitimateUserAgents" }'
```