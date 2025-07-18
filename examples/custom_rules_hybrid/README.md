# Custom Rules Hybrid Example

This example demonstrates the hybrid approach to WAF rule configuration, showcasing both simple type-based rules and advanced object-based rules within a single rule group. This approach allows teams to gradually migrate from simple configurations to advanced ones while maintaining backward compatibility.

## 🎯 Purpose

The hybrid example serves multiple purposes:

1. **Migration Path**: Shows how to migrate from simple type-based rules to advanced object-based configurations
2. **Flexibility**: Demonstrates mixing different configuration approaches in one rule group
3. **Best Practices**: Illustrates when to use simple vs. advanced configurations
4. **Comprehensive Protection**: Provides multi-layered security using both approaches

## 🏗️ Architecture Overview

### Rule Configuration Approaches

#### 1. Simple Type-Based Rules (Backward Compatible)
- Easy to configure and understand
- Perfect for common use cases
- Minimal configuration required
- Automatic field matching and transformations

#### 2. Advanced Object-Based Rules (Full Control)
- Complete control over WAF statement configuration
- Support for complex field matching
- Custom text transformations
- Advanced targeting capabilities

## 📋 Rule Breakdown

### Simple Type-Based Rules (4 rules)

#### 1. Simple SQL Injection Protection
```hcl
{
  name           = "SimpleBlockSQLi"
  type           = "sqli"
  field_to_match = "body"
  action         = "block"
}
```
- **Protection**: Basic SQL injection detection
- **Target**: Request body
- **Action**: Block malicious requests

#### 2. Simple XSS Protection
```hcl
{
  name           = "SimpleBlockXSS"
  type           = "xss"
  field_to_match = "uri_path"
  action         = "block"
}
```
- **Protection**: Cross-site scripting detection
- **Target**: URI path
- **Action**: Block XSS attempts

#### 3. Simple Rate Limiting
```hcl
{
  name               = "SimpleRateLimit"
  type               = "rate_based"
  rate_limit         = 1000
  aggregate_key_type = "IP"
  action             = "block"
}
```
- **Protection**: DDoS and brute force prevention
- **Limit**: 1000 requests per 5 minutes per IP
- **Action**: Block excessive requests

#### 4. Simple Geographic Blocking
```hcl
{
  name          = "SimpleGeoBlock"
  type          = "geo_match"
  country_codes = ["CN", "RU"]
  action        = "block"
}
```
- **Protection**: Geographic access control
- **Target**: China and Russia
- **Action**: Block requests from specified countries

### Advanced Object-Based Rules (6 rules)

#### 1. Advanced SQL Injection with Header Inspection
```hcl
{
  statement_config = {
    sqli_match_statement = {
      field_to_match = {
        single_header = { name = "x-forwarded-for" }
      }
      text_transformation = {
        priority = 1
        type     = "URL_DECODE"
      }
    }
  }
}
```
- **Protection**: SQL injection in forwarded headers
- **Target**: X-Forwarded-For header
- **Transformation**: URL decode before analysis

#### 2. Advanced XSS with Query String Inspection
```hcl
{
  statement_config = {
    xss_match_statement = {
      field_to_match = {
        query_string = {}
      }
      text_transformation = {
        priority = 2
        type     = "HTML_ENTITY_DECODE"
      }
    }
  }
}
```
- **Protection**: XSS in query parameters
- **Target**: URL query string
- **Transformation**: HTML entity decode

#### 3. Advanced Rate Limiting with Forwarded IP
```hcl
{
  statement_config = {
    rate_based_statement = {
      limit              = 500
      aggregate_key_type = "FORWARDED_IP"
    }
  }
}
```
- **Protection**: Rate limiting behind load balancers
- **Limit**: 500 requests per 5 minutes
- **Target**: Forwarded IP addresses
- **Action**: Count (monitoring mode)

#### 4. Advanced Geographic Blocking
```hcl
{
  statement_config = {
    geo_match_statement = {
      country_codes = ["CN", "RU", "KP", "IR", "SY"]
    }
  }
}
```
- **Protection**: Extended geographic blocking
- **Target**: High-risk countries
- **Coverage**: China, Russia, North Korea, Iran, Syria

#### 5. Advanced Size Constraint
```hcl
{
  statement_config = {
    size_constraint_statement = {
      comparison_operator = "GT"
      size               = 16384  # 16KB
      field_to_match = {
        body = {}
      }
    }
  }
}
```
- **Protection**: Large payload prevention
- **Limit**: 16KB request body size
- **Action**: Block oversized requests

#### 6. Advanced Bot Detection
```hcl
{
  statement_config = {
    byte_match_statement = {
      search_string         = "bot"
      positional_constraint = "CONTAINS"
      field_to_match = {
        single_header = { name = "user-agent" }
      }
      text_transformation = {
        type = "LOWERCASE"
      }
    }
  }
}
```
- **Protection**: Automated bot detection
- **Target**: User-Agent header
- **Pattern**: Contains "bot" (case-insensitive)

## 🚀 Usage

### Prerequisites
- AWS CLI configured with appropriate credentials
- Terraform >= 1.0
- WAF permissions in target AWS account

### Deployment Steps

1. **Initialize Terraform**:
   ```bash
   terraform init
   ```

2. **Review the Configuration**:
   ```bash
   terraform plan
   ```

3. **Deploy the Rule Group**:
   ```bash
   terraform apply
   ```

4. **Use in WAF ACL**:
   ```hcl
   module "waf_acl" {
     source = "../../modules/waf"
     
     rule_group_arn_list = [
       {
         arn      = module.custom_rule_group.waf_rule_group_arn
         name     = "hybrid-protection"
         priority = 100
       }
     ]
   }
   ```

### Customization Options

```hcl
# Adjust rule group capacity
variable "capacity" {
  default = 300  # Increase if adding more rules
}

# Modify rate limiting thresholds
locals {
  simple_rate_limit   = 1000  # Simple rule threshold
  advanced_rate_limit = 500   # Advanced rule threshold
}

# Update geographic blocking
locals {
  basic_blocked_countries    = ["CN", "RU"]
  extended_blocked_countries = ["CN", "RU", "KP", "IR", "SY"]
}
```

## 📊 Rule Priority Strategy

The example uses a clear priority strategy:

- **Simple Rules**: Priorities 1-9
  - 1: Simple SQL injection
  - 2: Simple XSS
  - 3: Simple rate limiting
  - 4: Simple geo blocking

- **Advanced Rules**: Priorities 10-19
  - 10: Advanced SQL injection (header)
  - 11: Advanced XSS (query string)
  - 12: Advanced rate limiting (forwarded IP)
  - 13: Advanced geo blocking (extended)
  - 14: Advanced size constraint
  - 15: Advanced bot detection

This strategy allows for:
- Easy insertion of new rules
- Clear separation between rule types
- Logical processing order

## 🔍 Monitoring & Observability

### CloudWatch Metrics

Each rule generates individual metrics:

**Simple Rules**:
- `simple_sqli_rule`
- `simple_xss_rule`
- `simple_rate_limit`
- `simple_geo_block`

**Advanced Rules**:
- `advanced_sqli_header`
- `advanced_xss_query`
- `advanced_rate_limit`
- `advanced_geo_block`
- `advanced_size_constraint`
- `advanced_bot_detection`

### Key Metrics to Monitor

```bash
# Rule-specific metrics
aws cloudwatch get-metric-statistics \
  --namespace AWS/WAFV2 \
  --metric-name BlockedRequests \
  --dimensions Name=RuleGroup,Value=custom-rule-group-hybrid

# Overall rule group performance
aws cloudwatch get-metric-statistics \
  --namespace AWS/WAFV2 \
  --metric-name AllowedRequests \
  --dimensions Name=RuleGroup,Value=custom-rule-group-hybrid
```

## 💰 Cost Analysis

### WCU (Web ACL Capacity Units) Breakdown

**Simple Rules** (~40 WCUs):
- SQL injection: ~10 WCUs
- XSS protection: ~10 WCUs
- Rate limiting: ~2 WCUs
- Geo blocking: ~1 WCU

**Advanced Rules** (~80 WCUs):
- Header SQL injection: ~15 WCUs
- Query XSS: ~15 WCUs
- Forwarded IP rate limiting: ~2 WCUs
- Extended geo blocking: ~1 WCU
- Size constraint: ~10 WCUs
- Bot detection: ~12 WCUs

**Total Estimated WCUs**: ~120 WCUs

### Monthly Cost Estimate
- **Rule Group**: $1.00/month
- **WCU Usage**: ~$0.07/month (120 WCUs)
- **Total**: ~$1.07/month

## 🛡️ Security Coverage

### Protection Matrix

| Threat Type | Simple Rules | Advanced Rules | Coverage Level |
|-------------|--------------|----------------|----------------|
| SQL Injection | Body inspection | Header inspection | Comprehensive |
| XSS Attacks | URI path | Query string | Multi-vector |
| DDoS/Brute Force | IP-based limiting | Forwarded IP limiting | Load balancer aware |
| Geographic Threats | Basic blocking | Extended blocking | Enhanced |
| Large Payloads | ❌ | 16KB limit | Protected |
| Bot Attacks | ❌ | User-Agent analysis | Detected |

### Security Layers

1. **Input Validation**: Size constraints and format checking
2. **Injection Prevention**: SQL injection and XSS protection
3. **Rate Limiting**: Multi-level DDoS protection
4. **Geographic Control**: Basic and extended country blocking
5. **Bot Detection**: Automated tool identification

## 🔧 Migration Strategy

### From Simple to Advanced

1. **Start with Simple Rules**:
   ```hcl
   {
     type = "sqli"
     field_to_match = "body"
   }
   ```

2. **Gradually Add Advanced Rules**:
   ```hcl
   {
     statement_config = {
       sqli_match_statement = {
         field_to_match = { single_header = { name = "custom-header" } }
         text_transformation = { type = "URL_DECODE" }
       }
     }
   }
   ```

3. **Monitor and Validate**:
   - Use count mode for new advanced rules
   - Monitor CloudWatch metrics
   - Validate no false positives

4. **Replace Simple Rules**:
   - Remove simple rules once advanced rules are validated
   - Update priorities accordingly

## 🧪 Testing Strategy

### Validation Steps

1. **Configuration Testing**:
   ```bash
   terraform validate
   terraform plan
   ```

2. **Rule Testing**:
   - Test each rule type individually
   - Validate priority ordering
   - Check WCU capacity usage

3. **Integration Testing**:
   - Deploy to staging environment
   - Test with real traffic patterns
   - Monitor false positive rates

### Test Cases

```bash
# Test SQL injection detection
curl -X POST "https://example.com/api" \
  -d "user=admin' OR '1'='1"

# Test XSS detection
curl "https://example.com/search?q=<script>alert('xss')</script>"

# Test rate limiting
for i in {1..1100}; do curl "https://example.com/"; done

# Test geographic blocking (requires VPN/proxy)
curl --header "CF-IPCountry: CN" "https://example.com/"
```

## 🚨 Troubleshooting

### Common Issues

1. **Priority Conflicts**:
   ```
   Error: Duplicate rule priorities
   Solution: Ensure unique priorities across all rules
   ```

2. **WCU Capacity Exceeded**:
   ```
   Error: Rule group capacity exceeded
   Solution: Increase capacity or optimize rules
   ```

3. **Invalid Configuration Mix**:
   ```
   Error: Cannot use both type and statement_config
   Solution: Use either type OR statement_config, not both
   ```

### Debug Commands

```bash
# Validate configuration
terraform validate

# Check rule group details
aws wafv2 describe-rule-group \
  --scope REGIONAL \
  --id <rule-group-id>

# Monitor rule performance
aws logs filter-log-events \
  --log-group-name aws-waf-logs-<name>
```

## 📚 Best Practices

### Configuration Management

1. **Use Version Control**: Track all configuration changes
2. **Environment Separation**: Different configs for dev/staging/prod
3. **Gradual Rollout**: Test in staging before production
4. **Documentation**: Document rule purposes and thresholds

### Security Practices

1. **Defense in Depth**: Use multiple rule types together
2. **Regular Updates**: Update threat patterns and country lists
3. **Monitoring**: Set up alerts for blocked requests
4. **Testing**: Regular penetration testing and validation

### Performance Optimization

1. **Rule Ordering**: Place most common blocks first
2. **WCU Management**: Monitor and optimize capacity usage
3. **Caching**: Use CloudFront for additional performance
4. **Regional Deployment**: Deploy close to users

---

## Summary

The Custom Rules Hybrid example demonstrates:

- ✅ **Backward Compatibility**: Simple rules continue to work
- ✅ **Migration Path**: Clear upgrade strategy from simple to advanced
- ✅ **Comprehensive Protection**: 10 rules covering major threat vectors
- ✅ **Cost Effective**: ~$1.07/month for enterprise-grade protection
- ✅ **Production Ready**: Monitoring, validation, and troubleshooting included

This hybrid approach allows teams to adopt advanced WAF capabilities at their own pace while maintaining existing simple configurations.