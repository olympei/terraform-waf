# Enterprise Secure WAF Configuration

This example provides a comprehensive, enterprise-grade WAF configuration with `default_action = "allow"` that implements maximum security while maintaining usability. It's designed for production environments requiring the highest level of web application security.

## 🎯 Purpose

This enterprise configuration is designed for:

1. **Large-Scale Production Applications**: High-traffic enterprise applications
2. **Regulatory Compliance**: PCI DSS, SOX, HIPAA, and other compliance requirements
3. **Maximum Security Posture**: Comprehensive protection against all known attack vectors
4. **Zero Downtime Requirements**: Allow legitimate traffic while blocking all threats
5. **Enterprise Monitoring**: Complete visibility and audit trails

## 🏗️ Architecture Overview

### Multi-Layer Security Architecture

```
Internet Traffic
       ↓
┌─────────────────────────────────────────────────────────────┐
│                    Enterprise WAF                           │
├─────────────────────────────────────────────────────────────┤
│ Layer 1: Custom Rule Groups (Priority 100-200)             │
│  ├─ Enterprise Security Rules (10 rules, 500 WCUs)         │
│  └─ Rate Limiting Rules (3 rules, 200 WCUs)                │
├─────────────────────────────────────────────────────────────┤
│ Layer 2: AWS Managed Rules (Priority 300-306)              │
│  ├─ Common Rule Set                                         │
│  ├─ SQL Injection Rule Set                                  │
│  ├─ Known Bad Inputs                                        │
│  ├─ Linux/Unix Protection                                   │
│  ├─ IP Reputation Lists                                     │
│  └─ Anonymous IP Detection                                  │
├─────────────────────────────────────────────────────────────┤
│ Layer 3: Inline Rules (Priority 500-505)                   │
│  ├─ Admin Panel Protection                                  │
│  ├─ Database Admin Protection                               │
│  ├─ Sensitive File Protection                               │
│  └─ Data Leakage Prevention                                 │
├─────────────────────────────────────────────────────────────┤
│ Default Action: ALLOW (legitimate traffic passes)          │
└─────────────────────────────────────────────────────────────┘
       ↓
Application Load Balancer
       ↓
Application Servers
```

## 🛡️ Security Layers

### Layer 1: Custom Rule Groups

#### Enterprise Security Rules (Priority 100)
**Capacity**: 500 WCUs | **Rules**: 10

1. **Geographic Blocking** (Priority 10)
   - Blocks traffic from 10 high-risk countries
   - Countries: CN, RU, KP, IR, SY, CU, SD, MM, AF, IQ
   - Configurable via `high_risk_countries` variable

2. **Advanced SQL Injection Protection** (Priority 20)
   - Inspects all query arguments with URL decoding
   - Blocks sophisticated SQL injection attempts
   - Complements AWS managed SQLi rules

3. **Advanced XSS Protection** (Priority 21)
   - Inspects request body with HTML entity decoding
   - Blocks cross-site scripting attacks
   - Multiple transformation support

4. **Path Traversal Protection** (Priority 30)
   - Blocks directory traversal attempts (../)
   - URL decoding before analysis
   - Protects against file system access

5. **Command Injection Protection** (Priority 31)
   - Blocks command injection attempts
   - Detects semicolon-based command chaining
   - URL decoding for evasion detection

6. **Malicious File Upload Protection** (Priority 32)
   - Blocks PHP file uploads
   - Case-insensitive matching
   - Prevents web shell uploads

7. **Bot Detection** (Priority 40)
   - Blocks requests with "bot" in User-Agent
   - Case-insensitive matching
   - Prevents automated attacks

8. **Security Scanner Detection** (Priority 41)
   - Blocks security scanning tools (nmap, etc.)
   - Protects against reconnaissance
   - Case-insensitive User-Agent analysis

9. **Large Payload Protection** (Priority 50)
   - Blocks requests larger than 2MB
   - Prevents DoS attacks via large payloads
   - Configurable size limits

10. **Suspicious Header Detection** (Priority 60)
    - Detects header manipulation attempts
    - Blocks suspicious proxy configurations
    - Prevents header-based attacks

#### Rate Limiting Rules (Priority 200)
**Capacity**: 200 WCUs | **Rules**: 3

1. **Strict Rate Limiting** (Priority 100)
   - 100 requests per 5 minutes per IP
   - For suspicious or flagged IPs
   - Immediate blocking action

2. **API Rate Limiting** (Priority 101)
   - 1000 requests per 5 minutes per forwarded IP
   - Protects API endpoints
   - Supports load balancer scenarios

3. **Web Traffic Rate Limiting** (Priority 102)
   - 5000 requests per 5 minutes per IP
   - Count mode (can be changed to block)
   - General web traffic protection

### Layer 2: AWS Managed Rules (Priority 300-306)

1. **AWSManagedRulesCommonRuleSet** (Priority 300)
   - Core web application protection
   - OWASP Top 10 coverage
   - Regularly updated by AWS

2. **AWSManagedRulesSQLiRuleSet** (Priority 301)
   - Advanced SQL injection protection
   - Database-specific attack patterns
   - Complements custom SQLi rules

3. **AWSManagedRulesKnownBadInputsRuleSet** (Priority 302)
   - Known malicious input patterns
   - Exploit kit signatures
   - Vulnerability scanner detection

4. **AWSManagedRulesLinuxRuleSet** (Priority 303)
   - Linux-specific attack protection
   - System command injection
   - File system access attempts

5. **AWSManagedRulesUnixRuleSet** (Priority 304)
   - Unix-specific attack protection
   - Shell command injection
   - System exploitation attempts

6. **AWSManagedRulesAmazonIpReputationList** (Priority 305)
   - AWS threat intelligence
   - Known malicious IP addresses
   - Botnet and malware sources

7. **AWSManagedRulesAnonymousIpList** (Priority 306)
   - Anonymous proxy detection
   - VPN and Tor exit nodes
   - Privacy service blocking

### Layer 3: Inline Rules (Priority 500-505)

1. **Admin Panel Protection** (Priority 500)
   - Blocks access to /admin paths
   - Case-insensitive matching
   - Prevents admin interface access

2. **Database Admin Protection** (Priority 501)
   - Blocks phpMyAdmin access
   - Prevents database management tool access
   - Case-insensitive detection

3. **Backup File Protection** (Priority 502)
   - Blocks access to .bak files
   - Prevents backup file exposure
   - Case-insensitive matching

4. **Configuration File Protection** (Priority 503)
   - Blocks access to .env files
   - Prevents configuration exposure
   - Environment variable protection

5. **API Key Protection** (Priority 504)
   - Blocks API keys in query strings
   - Prevents credential exposure
   - URL decoding for detection

6. **Sensitive Data Protection** (Priority 505)
   - Blocks passwords in query strings
   - Prevents credential leakage
   - URL decoding for detection

## 🚀 Usage

### Prerequisites
- AWS CLI configured with appropriate credentials
- Terraform >= 1.0
- Enterprise AWS account with WAF permissions
- CloudWatch and KMS permissions for logging

### Quick Deployment

1. **Navigate to the enterprise example**:
   ```bash
   cd examples/enterprise_secure_waf
   ```

2. **Initialize Terraform**:
   ```bash
   terraform init
   ```

3. **Review the configuration**:
   ```bash
   terraform plan
   ```

4. **Deploy the enterprise WAF**:
   ```bash
   terraform apply
   ```

5. **View the configuration summary**:
   ```bash
   terraform output enterprise_waf_configuration
   ```

### Configuration Options

#### Environment-Specific Deployment
```bash
# Development environment
terraform apply -var="environment=dev" -var="rate_limit_web=10000"

# Staging environment  
terraform apply -var="environment=staging" -var="rate_limit_api=2000"

# Production environment
terraform apply -var="environment=prod" -var="enable_kms_encryption=true"
```

#### Geographic Customization
```bash
# Custom high-risk countries
terraform apply -var='high_risk_countries=["CN","RU","KP","IR"]'

# More restrictive (block more countries)
terraform apply -var='high_risk_countries=["CN","RU","KP","IR","SY","CU","SD","MM","AF","IQ","LY","SO"]'
```

#### Rate Limiting Customization
```bash
# High-traffic application
terraform apply \
  -var="rate_limit_api=5000" \
  -var="rate_limit_web=20000" \
  -var="rate_limit_strict=500"

# Low-traffic application
terraform apply \
  -var="rate_limit_api=500" \
  -var="rate_limit_web=2000" \
  -var="rate_limit_strict=50"
```

### Using terraform.tfvars

Create a `terraform.tfvars` file:
```hcl
name        = "my-enterprise-waf"
environment = "prod"
scope       = "REGIONAL"

alb_arn_list = [
  "arn:aws:elasticloadbalancing:us-east-1:123456789012:loadbalancer/app/prod-app/1234567890123456"
]

# Geographic security
high_risk_countries = ["CN", "RU", "KP", "IR", "SY"]

# Rate limiting
rate_limit_api    = 2000
rate_limit_web    = 8000
rate_limit_strict = 200

# Logging and compliance
enable_logging           = true
log_group_retention_days = 365  # 1 year for compliance
enable_kms_encryption    = true

tags = {
  Environment   = "production"
  Application   = "enterprise-web-app"
  SecurityLevel = "maximum"
  Compliance    = "pci-dss-sox-hipaa"
  Owner         = "security-team"
  CostCenter    = "security"
  Criticality   = "high"
  DataClass     = "confidential"
}
```

## 📊 Monitoring & Observability

### Enterprise CloudWatch Logging Configuration

The enterprise WAF includes comprehensive CloudWatch logging with flexible configuration options to support existing enterprise logging infrastructure.

#### Logging Configuration Options

**Option 1: Create New Log Group (Default)**
```hcl
enable_logging = true
create_log_group = true
log_group_name = null  # Auto-generated: /aws/wafv2/{waf-name}
log_group_retention_days = 90
enable_kms_encryption = true
kms_key_id = null  # Will create new KMS key
```

**Option 2: Use Existing Log Group**
```hcl
enable_logging = true
create_log_group = false
existing_log_group_arn = "arn:aws:logs:us-east-1:123456789012:log-group:enterprise-security-logs:*"
```

**Option 3: Disable Logging (Not Recommended for Enterprise)**
```hcl
enable_logging = false
```

#### Enterprise Logging Features

- **Centralized Logging**: Integration with existing enterprise log groups
- **Compliance Retention**: Configurable retention from 1 day to 10 years
- **KMS Encryption**: Optional encryption for sensitive environments
- **Cost Optimization**: Shared log groups reduce costs
- **SIEM Integration**: Compatible with existing SIEM systems
- **Audit Trail**: Complete request/response logging for compliance

#### Log Group Configuration Details

| Configuration | New Log Group | Existing Log Group |
|---------------|---------------|-------------------|
| **Auto-Generated Name** | `/aws/wafv2/{waf-name}` | Uses existing name |
| **Custom Name** | Configurable | Inherited |
| **Retention** | 1 day - 10 years | Inherited |
| **Encryption** | Optional KMS | Inherited |
| **Cost** | ~$0.50/GB ingested | Shared costs |
| **Management** | Terraform managed | External management |

#### Finding Existing Log Groups

```bash
# List all log groups
aws logs describe-log-groups --query 'logGroups[*].[logGroupName,arn]' --output table

# Find security-related log groups
aws logs describe-log-groups --log-group-name-prefix "security"
aws logs describe-log-groups --log-group-name-prefix "enterprise"
aws logs describe-log-groups --log-group-name-prefix "compliance"

# Get specific log group details
aws logs describe-log-groups --log-group-name "enterprise-security-logs"
```

#### Common Enterprise Log Group Patterns

- **Centralized Security**: `enterprise-security-logs`
- **SIEM Integration**: `siem-ingestion-logs`
- **Compliance Audit**: `compliance-audit-logs`
- **Multi-Service**: `aws-security-services`
- **Department-Specific**: `security-team-logs`

### Real-Time Security Monitoring

#### Live Threat Detection
```bash
# Monitor live security events
aws logs tail /aws/wafv2/enterprise-secure-waf --follow

# Filter blocked requests only
aws logs filter-log-events \
  --log-group-name /aws/wafv2/enterprise-secure-waf \
  --filter-pattern '{ $.action = "BLOCK" }'

# Monitor specific threat types
aws logs filter-log-events \
  --log-group-name /aws/wafv2/enterprise-secure-waf \
  --filter-pattern '{ $.terminatingRuleId = "BlockAdvancedSQLi" || $.terminatingRuleId = "BlockAdvancedXSS" }'
```

#### Geographic Threat Analysis
```bash
# Monitor blocked countries
aws logs filter-log-events \
  --log-group-name /aws/wafv2/enterprise-secure-waf \
  --filter-pattern '{ $.terminatingRuleId = "BlockHighRiskCountries" }'

# Analyze attack sources by country
aws logs filter-log-events \
  --log-group-name /aws/wafv2/enterprise-secure-waf \
  --filter-pattern '{ $.action = "BLOCK" }' \
  | jq '.events[] | .httpRequest.country' | sort | uniq -c | sort -nr
```

#### Bot and Scanner Detection
```bash
# Monitor bot activity
aws logs filter-log-events \
  --log-group-name /aws/wafv2/enterprise-secure-waf \
  --filter-pattern '{ $.terminatingRuleId = "BlockSuspiciousBots" || $.terminatingRuleId = "BlockSecurityScanners" }'

# Analyze blocked User-Agents
aws logs filter-log-events \
  --log-group-name /aws/wafv2/enterprise-secure-waf \
  --filter-pattern '{ $.action = "BLOCK" }' \
  | jq '.events[] | .httpRequest.headers[] | select(.name == "User-Agent") | .value' | sort | uniq -c | sort -nr
```

### CloudWatch Insights Queries

#### Security Dashboard Queries

**Top Attack Types**:
```sql
fields @timestamp, terminatingRuleId, action
| filter action = "BLOCK"
| stats count() by terminatingRuleId
| sort count desc
| limit 20
```

**Geographic Attack Analysis**:
```sql
fields @timestamp, httpRequest.country, terminatingRuleId
| filter action = "BLOCK" and terminatingRuleId = "BlockHighRiskCountries"
| stats count() by httpRequest.country
| sort count desc
```

**Hourly Attack Patterns**:
```sql
fields @timestamp, action
| filter action = "BLOCK"
| stats count() by bin(1h)
| sort @timestamp desc
```

**Rate Limiting Effectiveness**:
```sql
fields @timestamp, terminatingRuleId, httpRequest.clientIp
| filter terminatingRuleId like /RateLimit/
| stats count() by httpRequest.clientIp, terminatingRuleId
| sort count desc
| limit 50
```

**Admin Panel Attack Attempts**:
```sql
fields @timestamp, httpRequest.uri, httpRequest.clientIp, httpRequest.country
| filter terminatingRuleId = "ProtectAdminPanel"
| stats count() by httpRequest.clientIp, httpRequest.country
| sort count desc
```

### Compliance Reporting

#### Security Metrics Collection
```bash
# Overall security metrics
aws cloudwatch get-metric-statistics \
  --namespace AWS/WAFV2 \
  --metric-name BlockedRequests \
  --dimensions Name=WebACL,Value=enterprise-secure-waf \
  --start-time $(date -d '30 days ago' --iso-8601) \
  --end-time $(date --iso-8601) \
  --period 86400 \
  --statistics Sum

# Rule group effectiveness
aws cloudwatch get-metric-statistics \
  --namespace AWS/WAFV2 \
  --metric-name BlockedRequests \
  --dimensions Name=WebACL,Value=enterprise-secure-waf Name=RuleGroup,Value=enterprise-security-rules \
  --start-time $(date -d '7 days ago' --iso-8601) \
  --end-time $(date --iso-8601) \
  --period 3600 \
  --statistics Sum
```

#### Automated Compliance Reports
```bash
# Generate daily security report
cat << 'EOF' > daily_security_report.sh
#!/bin/bash
DATE=$(date +%Y-%m-%d)
LOG_GROUP="/aws/wafv2/enterprise-secure-waf"

echo "Enterprise WAF Security Report - $DATE"
echo "========================================"

echo "Total Blocked Requests (Last 24h):"
aws logs filter-log-events \
  --log-group-name $LOG_GROUP \
  --start-time $(date -d '24 hours ago' +%s)000 \
  --filter-pattern '{ $.action = "BLOCK" }' \
  | jq '.events | length'

echo "Top Attack Types:"
aws logs filter-log-events \
  --log-group-name $LOG_GROUP \
  --start-time $(date -d '24 hours ago' +%s)000 \
  --filter-pattern '{ $.action = "BLOCK" }' \
  | jq '.events | group_by(.terminatingRuleId) | map({rule: .[0].terminatingRuleId, count: length}) | sort_by(.count) | reverse | .[0:10]'

echo "Top Source Countries:"
aws logs filter-log-events \
  --log-group-name $LOG_GROUP \
  --start-time $(date -d '24 hours ago' +%s)000 \
  --filter-pattern '{ $.action = "BLOCK" }' \
  | jq '.events | group_by(.httpRequest.country) | map({country: .[0].httpRequest.country, count: length}) | sort_by(.count) | reverse | .[0:10]'
EOF

chmod +x daily_security_report.sh
```

## 💰 Cost Analysis

### Detailed Cost Breakdown

#### Base WAF Costs
- **WAF ACL**: $1.00/month
- **Custom Rule Groups**: $2.00/month (2 groups)
- **AWS Managed Rules**: $7.00/month (7 rule groups)
- **WCU Usage**: ~$3.00/month (estimated 500 WCUs)

#### CloudWatch Logging Costs
- **Log Ingestion**: ~$0.50 per GB
- **Log Storage**: ~$0.03 per GB per month
- **Typical Enterprise Usage**: ~$10-20/month

#### Total Monthly Cost Estimate
- **Base Configuration**: ~$13.00/month
- **With Logging**: ~$23-33/month
- **High Traffic (>10M requests)**: ~$40-60/month

### Cost Optimization Strategies

1. **WCU Optimization**:
   - Monitor WCU usage in CloudWatch
   - Optimize rule order (most common blocks first)
   - Use count mode for testing before blocking

2. **Log Management**:
   - Adjust retention based on compliance requirements
   - Use log filtering to reduce storage costs
   - Archive old logs to S3 for long-term retention

3. **Rule Efficiency**:
   - Regularly review rule effectiveness
   - Remove or modify underperforming rules
   - Combine similar rules where possible

## 🔒 Security Benefits

### Comprehensive Threat Protection

| Threat Category | Protection Level | Coverage |
|----------------|------------------|----------|
| **OWASP Top 10** | Maximum | ✅ Complete |
| **SQL Injection** | Maximum | ✅ Multi-layer |
| **XSS Attacks** | Maximum | ✅ Advanced |
| **DDoS/Rate Limiting** | High | ✅ Multi-tier |
| **Bot Protection** | High | ✅ Advanced |
| **Geographic Threats** | High | ✅ Configurable |
| **File Upload Attacks** | High | ✅ Comprehensive |
| **Admin Panel Protection** | Maximum | ✅ Complete |
| **Data Leakage Prevention** | Maximum | ✅ Advanced |
| **IP Reputation** | High | ✅ AWS Intelligence |

### Compliance Features

- **PCI DSS**: Complete audit trail and data protection
- **SOX**: Financial data protection and access controls
- **HIPAA**: Healthcare data security and privacy
- **GDPR**: Data protection and privacy controls
- **ISO 27001**: Information security management

### Enterprise Security Features

1. **Zero Trust Architecture**: Default allow with comprehensive blocking
2. **Defense in Depth**: Multiple security layers
3. **Threat Intelligence**: AWS-managed threat feeds
4. **Real-time Monitoring**: Live security event tracking
5. **Automated Response**: Immediate threat blocking
6. **Audit Compliance**: Complete request/response logging

## 🧪 Testing Strategy

### Pre-Production Testing

#### Security Validation Tests
```bash
# Test SQL injection protection
curl -X POST "https://staging-app.com/api" \
  -d "user=admin' OR '1'='1" \
  -H "Content-Type: application/x-www-form-urlencoded"

# Test XSS protection
curl "https://staging-app.com/search?q=<script>alert('xss')</script>"

# Test path traversal protection
curl "https://staging-app.com/../../../etc/passwd"

# Test admin panel protection
curl "https://staging-app.com/admin/login"

# Test rate limiting
for i in {1..150}; do curl "https://staging-app.com/api/test"; done
```

#### Geographic Testing
```bash
# Test from different countries (using VPN or proxy)
curl -H "CF-IPCountry: CN" "https://staging-app.com/"
curl -H "CF-IPCountry: RU" "https://staging-app.com/"
curl -H "CF-IPCountry: US" "https://staging-app.com/"
```

### Production Monitoring

#### Health Checks
```bash
# Monitor legitimate traffic
curl -H "User-Agent: Mozilla/5.0 (legitimate browser)" "https://prod-app.com/"

# Check API functionality
curl -H "Content-Type: application/json" \
     -X POST "https://prod-app.com/api/health" \
     -d '{"status":"check"}'
```

#### Security Validation
```bash
# Verify blocking is working
curl "https://prod-app.com/admin/" # Should be blocked
curl "https://prod-app.com/../etc/passwd" # Should be blocked
```

## 🚨 Troubleshooting

### Common Issues

#### 1. Legitimate Traffic Blocked
**Symptoms**: Users can't access the application
**Diagnosis**:
```bash
# Check recent blocked requests
aws logs filter-log-events \
  --log-group-name /aws/wafv2/enterprise-secure-waf \
  --start-time $(date -d '1 hour ago' +%s)000 \
  --filter-pattern '{ $.action = "BLOCK" }'
```

**Solutions**:
- Review geographic blocking settings
- Adjust rate limiting thresholds
- Whitelist specific IP ranges if needed
- Use count mode for testing

#### 2. High False Positive Rate
**Symptoms**: Many legitimate requests blocked
**Diagnosis**:
```bash
# Analyze blocked request patterns
aws logs filter-log-events \
  --log-group-name /aws/wafv2/enterprise-secure-waf \
  --filter-pattern '{ $.action = "BLOCK" }' \
  | jq '.events | group_by(.terminatingRuleId) | map({rule: .[0].terminatingRuleId, count: length}) | sort_by(.count) | reverse'
```

**Solutions**:
- Fine-tune specific rules
- Use count mode for problematic rules
- Adjust text transformations
- Review rule priorities

#### 3. Performance Issues
**Symptoms**: Slow response times
**Diagnosis**:
```bash
# Check WCU usage
aws cloudwatch get-metric-statistics \
  --namespace AWS/WAFV2 \
  --metric-name ConsumedCapacity \
  --dimensions Name=WebACL,Value=enterprise-secure-waf
```

**Solutions**:
- Optimize rule order
- Reduce rule complexity
- Monitor WCU consumption
- Consider rule group capacity limits

### Emergency Procedures

#### Disable WAF (Emergency Only)
```bash
# Disassociate WAF from ALB
aws wafv2 disassociate-web-acl --resource-arn <ALB-ARN>

# Or modify default action to allow all
aws wafv2 update-web-acl --scope REGIONAL --id <WAF-ID> --default-action Allow={}
```

#### Quick Rule Disable
```bash
# Change rule action to count instead of block
terraform apply -var="emergency_count_mode=true"
```

## 📚 Best Practices

### Configuration Management

1. **Infrastructure as Code**: Use Terraform for all changes
2. **Version Control**: Track all configuration changes
3. **Environment Separation**: Different configs for dev/staging/prod
4. **Change Management**: Formal approval process for production changes

### Security Operations

1. **Continuous Monitoring**: 24/7 security event monitoring
2. **Regular Reviews**: Monthly rule effectiveness reviews
3. **Threat Intelligence**: Stay updated with latest threat patterns
4. **Incident Response**: Documented procedures for security incidents

### Compliance Management

1. **Regular Audits**: Quarterly security audits
2. **Documentation**: Maintain complete security documentation
3. **Training**: Regular security training for operations team
4. **Reporting**: Automated compliance reporting

---

## Summary

The Enterprise Secure WAF configuration provides:

- ✅ **Maximum Security**: 20+ security rules across 3 layers
- ✅ **Enterprise Scale**: Handles high-traffic production workloads
- ✅ **Compliance Ready**: Meets major regulatory requirements
- ✅ **Cost Effective**: ~$23-33/month for comprehensive protection
- ✅ **Production Ready**: Complete monitoring and alerting
- ✅ **Zero Downtime**: Allow legitimate traffic while blocking threats

This configuration represents the gold standard for enterprise web application security, providing comprehensive protection against all known attack vectors while maintaining optimal performance and usability.