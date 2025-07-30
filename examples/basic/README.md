# Basic WAF Example

This example demonstrates a simple AWS WAF v2 deployment with essential protection rules including AWS managed rules and custom inline rules for XSS protection and size restrictions.

## Features

### AWS Managed Rules
- **AWSManagedRulesCommonRuleSet** (Priority 100): Core protection against common attacks
- **AWSManagedRulesSQLiRuleSet** (Priority 200): SQL injection protection

### Custom Inline Rules
- **CrossSiteScripting_BODY** (Priority 300): Blocks XSS attempts in request body
- **SizeRestrictions_BODY** (Priority 301): Blocks requests with body size > 8KB

## Configuration

### Variables

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `name` | string | `"basic-waf"` | Name of the WAF ACL |
| `scope` | string | `"REGIONAL"` | WAF scope (REGIONAL/CLOUDFRONT) |
| `default_action` | string | `"allow"` | Default action (allow/block) |
| `alb_arn_list` | list(string) | `[]` | List of ALB ARNs to associate |
| `tags` | map(string) | See main.tf | Resource tags |

### Custom Rules Details

#### CrossSiteScripting_BODY Rule
```hcl
{
  name        = "CrossSiteScripting_BODY"
  priority    = 300
  action      = "block"
  metric_name = "CrossSiteScripting_BODY"
  statement_config = {
    xss_match_statement = {
      field_to_match = {
        body = {}  # Inspects request body
      }
      text_transformation = {
        priority = 1
        type     = "HTML_ENTITY_DECODE"  # Decodes HTML entities before inspection
      }
    }
  }
}
```

**Purpose**: Protects against Cross-Site Scripting (XSS) attacks by inspecting the request body for malicious scripts.

**How it works**:
1. Inspects the HTTP request body
2. Applies HTML entity decoding transformation
3. Checks for XSS patterns
4. Blocks requests containing XSS attempts

#### SizeRestrictions_BODY Rule
```hcl
{
  name        = "SizeRestrictions_BODY"
  priority    = 301
  action      = "block"
  metric_name = "SizeRestrictions_BODY"
  statement_config = {
    size_constraint_statement = {
      comparison_operator = "GT"
      size                = 8192  # 8KB limit
      field_to_match = {
        body = {}  # Inspects request body size
      }
      text_transformation = {
        priority = 0
        type     = "NONE"  # No transformation needed for size check
      }
    }
  }
}
```

**Purpose**: Prevents large payload attacks and helps control bandwidth usage by limiting request body size.

**How it works**:
1. Measures the size of the HTTP request body
2. Compares against the 8KB (8192 bytes) limit
3. Blocks requests with body size greater than the limit
4. Helps prevent DoS attacks using large payloads

## Deployment

### Quick Start
```bash
# Clone the repository
git clone <repository-url>
cd waf-module-v1/examples/basic

# Initialize Terraform
terraform init

# Plan the deployment
terraform plan

# Apply the configuration
terraform apply
```

### With Custom Variables
```bash
# Create a terraform.tfvars file
cat > terraform.tfvars << EOF
name = "my-basic-waf"
scope = "REGIONAL"
default_action = "allow"
alb_arn_list = [
  "arn:aws:elasticloadbalancing:us-east-1:123456789012:loadbalancer/app/my-alb/1234567890123456"
]
tags = {
  Environment = "development"
  Application = "web-app"
  Owner       = "dev-team"
}
EOF

# Deploy with custom variables
terraform apply -var-file="terraform.tfvars"
```

## Outputs

After deployment, you can view the configuration details:

```bash
# View WAF ACL information
terraform output waf_acl_arn
terraform output waf_acl_id

# View complete configuration summary
terraform output basic_waf_summary

# View custom rules details
terraform output custom_rules_details
```

## Monitoring

### CloudWatch Metrics

The WAF automatically creates CloudWatch metrics for monitoring:

- `AllowedRequests`: Number of requests allowed
- `BlockedRequests`: Number of requests blocked
- `CrossSiteScripting_BODY`: XSS attempts blocked
- `SizeRestrictions_BODY`: Large payload requests blocked

### Viewing Metrics
```bash
# View blocked requests in the last hour
aws cloudwatch get-metric-statistics \
  --namespace AWS/WAFV2 \
  --metric-name BlockedRequests \
  --dimensions Name=WebACL,Value=basic-waf \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --statistics Sum

# View XSS blocks specifically
aws cloudwatch get-metric-statistics \
  --namespace AWS/WAFV2 \
  --metric-name CrossSiteScripting_BODY \
  --dimensions Name=WebACL,Value=basic-waf \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --statistics Sum
```

## Testing

### Test XSS Protection
```bash
# This request should be blocked by the XSS rule
curl -X POST https://your-domain.com/api/test \
  -H "Content-Type: application/json" \
  -d '{"comment": "<script>alert(\"XSS\")</script>"}'
```

### Test Size Restriction
```bash
# This request should be blocked by the size restriction rule
curl -X POST https://your-domain.com/api/test \
  -H "Content-Type: application/json" \
  -d "$(python3 -c 'print("{\"data\": \"" + "A" * 10000 + "\"}")')"
```

## Use Cases

This basic WAF configuration is ideal for:

- **Development environments**: Quick protection setup
- **Small web applications**: Essential security without complexity
- **Learning and testing**: Understanding WAF rule behavior
- **Proof of concept**: Demonstrating WAF capabilities
- **Foundation for expansion**: Starting point for more complex configurations

## Cost Estimation

**Monthly costs** (approximate):
- WAF ACL: $1.00
- Rule evaluations: $0.60 per million requests
- AWS managed rules: $2.00 (2 rule groups)
- Custom rules: Minimal additional cost

**Total estimated cost**: ~$3-5/month for typical small application traffic

## Security Considerations

### What This Configuration Protects Against
- ✅ SQL injection attacks (AWS managed rule)
- ✅ Common web exploits (AWS managed rule)
- ✅ Cross-site scripting (XSS) in request body
- ✅ Large payload DoS attacks
- ✅ Basic web application attacks

### What This Configuration Does NOT Protect Against
- ❌ Advanced persistent threats (APT)
- ❌ DDoS attacks (use AWS Shield)
- ❌ Application-specific business logic attacks
- ❌ Zero-day exploits
- ❌ Social engineering attacks

### Recommendations for Production
For production environments, consider upgrading to:
- [Enterprise Zero Trust WAF](../enterprise_zero_trust_waf/)
- [Enterprise Secure WAF](../enterprise_secure_waf/)

These provide additional protection including:
- Geographic blocking
- Rate limiting
- Advanced threat protection
- Comprehensive logging
- Compliance features

## Troubleshooting

### Common Issues

#### False Positives
If legitimate requests are being blocked:

1. Check CloudWatch metrics to identify which rule is blocking
2. Review the request content for potential triggers
3. Consider adjusting rule sensitivity or adding exceptions

#### Size Limit Too Restrictive
If the 8KB body size limit is too small:

1. Increase the size limit in the rule configuration
2. Consider different limits for different endpoints
3. Monitor actual request sizes in your application

#### XSS Rule Too Sensitive
If the XSS rule blocks legitimate content:

1. Review the HTML content being submitted
2. Consider using different text transformations
3. Add specific exceptions for known safe patterns

### Getting Help

- **Documentation**: Check the main module documentation
- **Issues**: Report bugs on GitHub
- **Community**: Ask questions on Stack Overflow with tags `aws-waf` and `terraform`

## Next Steps

After deploying this basic WAF:

1. **Monitor metrics** to understand traffic patterns
2. **Test thoroughly** with your application
3. **Consider upgrades** to enterprise configurations for production
4. **Implement logging** for better visibility
5. **Add more rules** based on your specific security needs