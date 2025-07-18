# Enhanced WAF Rule Group Example

This example demonstrates the comprehensive protection capabilities of the enhanced WAF rule group module, showcasing both simple type-based and advanced object-based rule configurations.

## 🛡️ Protection Types Supported

### ✅ SQL Injection Detection
- **Configurable Field Matching**: Body, URI path, query string, headers, all query arguments
- **Text Transformations**: URL decode, HTML entity decode, lowercase, compress whitespace
- **Advanced Targeting**: Single header inspection, method-based filtering

### ✅ XSS Protection  
- **Multi-Field Inspection**: Query strings, request body, headers, URI paths
- **Transformation Support**: HTML entity decode, URL decode, case normalization
- **Context-Aware**: Different transformations for different attack vectors

### ✅ Rate-Based DDoS Protection
- **IP-Based Limiting**: Traditional per-IP rate limiting
- **Forwarded IP Support**: Rate limiting behind load balancers/proxies
- **Configurable Thresholds**: Custom request limits per 5-minute window
- **Action Flexibility**: Block, count, or allow with monitoring

### ✅ Geographic Blocking
- **Country-Level Control**: ISO 3166-1 alpha-2 country codes
- **High-Risk Region Blocking**: Pre-configured lists for common threat countries
- **Compliance Support**: Geographic restrictions for regulatory compliance

### ✅ Size Constraint Validation
- **Request Size Limits**: Body, URI path, query string, header size validation
- **Flexible Operators**: GT, LT, EQ, NE, GE, LE comparisons
- **DoS Prevention**: Prevent large payload attacks
- **Resource Protection**: Limit resource consumption

### ✅ Advanced Pattern Matching
- **Byte Match Statements**: Exact string matching with positional constraints
- **Bot Detection**: User-Agent analysis and scanner identification
- **Method Validation**: HTTP method restriction and monitoring
- **Custom String Patterns**: Flexible search with CONTAINS, STARTS_WITH, ENDS_WITH

## 📋 Example Configurations

### 1. Simple Rule Group (`simple_rule_group`)
**Purpose**: Easy-to-configure protection using type-based rules

```hcl
custom_rules = [
  {
    name        = "SimpleSQLi"
    type        = "sqli"
    field_to_match = "body"
    action      = "block"
  },
  {
    name        = "SimpleRateLimit"
    type        = "rate_based"
    rate_limit  = 1000
    action      = "block"
  }
]
```

**Features**:
- 🔒 SQL injection protection (body inspection)
- 🛡️ XSS protection (URI path inspection)  
- ⚡ Rate limiting (1000 req/5min per IP)
- 🌍 Geographic blocking (CN, RU, KP)
- 📏 Size constraints (10KB body limit)

### 2. Advanced Rule Group (`advanced_rule_group`)
**Purpose**: Full control with object-based statement configurations

```hcl
custom_rules = [
  {
    name = "AdvancedSQLiHeader"
    statement_config = {
      sqli_match_statement = {
        field_to_match = {
          single_header = { name = "x-custom-header" }
        }
        text_transformation = {
          priority = 1
          type     = "URL_DECODE"
        }
      }
    }
  }
]
```

**Features**:
- 🎯 Header-specific SQL injection detection
- 🔄 Multiple text transformations (URL decode, HTML decode)
- 🤖 Advanced bot detection via User-Agent analysis
- 🌐 Forwarded IP rate limiting (for load balancers)
- 📐 URI path size validation
- 🚫 Extended geographic blocking

### 3. Comprehensive Rule Group (`comprehensive_rule_group`)
**Purpose**: Multi-layered security with defense-in-depth approach

**Security Layers**:
1. **Input Validation**: Size constraints and format validation
2. **Injection Protection**: SQL injection and XSS prevention
3. **DDoS Protection**: Rate limiting and traffic shaping
4. **Geographic Security**: High-risk country blocking
5. **Bot Detection**: Scanner and automated tool identification
6. **Method Validation**: HTTP method restriction and monitoring

## 🚀 Usage

### Prerequisites
- AWS CLI configured with appropriate credentials
- Terraform >= 1.0
- WAF permissions in target AWS account

### Quick Start

1. **Initialize Terraform**:
   ```bash
   terraform init
   ```

2. **Review Configuration**:
   ```bash
   terraform plan
   ```

3. **Deploy Rule Groups**:
   ```bash
   terraform apply
   ```

4. **Use in WAF ACL**:
   ```hcl
   module "waf_acl" {
     source = "../../modules/waf"
     
     rule_group_arn_list = [
       {
         arn      = module.simple_rule_group.waf_rule_group_arn
         name     = "simple-protection"
         priority = 100
       },
       {
         arn      = module.advanced_rule_group.waf_rule_group_arn
         name     = "advanced-protection"
         priority = 200
       }
     ]
   }
   ```

### Customization

```hcl
# Override default values
variable "name" {
  default = "my-security-rules"
}

variable "scope" {
  default = "CLOUDFRONT"  # For CloudFront distributions
}

# Custom country blocking
locals {
  high_risk_countries = ["CN", "RU", "KP", "IR", "SY", "CU", "SD"]
  rate_limit_threshold = 500  # Requests per 5 minutes
}
```

## 🔧 Configuration Options

### Field Matching Options
- `body`: Request body content
- `uri_path`: URL path component
- `query_string`: URL query parameters
- `all_query_arguments`: All query parameters
- `single_header`: Specific HTTP header
- `method`: HTTP method (GET, POST, etc.)

### Text Transformation Types
- `NONE`: No transformation
- `COMPRESS_WHITE_SPACE`: Remove extra whitespace
- `HTML_ENTITY_DECODE`: Decode HTML entities
- `LOWERCASE`: Convert to lowercase
- `CMD_LINE`: Command line normalization
- `URL_DECODE`: URL decode

### Positional Constraints (Byte Match)
- `EXACTLY`: Exact match
- `STARTS_WITH`: String starts with pattern
- `ENDS_WITH`: String ends with pattern
- `CONTAINS`: String contains pattern
- `CONTAINS_WORD`: Contains whole word

### Comparison Operators (Size Constraint)
- `EQ`: Equal to
- `NE`: Not equal to
- `LE`: Less than or equal to
- `LT`: Less than
- `GE`: Greater than or equal to
- `GT`: Greater than

## 📊 Monitoring & Metrics

Each rule generates CloudWatch metrics:

- **Request Counts**: Total requests evaluated
- **Block Counts**: Requests blocked by rule
- **Allow Counts**: Requests allowed by rule
- **Sample Requests**: Detailed request samples

### Key Metrics to Monitor
```
AWS/WAFV2/RuleGroup/BlockedRequests
AWS/WAFV2/RuleGroup/AllowedRequests
AWS/WAFV2/RuleGroup/CountedRequests
AWS/WAFV2/RuleGroup/SampledRequests
```

## 💰 Cost Optimization

### WCU (Web ACL Capacity Units) Usage
- **Simple Rules**: ~5-10 WCUs each
- **Advanced Rules**: ~10-20 WCUs each
- **Rate-Based Rules**: ~2 WCUs each
- **Geo Match Rules**: ~1 WCU each

### Cost Estimation
- **Rule Group**: $1.00/month per rule group
- **WCU Usage**: $0.60/million WCUs per month
- **Requests**: $0.60/million requests

**Example Monthly Cost**:
- Simple Rule Group (200 WCUs): ~$1.12
- Advanced Rule Group (300 WCUs): ~$1.18
- Comprehensive Rule Group (500 WCUs): ~$1.30

## 🔒 Security Best Practices

### 1. Layered Defense
- Combine multiple rule types for comprehensive protection
- Use both blocking and counting rules for gradual deployment
- Implement rate limiting at multiple levels

### 2. Monitoring & Alerting
- Set up CloudWatch alarms for blocked requests
- Monitor false positive rates
- Regular review of rule effectiveness

### 3. Testing & Validation
- Test rules in count mode before blocking
- Use staging environments for rule validation
- Implement gradual rollout strategies

### 4. Maintenance
- Regular updates to geographic blocking lists
- Periodic review of rate limiting thresholds
- Update bot detection patterns based on threat intelligence

## 🚨 Troubleshooting

### Common Issues

1. **WCU Capacity Exceeded**
   ```
   Error: Rule group capacity exceeded
   Solution: Increase capacity or optimize rules
   ```

2. **Priority Conflicts**
   ```
   Error: Duplicate rule priorities
   Solution: Ensure unique priorities across all rules
   ```

3. **Invalid Country Codes**
   ```
   Error: Invalid country code
   Solution: Use ISO 3166-1 alpha-2 codes (e.g., "US", "GB")
   ```

### Debug Commands
```bash
# Validate configuration
terraform validate

# Check rule group capacity
aws wafv2 describe-rule-group --scope REGIONAL --id <rule-group-id>

# Monitor rule metrics
aws cloudwatch get-metric-statistics --namespace AWS/WAFV2
```

## 📚 Additional Resources

- [AWS WAF Developer Guide](https://docs.aws.amazon.com/waf/)
- [WAF Rule Statement Reference](https://docs.aws.amazon.com/waf/latest/developerguide/waf-rule-statements.html)
- [CloudWatch Metrics for WAF](https://docs.aws.amazon.com/waf/latest/developerguide/monitoring-cloudwatch.html)
- [WAF Security Best Practices](https://docs.aws.amazon.com/waf/latest/developerguide/security-best-practices.html)