# Block Default, Allow HTTP/HTTPS Traffic Example

This example demonstrates a high-security WAF configuration using the **"Default Deny, Explicit Allow"** security model. With `default_action = "block"`, all traffic is blocked by default, and only explicitly allowed traffic patterns are permitted through.

## 🎯 Purpose

This example is perfect for:

1. **High-Security Applications**: Applications handling sensitive data
2. **Zero-Trust Architecture**: Implementing zero-trust network principles
3. **Compliance Requirements**: Meeting strict security standards (PCI DSS, SOX, HIPAA)
4. **API Security**: Protecting APIs with strict access controls
5. **Defense in Depth**: Adding an extra security layer with explicit allow lists

## ⚠️ Important Security Model

### Default Deny Approach
- **Default Action**: `block` - All traffic is blocked by default
- **Explicit Allow Rules**: Only traffic matching specific patterns is allowed
- **Higher Security**: More secure than default allow, but requires careful configuration
- **Testing Critical**: Thorough testing required to avoid blocking legitimate users

## 🏗️ Architecture Overview

### Security Layers

1. **Geographic Filtering**: Allow traffic only from specific countries
2. **User-Agent Validation**: Allow only legitimate browser requests
3. **HTTP Method Control**: Allow only standard HTTP methods (GET, POST, PUT)
4. **Content-Type Validation**: Allow standard web and API content types
5. **Rate Limiting**: Block excessive requests even from allowed sources
6. **Pattern Blocking**: Block suspicious patterns (path traversal, etc.)
7. **Size Constraints**: Block oversized payloads
8. **Monitoring**: Count (but don't block) common attacks for visibility

## 📋 Rule Configuration

### Allow Rules (Priorities 200-206)

#### 1. Geographic Allow List (Priority 200)
```hcl
{
  name = "AllowSpecificCountries"
  action = "allow"
  statement_config = {
    geo_match_statement = {
      country_codes = ["US", "CA", "GB", "DE", "FR", "AU", "JP"]
    }
  }
}
```
- **Purpose**: Allow traffic only from trusted countries
- **Default Countries**: US, Canada, UK, Germany, France, Australia, Japan
- **Customizable**: Modify `allowed_countries` variable

#### 2. User-Agent Validation (Priority 201)
```hcl
{
  name = "AllowLegitimateUserAgents"
  action = "allow"
  statement_config = {
    byte_match_statement = {
      search_string = "Mozilla"
      field_to_match = { single_header = { name = "user-agent" } }
    }
  }
}
```
- **Purpose**: Allow only requests with legitimate browser User-Agent headers
- **Pattern**: Must contain "Mozilla" (covers most modern browsers)
- **Blocks**: Automated tools, bots, and scripts without proper User-Agent

#### 3. HTTP Method Control (Priorities 202-204)
```hcl
# Allow GET requests
{
  name = "AllowStandardHTTPMethods"
  action = "allow"
  statement_config = {
    byte_match_statement = {
      search_string = "GET"
      field_to_match = { method = {} }
    }
  }
}

# Allow POST requests (forms, APIs)
# Allow PUT requests (APIs)
```
- **Purpose**: Allow only standard HTTP methods
- **Allowed Methods**: GET, POST, PUT
- **Blocks**: Unusual methods like TRACE, DELETE, PATCH, OPTIONS

#### 4. Content-Type Validation (Priorities 205-206)
```hcl
# Allow HTML requests
{
  name = "AllowStandardAcceptHeaders"
  action = "allow"
  statement_config = {
    byte_match_statement = {
      search_string = "text/html"
      field_to_match = { single_header = { name = "accept" } }
    }
  }
}

# Allow JSON API requests
{
  name = "AllowJSONRequests"
  action = "allow"
  statement_config = {
    byte_match_statement = {
      search_string = "application/json"
      field_to_match = { single_header = { name = "content-type" } }
    }
  }
}
```
- **Purpose**: Allow standard web and API content types
- **Allowed Types**: HTML, JSON
- **Blocks**: Unusual content types that might indicate attacks

### Block Rules (Priorities 300-302)

#### 1. Rate Limiting (Priority 300)
```hcl
{
  name = "BlockExcessiveRequests"
  action = "block"
  statement_config = {
    rate_based_statement = {
      limit = 2000
      aggregate_key_type = "IP"
    }
  }
}
```
- **Purpose**: Block IPs making too many requests
- **Limit**: 2000 requests per 5 minutes per IP (configurable)
- **Protects**: Against DDoS and brute force attacks

#### 2. Suspicious Pattern Blocking (Priority 301)
```hcl
{
  name = "BlockSuspiciousPatterns"
  action = "block"
  statement_config = {
    byte_match_statement = {
      search_string = "../"
      field_to_match = { uri_path = {} }
    }
  }
}
```
- **Purpose**: Block path traversal attempts
- **Pattern**: URLs containing "../"
- **Protects**: Against directory traversal attacks

#### 3. Large Payload Blocking (Priority 302)
```hcl
{
  name = "BlockLargePayloads"
  action = "block"
  statement_config = {
    size_constraint_statement = {
      comparison_operator = "GT"
      size = 1048576  # 1MB
      field_to_match = { body = {} }
    }
  }
}
```
- **Purpose**: Block oversized request bodies
- **Limit**: 1MB maximum body size
- **Protects**: Against DoS attacks using large payloads

### Monitoring Rules (Priorities 100-101)

#### AWS Managed Rules (Count Mode)
```hcl
aws_managed_rule_groups = [
  {
    name = "AWSManagedRulesCommonRuleSet"
    override_action = "count"  # Monitor but don't block
  },
  {
    name = "AWSManagedRulesSQLiRuleSet"
    override_action = "count"  # Monitor but don't block
  }
]
```
- **Purpose**: Monitor common attacks without blocking
- **Benefit**: Visibility into attack patterns while maintaining control
- **Use Case**: Can be changed to "none" (block) after testing

## 🚀 Usage

### Prerequisites
- AWS CLI configured with appropriate credentials
- Terraform >= 1.0
- WAF permissions in target AWS account
- **Important**: Staging environment for testing

### Deployment Steps

1. **Navigate to the example**:
   ```bash
   cd examples/block_default_allow_http
   ```

2. **Initialize Terraform**:
   ```bash
   terraform init
   ```

3. **Review and customize variables**:
   ```bash
   # Edit terraform.tfvars or use command line variables
   terraform plan -var="name=my-secure-waf"
   ```

4. **Deploy to staging first**:
   ```bash
   terraform apply -var="name=staging-secure-waf"
   ```

5. **Test thoroughly** (see testing section below)

6. **Deploy to production**:
   ```bash
   terraform apply -var="name=prod-secure-waf"
   ```

### Customization Options

#### Geographic Configuration
```bash
terraform apply -var='allowed_countries=["US","CA","GB"]'
```

#### Rate Limiting Adjustment
```bash
terraform apply -var="rate_limit_threshold=1000"
```

#### ALB Association
```bash
terraform apply -var='alb_arn_list=["arn:aws:elasticloadbalancing:us-east-1:123456789012:loadbalancer/app/my-alb/1234567890123456"]'
```

### Using terraform.tfvars

Create a `terraform.tfvars` file:
```hcl
name                  = "secure-block-default-waf"
scope                 = "REGIONAL"
allowed_countries     = ["US", "CA", "GB", "DE", "FR"]
rate_limit_threshold  = 1500
alb_arn_list = [
  "arn:aws:elasticloadbalancing:us-east-1:123456789012:loadbalancer/app/secure-app/1234567890123456"
]
tags = {
  Environment   = "production"
  SecurityLevel = "high"
  Compliance    = "pci-dss"
}
```

## 🧪 Testing Strategy

### ⚠️ Critical Testing Requirements

**Before Production Deployment**:
1. Test all legitimate user workflows
2. Test from different geographic locations
3. Test different browsers and devices
4. Test API endpoints and integrations
5. Monitor CloudWatch metrics during testing

### Legitimate Traffic Tests

#### 1. Basic Web Requests
```bash
# Should be ALLOWED
curl -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36" \
     -H "Accept: text/html,application/xhtml+xml" \
     https://your-app.com/

# Expected: 200 OK response
```

#### 2. JSON API Requests
```bash
# Should be ALLOWED
curl -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36" \
     -H "Content-Type: application/json" \
     -H "Accept: application/json" \
     -X POST \
     -d '{"key":"value"}' \
     https://your-app.com/api/endpoint

# Expected: Normal API response
```

#### 3. Form Submissions
```bash
# Should be ALLOWED
curl -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36" \
     -H "Content-Type: application/x-www-form-urlencoded" \
     -X POST \
     -d "username=test&password=test" \
     https://your-app.com/login

# Expected: Normal form processing
```

### Blocked Traffic Tests

#### 1. No User-Agent Header
```bash
# Should be BLOCKED
curl https://your-app.com/

# Expected: 403 Forbidden (blocked by WAF)
```

#### 2. Suspicious Path Traversal
```bash
# Should be BLOCKED
curl -H "User-Agent: Mozilla/5.0" \
     https://your-app.com/../../../etc/passwd

# Expected: 403 Forbidden (blocked by WAF)
```

#### 3. Large Payload Attack
```bash
# Should be BLOCKED
curl -H "User-Agent: Mozilla/5.0" \
     -X POST \
     -d "$(head -c 2000000 /dev/zero | tr '\0' 'A')" \
     https://your-app.com/

# Expected: 403 Forbidden (blocked by WAF)
```

#### 4. Rate Limiting Test
```bash
# Should be BLOCKED after threshold
for i in {1..2100}; do
  curl -H "User-Agent: Mozilla/5.0" https://your-app.com/
done

# Expected: First 2000 requests allowed, then 403 Forbidden
```

#### 5. Unusual HTTP Method
```bash
# Should be BLOCKED
curl -H "User-Agent: Mozilla/5.0" \
     -X TRACE \
     https://your-app.com/

# Expected: 403 Forbidden (blocked by WAF)
```

## 📊 Monitoring & Observability

### CloudWatch Logging Configuration

This example includes comprehensive CloudWatch logging to provide detailed visibility into WAF decisions and traffic patterns.

#### Logging Options

**Option 1: Create New Log Group (Default)**
```hcl
enable_logging = true
create_log_group = true
log_group_name = null  # Auto-generated name
log_group_retention_days = 30
kms_key_id = null  # Optional encryption
```

**Option 2: Use Existing Log Group**
```hcl
enable_logging = true
create_log_group = false
existing_log_group_arn = "arn:aws:logs:us-east-1:123456789012:log-group:existing-waf-logs:*"
```

**Option 3: Disable Logging**
```hcl
enable_logging = false
```

#### Log Group Configuration

- **Auto-Generated Name**: `/aws/wafv2/{waf-name}` (when log_group_name is null)
- **Custom Name**: Specify your preferred log group name
- **Retention**: Configurable from 1 day to 10 years
- **Encryption**: Optional KMS encryption for sensitive environments
- **Cost**: ~$0.50 per GB ingested + $0.03 per GB stored per month

### Log Analysis Commands

#### View Recent WAF Logs
```bash
# Tail live logs
aws logs tail /aws/wafv2/block-default-allow-http-waf --follow

# View last 1 hour of logs
aws logs filter-log-events \
  --log-group-name /aws/wafv2/block-default-allow-http-waf \
  --start-time $(date -d '1 hour ago' +%s)000
```

#### Filter Blocked Requests
```bash
# All blocked requests
aws logs filter-log-events \
  --log-group-name /aws/wafv2/block-default-allow-http-waf \
  --filter-pattern '{ $.action = "BLOCK" }'

# Blocked requests from specific rule
aws logs filter-log-events \
  --log-group-name /aws/wafv2/block-default-allow-http-waf \
  --filter-pattern '{ $.action = "BLOCK" && $.terminatingRuleId = "BlockExcessiveRequests" }'
```

#### Filter Allowed Requests
```bash
# All allowed requests
aws logs filter-log-events \
  --log-group-name /aws/wafv2/block-default-allow-http-waf \
  --filter-pattern '{ $.action = "ALLOW" }'

# Requests allowed by specific rule
aws logs filter-log-events \
  --log-group-name /aws/wafv2/block-default-allow-http-waf \
  --filter-pattern '{ $.action = "ALLOW" && $.terminatingRuleId = "AllowSpecificCountries" }'
```

#### Analyze Traffic Patterns
```bash
# Requests from specific countries
aws logs filter-log-events \
  --log-group-name /aws/wafv2/block-default-allow-http-waf \
  --filter-pattern '{ $.httpRequest.country = "US" }'

# Requests with specific User-Agent patterns
aws logs filter-log-events \
  --log-group-name /aws/wafv2/block-default-allow-http-waf \
  --filter-pattern '{ $.httpRequest.headers[0].name = "User-Agent" }'

# Rate limited requests
aws logs filter-log-events \
  --log-group-name /aws/wafv2/block-default-allow-http-waf \
  --filter-pattern '{ $.terminatingRuleId = "BlockExcessiveRequests" }'
```

#### Security Analysis
```bash
# Path traversal attempts
aws logs filter-log-events \
  --log-group-name /aws/wafv2/block-default-allow-http-waf \
  --filter-pattern '{ $.terminatingRuleId = "BlockSuspiciousPatterns" }'

# Large payload attacks
aws logs filter-log-events \
  --log-group-name /aws/wafv2/block-default-allow-http-waf \
  --filter-pattern '{ $.terminatingRuleId = "BlockLargePayloads" }'

# Requests without User-Agent (likely bots)
aws logs filter-log-events \
  --log-group-name /aws/wafv2/block-default-allow-http-waf \
  --filter-pattern '{ $.action = "BLOCK" && $.terminatingRuleId = "Default_Action" }'
```

### Sample Log Entry Structure

```json
{
  "timestamp": 1640995200000,
  "formatVersion": 1,
  "webaclId": "arn:aws:wafv2:us-east-1:123456789012:regional/webacl/block-default-allow-http-waf/12345678-1234-1234-1234-123456789012",
  "terminatingRuleId": "AllowLegitimateUserAgents",
  "terminatingRuleType": "REGULAR",
  "action": "ALLOW",
  "terminatingRuleMatchDetails": [],
  "httpSourceName": "ALB",
  "httpSourceId": "123456789012-app/my-load-balancer/50dc6c495c0c9188",
  "ruleGroupList": [],
  "rateBasedRuleList": [],
  "nonTerminatingMatchingRules": [],
  "requestHeadersInserted": null,
  "responseCodeSent": null,
  "httpRequest": {
    "clientIp": "192.0.2.1",
    "country": "US",
    "headers": [
      {
        "name": "User-Agent",
        "value": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"
      },
      {
        "name": "Accept",
        "value": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8"
      }
    ],
    "uri": "/",
    "args": "",
    "httpVersion": "HTTP/1.1",
    "httpMethod": "GET",
    "requestId": "1-61c88400-69c4b044363faae6273c3aa6"
  }
}
```

### CloudWatch Insights Queries

#### Top Blocked Countries
```sql
fields @timestamp, httpRequest.country, action
| filter action = "BLOCK"
| stats count() by httpRequest.country
| sort count desc
| limit 10
```

#### Top User Agents (Blocked)
```sql
fields @timestamp, httpRequest.headers
| filter action = "BLOCK"
| filter ispresent(httpRequest.headers)
| stats count() by httpRequest.headers[0].value
| sort count desc
| limit 10
```

#### Hourly Traffic Pattern
```sql
fields @timestamp, action
| filter @timestamp > date_sub(now(), interval 24 hour)
| stats count() by bin(5m), action
| sort @timestamp desc
```

#### Rule Effectiveness Analysis
```sql
fields @timestamp, terminatingRuleId, action
| filter action = "BLOCK"
| stats count() by terminatingRuleId
| sort count desc
```

### Key CloudWatch Metrics

#### WAF Metrics
```bash
# View allowed requests
aws cloudwatch get-metric-statistics \
  --namespace AWS/WAFV2 \
  --metric-name AllowedRequests \
  --dimensions Name=WebACL,Value=block-default-allow-http-waf \
  --start-time 2024-01-01T00:00:00Z \
  --end-time 2024-01-02T00:00:00Z \
  --period 3600 \
  --statistics Sum

# View blocked requests
aws cloudwatch get-metric-statistics \
  --namespace AWS/WAFV2 \
  --metric-name BlockedRequests \
  --dimensions Name=WebACL,Value=block-default-allow-http-waf \
  --start-time 2024-01-01T00:00:00Z \
  --end-time 2024-01-02T00:00:00Z \
  --period 3600 \
  --statistics Sum
```

#### Rule-Specific Metrics
```bash
# Monitor specific allow rules
aws cloudwatch get-metric-statistics \
  --namespace AWS/WAFV2 \
  --metric-name AllowedRequests \
  --dimensions Name=WebACL,Value=block-default-allow-http-waf Name=Rule,Value=AllowSpecificCountries \
  --start-time 2024-01-01T00:00:00Z \
  --end-time 2024-01-02T00:00:00Z \
  --period 3600 \
  --statistics Sum
```

### Setting Up Alarms

#### High Blocked Requests Alarm
```bash
aws cloudwatch put-metric-alarm \
  --alarm-name "WAF-High-Blocked-Requests" \
  --alarm-description "Alert when WAF blocks many requests (possible attack or misconfiguration)" \
  --metric-name BlockedRequests \
  --namespace AWS/WAFV2 \
  --statistic Sum \
  --period 300 \
  --threshold 1000 \
  --comparison-operator GreaterThanThreshold \
  --dimensions Name=WebACL,Value=block-default-allow-http-waf
```

#### Low Allowed Requests Alarm
```bash
aws cloudwatch put-metric-alarm \
  --alarm-name "WAF-Low-Allowed-Requests" \
  --alarm-description "Alert when WAF allows very few requests (possible misconfiguration)" \
  --metric-name AllowedRequests \
  --namespace AWS/WAFV2 \
  --statistic Sum \
  --period 300 \
  --threshold 10 \
  --comparison-operator LessThanThreshold \
  --dimensions Name=WebACL,Value=block-default-allow-http-waf
```

## 💰 Cost Analysis

### AWS WAF Pricing
- **Web ACL**: $1.00 per month
- **Rule Groups**: $1.00 per month per AWS managed rule group (2 = $2.00)
- **WCU Usage**: ~100 WCUs for custom rules (~$0.06/month)
- **Requests**: $0.60 per million requests

### Monthly Cost Estimate
- **Base Cost**: $3.00/month (Web ACL + 2 AWS managed rule groups)
- **WCU Cost**: ~$0.06/month (100 WCUs)
- **Request Cost**: Variable based on traffic
- **Total Base**: ~$3.06/month + request costs

### Cost Optimization
1. Monitor WCU usage and optimize rules
2. Use count mode for AWS managed rules if not needed for blocking
3. Adjust rate limiting thresholds based on actual traffic patterns

## 🛡️ Security Benefits

### Advantages of Default Block
1. **Zero Trust**: Nothing is trusted by default
2. **Attack Surface Reduction**: Only explicitly allowed traffic passes
3. **Compliance**: Meets strict security requirements
4. **Visibility**: Clear understanding of what traffic is allowed
5. **Control**: Fine-grained control over access patterns

### Security Coverage

| Attack Vector | Protection Level | Method |
|---------------|------------------|---------|
| Geographic Attacks | High | Country-based blocking |
| Bot/Automated Attacks | High | User-Agent validation |
| HTTP Method Abuse | High | Method restriction |
| Content-Type Attacks | Medium | Content-Type validation |
| DDoS/Brute Force | High | Rate limiting |
| Path Traversal | High | Pattern blocking |
| Large Payload DoS | High | Size constraints |
| SQL Injection | Monitoring | AWS managed rules (count) |
| XSS Attacks | Monitoring | AWS managed rules (count) |

## 🚨 Troubleshooting

### Common Issues

#### 1. Legitimate Users Blocked
**Symptoms**: Users can't access the application
**Causes**: 
- User-Agent doesn't contain "Mozilla"
- Requests from non-allowed countries
- Unusual HTTP methods or content types

**Solutions**:
```bash
# Check sampled requests
aws wafv2 get-sampled-requests \
  --web-acl-arn <WAF-ARN> \
  --rule-metric-name AllowLegitimateUserAgents \
  --scope REGIONAL \
  --time-window StartTime=<START>,EndTime=<END> \
  --max-items 100

# Adjust allow rules based on findings
```

#### 2. High False Positive Rate
**Symptoms**: Many legitimate requests blocked
**Solutions**:
1. Review and expand allowed countries list
2. Adjust User-Agent matching patterns
3. Add more content-type allow rules
4. Consider using count mode initially

#### 3. Performance Issues
**Symptoms**: Slow response times
**Solutions**:
1. Optimize rule order (most common matches first)
2. Monitor WCU usage
3. Simplify complex rules

### Debug Commands

```bash
# Check WAF configuration
aws wafv2 describe-web-acl --scope REGIONAL --id <web-acl-id>

# View rule details
aws wafv2 describe-web-acl --scope REGIONAL --id <web-acl-id> --query 'WebACL.Rules'

# Check recent logs
aws logs filter-log-events \
  --log-group-name aws-waf-logs-block-default-allow-http-waf \
  --start-time $(date -d '1 hour ago' +%s)000
```

## 📚 Best Practices

### Configuration Management
1. **Test in Staging**: Always test thoroughly before production
2. **Gradual Rollout**: Start with count mode, then enable blocking
3. **Monitor Closely**: Watch metrics during initial deployment
4. **Document Rules**: Maintain clear documentation of allow/block rules

### Security Practices
1. **Regular Review**: Periodically review and update allow lists
2. **Incident Response**: Have procedures for quickly adjusting rules
3. **Backup Plans**: Know how to quickly disable WAF if needed
4. **Compliance**: Ensure configuration meets regulatory requirements

### Operational Practices
1. **Alerting**: Set up comprehensive CloudWatch alarms
2. **Logging**: Enable WAF logging for detailed analysis
3. **Automation**: Use Infrastructure as Code for all changes
4. **Training**: Ensure team understands the security model

## 🔄 Migration Strategy

### From Default Allow to Default Block

1. **Phase 1**: Deploy with count mode
   ```hcl
   default_action = "allow"
   # All custom rules with action = "count"
   ```

2. **Phase 2**: Enable blocking for obvious attacks
   ```hcl
   default_action = "allow"
   # Enable blocking for rate limiting and suspicious patterns
   ```

3. **Phase 3**: Switch to default block
   ```hcl
   default_action = "block"
   # All allow rules active
   ```

4. **Phase 4**: Fine-tune based on monitoring
   - Adjust allow rules based on legitimate traffic patterns
   - Add new allow rules as needed
   - Optimize performance

---

## Summary

The Block Default, Allow HTTP/HTTPS example provides:

- ✅ **Maximum Security**: Default deny with explicit allow rules
- ✅ **Comprehensive Coverage**: Geographic, method, content-type, and pattern filtering
- ✅ **Monitoring**: Full visibility into allowed and blocked traffic
- ✅ **Flexibility**: Highly configurable for different security requirements
- ✅ **Production Ready**: Includes testing, monitoring, and troubleshooting guides
- ✅ **Compliance**: Suitable for high-security and regulated environments

**⚠️ Important**: This configuration requires thorough testing and careful monitoring. Start with staging environments and gradually roll out to production while closely monitoring metrics and user feedback.