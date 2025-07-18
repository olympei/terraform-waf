# Custom Rule Group WAF ACL Example

This comprehensive example demonstrates how to create custom WAF rule groups and integrate them with WAF ACLs. It showcases both simple type-based rules and advanced object-based configurations, providing multiple deployment patterns for different security requirements.

## 🎯 Purpose

This example illustrates:

1. **Custom Rule Group Creation**: Building reusable security rule groups
2. **WAF ACL Integration**: Connecting rule groups to Web ACLs
3. **Multiple Configuration Approaches**: Simple vs. advanced rule definitions
4. **Layered Security**: Combining custom rules with AWS managed rules
5. **Production Patterns**: Real-world deployment scenarios

## 🏗️ Architecture Overview

The example creates:

- **2 Custom Rule Groups**: Basic and Advanced configurations
- **3 WAF ACLs**: Basic, Advanced, and Comprehensive deployments
- **Multiple Protection Layers**: Custom rules + AWS managed rules + inline rules

### Rule Group Types

#### 1. Basic Custom Rule Group
- **Simple Configuration**: Type-based rules for easy setup
- **3 Rules**: SQL injection, XSS, and rate limiting
- **Capacity**: 100 WCUs
- **Use Case**: Quick deployment with standard protection

#### 2. Advanced Custom Rule Group  
- **Object-Based Configuration**: Full control over rule statements
- **5 Rules**: Advanced SQLi, XSS, bot detection, geo-blocking, size constraints
- **Capacity**: 200 WCUs
- **Use Case**: Sophisticated threat protection with custom logic

## 📋 Detailed Configuration

### Basic Custom Rule Group Rules

#### 1. Basic SQL Injection Protection
```hcl
{
  name           = "BasicSQLiProtection"
  type           = "sqli"
  field_to_match = "body"
  action         = "block"
}
```
- **Target**: Request body
- **Action**: Block SQL injection attempts
- **Configuration**: Simple type-based

#### 2. Basic XSS Protection
```hcl
{
  name           = "BasicXSSProtection"
  type           = "xss"
  field_to_match = "uri_path"
  action         = "block"
}
```
- **Target**: URI path
- **Action**: Block XSS attempts
- **Configuration**: Simple type-based

#### 3. Basic Rate Limiting
```hcl
{
  name               = "BasicRateLimit"
  type               = "rate_based"
  rate_limit         = 2000
  aggregate_key_type = "IP"
  action             = "block"
}
```
- **Limit**: 2000 requests per 5 minutes per IP
- **Action**: Block excessive requests
- **Configuration**: Simple type-based

### Advanced Custom Rule Group Rules

#### 1. Advanced SQL Injection Detection
```hcl
{
  statement_config = {
    sqli_match_statement = {
      field_to_match = {
        all_query_arguments = {}
      }
      text_transformation = {
        priority = 1
        type     = "URL_DECODE"
      }
    }
  }
}
```
- **Target**: All query arguments
- **Transformation**: URL decode before analysis
- **Configuration**: Object-based with full control

#### 2. Advanced XSS Detection
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
- **Target**: Query string parameters
- **Transformation**: HTML entity decode
- **Configuration**: Object-based with custom transformations

#### 3. Advanced Bot Detection
```hcl
{
  statement_config = {
    byte_match_statement = {
      search_string         = "scanner"
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
- **Target**: User-Agent header
- **Pattern**: Contains "scanner" (case-insensitive)
- **Configuration**: Advanced pattern matching

#### 4. Advanced Geographic Blocking
```hcl
{
  statement_config = {
    geo_match_statement = {
      country_codes = ["CN", "RU", "KP", "IR"]
    }
  }
}
```
- **Target**: High-risk countries
- **Action**: Block requests from specified countries
- **Configuration**: Geographic access control

#### 5. Advanced Size Constraint
```hcl
{
  statement_config = {
    size_constraint_statement = {
      comparison_operator = "GT"
      size               = 8192
      field_to_match = {
        body = {}
      }
    }
  }
}
```
- **Target**: Request body
- **Limit**: 8KB maximum size
- **Configuration**: Flexible size validation

## 🚀 Deployment Options

### Option 1: Basic WAF ACL
- **Rule Groups**: Basic custom rule group only
- **Protection**: Standard SQLi, XSS, and rate limiting
- **Use Case**: Simple applications with basic security needs

### Option 2: Advanced WAF ACL
- **Rule Groups**: Advanced custom rule group only
- **Protection**: Sophisticated threat detection and blocking
- **Use Case**: Applications requiring advanced security controls

### Option 3: Comprehensive WAF ACL
- **Rule Groups**: Both basic and advanced custom rule groups
- **AWS Managed Rules**: Common rule set + known bad inputs
- **Inline Rules**: Additional API-specific rate limiting
- **Use Case**: Enterprise applications requiring multi-layer security

## 🛠️ Usage

### Prerequisites
- AWS CLI configured with appropriate credentials
- Terraform >= 1.0
- WAF permissions in target AWS account

### Quick Start

1. **Initialize Terraform**:
   ```bash
   cd examples/custom_rule_group_waf_acl
   terraform init
   ```

2. **Review Configuration**:
   ```bash
   terraform plan
   ```

3. **Deploy Resources**:
   ```bash
   terraform apply
   ```

4. **Verify Deployment**:
   ```bash
   terraform output deployment_summary
   ```

### Customization

#### Modify ALB Association
```hcl
variable "alb_arn_list" {
  default = [
    "arn:aws:elasticloadbalancing:us-east-1:YOUR-ACCOUNT:loadbalancer/app/your-alb/YOUR-ID"
  ]
}
```

#### Adjust Rate Limiting
```hcl
# In basic rule group
rate_limit = 1000  # Reduce to 1000 requests per 5 minutes

# In comprehensive inline rules
limit = 50  # Stricter API rate limiting
```

#### Update Geographic Blocking
```hcl
country_codes = ["CN", "RU", "KP", "IR", "SY", "CU"]  # Add more countries
```

#### Change Scope for CloudFront
```hcl
variable "scope" {
  default = "CLOUDFRONT"  # For CloudFront distributions
}
```

## 📊 Resource Summary

### Created Resources

| Resource Type | Count | Description |
|---------------|-------|-------------|
| Rule Groups | 2 | Basic (3 rules) + Advanced (5 rules) |
| WAF ACLs | 3 | Basic, Advanced, Comprehensive |
| Total Rules | 9 | 3 basic + 5 advanced + 1 inline |

### Priority Allocation

| Rule Type | Priority Range | Count |
|-----------|----------------|-------|
| Basic Custom Rules | 1-3 | 3 |
| Advanced Custom Rules | 10-14 | 5 |
| Custom Rule Groups | 100-200 | 2 |
| AWS Managed Rules | 300-301 | 2 |
| Inline Rules | 400+ | 1 |

## 💰 Cost Analysis

### WCU Usage Breakdown

**Basic Rule Group** (~50 WCUs):
- SQL injection: ~15 WCUs
- XSS protection: ~15 WCUs
- Rate limiting: ~2 WCUs

**Advanced Rule Group** (~100 WCUs):
- Advanced SQLi: ~20 WCUs
- Advanced XSS: ~20 WCUs
- Bot detection: ~15 WCUs
- Geo blocking: ~1 WCU
- Size constraint: ~10 WCUs

### Monthly Cost Estimate

**Per Deployment**:
- **Basic WAF ACL**: ~$1.03/month (Rule group + 50 WCUs)
- **Advanced WAF ACL**: ~$1.06/month (Rule group + 100 WCUs)
- **Comprehensive WAF ACL**: ~$1.09/month (2 rule groups + 150 WCUs + managed rules)

**Total for All Examples**: ~$3.18/month

## 🔍 Monitoring & Observability

### CloudWatch Metrics

Each rule generates individual metrics:

**Basic Rule Group**:
- `basic_sqli_protection`
- `basic_xss_protection`
- `basic_rate_limit`

**Advanced Rule Group**:
- `advanced_sqli_detection`
- `advanced_xss_detection`
- `advanced_bot_detection`
- `advanced_geo_blocking`
- `advanced_size_constraint`

### Monitoring Commands

```bash
# View rule group metrics
aws cloudwatch get-metric-statistics \
  --namespace AWS/WAFV2 \
  --metric-name BlockedRequests \
  --dimensions Name=RuleGroup,Value=custom-rule-group-waf-basic-rules

# View WAF ACL metrics
aws cloudwatch get-metric-statistics \
  --namespace AWS/WAFV2 \
  --metric-name AllowedRequests \
  --dimensions Name=WebACL,Value=custom-rule-group-waf-basic
```

## 🛡️ Security Coverage Matrix

| Threat Vector | Basic Rules | Advanced Rules | AWS Managed | Coverage Level |
|---------------|-------------|----------------|-------------|----------------|
| SQL Injection | Body inspection | Query args + URL decode | Common patterns | Comprehensive |
| XSS Attacks | URI path | Query string + HTML decode | Common patterns | Multi-layer |
| DDoS/Rate Limiting | IP-based (2000/5min) | API-specific (100/5min) | ❌ | Graduated |
| Bot/Scanner Detection | ❌ | User-Agent analysis | Known bad inputs | Advanced |
| Geographic Threats | ❌ | 4 high-risk countries | ❌ | Targeted |
| Large Payloads | ❌ | 8KB body limit | ❌ | Protected |
| Known Attack Patterns | ❌ | ❌ | AWS intelligence | Enterprise |

## 🧪 Testing Strategy

### Validation Tests

1. **Configuration Testing**:
   ```bash
   terraform validate
   terraform plan -detailed-exitcode
   ```

2. **Rule Testing**:
   ```bash
   # Test SQL injection detection
   curl -X POST "https://your-alb.com/api" -d "user=admin' OR '1'='1"
   
   # Test XSS detection
   curl "https://your-alb.com/search?q=<script>alert('xss')</script>"
   
   # Test rate limiting
   for i in {1..2100}; do curl "https://your-alb.com/"; done
   ```

3. **Geographic Testing** (requires VPN):
   ```bash
   # Simulate request from blocked country
   curl --header "CF-IPCountry: CN" "https://your-alb.com/"
   ```

### Integration Testing

```bash
# Deploy to staging environment
terraform workspace select staging
terraform apply

# Run automated security tests
./run_security_tests.sh

# Monitor CloudWatch metrics
aws logs tail aws-waf-logs-custom-rule-group-waf --follow
```

## 🚨 Troubleshooting

### Common Issues

1. **Module Not Found**:
   ```
   Error: Module not installed
   Solution: Run terraform init
   ```

2. **Priority Conflicts**:
   ```
   Error: Duplicate priorities detected
   Solution: Check priority ranges in different rule groups
   ```

3. **WCU Capacity Exceeded**:
   ```
   Error: Rule group capacity exceeded
   Solution: Increase capacity or optimize rules
   ```

4. **Invalid ALB ARN**:
   ```
   Error: Invalid resource ARN
   Solution: Update alb_arn_list with valid ARNs
   ```

### Debug Commands

```bash
# Check rule group details
aws wafv2 describe-rule-group --scope REGIONAL --id <rule-group-id>

# List all WAF ACLs
aws wafv2 list-web-acls --scope REGIONAL

# View WAF logs
aws logs describe-log-groups --log-group-name-prefix aws-waf-logs
```

## 📚 Best Practices

### Configuration Management

1. **Environment Separation**: Use different configurations for dev/staging/prod
2. **Version Control**: Track all configuration changes
3. **Gradual Rollout**: Test in staging before production deployment
4. **Documentation**: Document rule purposes and business justification

### Security Practices

1. **Defense in Depth**: Use multiple rule types and layers
2. **Regular Updates**: Update threat patterns and geographic lists
3. **Monitoring**: Set up CloudWatch alarms for security events
4. **Testing**: Regular penetration testing and rule validation

### Performance Optimization

1. **Rule Ordering**: Place most common blocks first (lower priorities)
2. **WCU Management**: Monitor capacity usage and optimize rules
3. **Caching**: Use CloudFront for additional performance benefits
4. **Regional Deployment**: Deploy WAF close to your users

## 🔄 Migration Guide

### From Legacy Configuration

If migrating from older WAF configurations:

1. **Assess Current Rules**: Document existing protection
2. **Map to New Structure**: Convert to type-based or object-based rules
3. **Test in Staging**: Validate new configuration thoroughly
4. **Gradual Migration**: Replace rules incrementally
5. **Monitor Impact**: Watch for false positives or performance issues

### Upgrade Path

1. **Start with Basic**: Deploy basic rule group first
2. **Add Advanced**: Introduce advanced rules gradually
3. **Enable Monitoring**: Set up CloudWatch dashboards
4. **Optimize Performance**: Tune rules based on traffic patterns
5. **Scale Up**: Add AWS managed rules and inline rules as needed

---

## Summary

The Custom Rule Group WAF ACL example provides:

- ✅ **Comprehensive Protection**: 9 rules covering major threat vectors
- ✅ **Flexible Configuration**: Both simple and advanced rule options
- ✅ **Multiple Deployment Patterns**: Basic, advanced, and comprehensive options
- ✅ **Production Ready**: Complete monitoring, testing, and troubleshooting
- ✅ **Cost Effective**: ~$3.18/month for all three deployment options
- ✅ **Enterprise Grade**: Suitable for production workloads

This example serves as a complete reference for implementing custom WAF rule groups in production environments.