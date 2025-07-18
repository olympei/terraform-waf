# Basic WAF Example

This example demonstrates the simplest way to deploy a WAF ACL with essential protection using AWS managed rules. It's perfect for getting started with AWS WAF or for applications that need basic web security without complex custom rules.

## 🎯 Purpose

The basic example serves as:

1. **Getting Started Guide**: Simplest WAF deployment possible
2. **AWS Managed Rules Demo**: Shows how to use AWS-provided security rules
3. **Foundation Template**: Base configuration for more complex deployments
4. **Quick Protection**: Immediate security for web applications

## 🏗️ What This Example Creates

### WAF ACL with AWS Managed Rules
- **Name**: `basic-waf` (configurable)
- **Scope**: `REGIONAL` (can be changed to `CLOUDFRONT`)
- **Default Action**: `allow` (allows traffic by default, rules can block)
- **Protection Level**: Essential web application security

### AWS Managed Rule Groups Included

#### 1. AWSManagedRulesCommonRuleSet (Priority 100)
- **Purpose**: Core web application protection
- **Protects Against**:
  - Cross-site scripting (XSS)
  - SQL injection attacks
  - Local file inclusion (LFI)
  - Remote file inclusion (RFI)
  - Common web exploits

#### 2. AWSManagedRulesSQLiRuleSet (Priority 200)
- **Purpose**: Advanced SQL injection protection
- **Protects Against**:
  - SQL injection in request body
  - SQL injection in query strings
  - SQL injection in headers
  - Database-specific attack patterns

## 🚀 Usage

### Prerequisites
- AWS CLI configured with appropriate credentials
- Terraform >= 1.0
- WAF permissions in target AWS account

### Quick Deployment

1. **Navigate to the basic example**:
   ```bash
   cd examples/basic
   ```

2. **Initialize Terraform**:
   ```bash
   terraform init
   ```

3. **Review the configuration**:
   ```bash
   terraform plan
   ```

4. **Deploy the WAF**:
   ```bash
   terraform apply
   ```

5. **View the results**:
   ```bash
   terraform output basic_waf_summary
   ```

### Customization Options

#### Change WAF Name
```bash
terraform apply -var="name=my-app-waf"
```

#### Deploy for CloudFront
```bash
terraform apply -var="scope=CLOUDFRONT"
```

#### Associate with ALB
```bash
terraform apply -var='alb_arn_list=["arn:aws:elasticloadbalancing:us-east-1:123456789012:loadbalancer/app/my-alb/1234567890123456"]'
```

#### Change Default Action to Block
```bash
terraform apply -var="default_action=block"
```

### Using terraform.tfvars

Create a `terraform.tfvars` file:
```hcl
name           = "my-basic-waf"
scope          = "REGIONAL"
default_action = "allow"
alb_arn_list   = [
  "arn:aws:elasticloadbalancing:us-east-1:123456789012:loadbalancer/app/my-alb/1234567890123456"
]
tags = {
  Environment = "production"
  Application = "my-web-app"
  Owner       = "security-team"
}
```

## 📊 Configuration Details

### Rule Priority Strategy
- **AWS Managed Rules**: Priorities 100-200
- **Future Custom Rules**: Can use priorities 300+
- **Rule Groups**: Can use priorities 50-99

### Default Behavior
- **Default Action**: `allow` (recommended for most applications)
- **Rule Actions**: AWS managed rules will `block` malicious requests
- **Override Actions**: Set to `none` (rules act as configured)

### Resource Tagging
All resources are tagged with:
- Environment information
- Purpose identification
- Example source tracking

## 💰 Cost Analysis

### AWS WAF Pricing (US East 1)
- **Web ACL**: $1.00 per month
- **Rule Groups**: $1.00 per month per rule group (2 AWS managed = $2.00)
- **WCU Usage**: AWS managed rules use ~20 WCUs total
- **WCU Cost**: $0.60 per million WCUs per month (~$0.01 for basic usage)
- **Requests**: $0.60 per million requests

### Monthly Cost Estimate
- **Base Cost**: $3.00/month (Web ACL + 2 rule groups)
- **Usage Cost**: ~$0.01/month (for typical small application)
- **Total**: ~$3.01/month

### Cost Optimization Tips
1. Monitor WCU usage in CloudWatch
2. Remove unused rule groups if not needed
3. Use count mode for testing before blocking
4. Consider request volume for cost planning

## 🔍 Monitoring & Observability

### CloudWatch Metrics Available
- `AllowedRequests`: Requests allowed by the WAF
- `BlockedRequests`: Requests blocked by the WAF
- `CountedRequests`: Requests counted (if using count mode)
- `SampledRequests`: Sample of requests for analysis

### Viewing Metrics
```bash
# View blocked requests
aws cloudwatch get-metric-statistics \
  --namespace AWS/WAFV2 \
  --metric-name BlockedRequests \
  --dimensions Name=WebACL,Value=basic-waf \
  --start-time 2024-01-01T00:00:00Z \
  --end-time 2024-01-02T00:00:00Z \
  --period 3600 \
  --statistics Sum

# View allowed requests
aws cloudwatch get-metric-statistics \
  --namespace AWS/WAFV2 \
  --metric-name AllowedRequests \
  --dimensions Name=WebACL,Value=basic-waf \
  --start-time 2024-01-01T00:00:00Z \
  --end-time 2024-01-02T00:00:00Z \
  --period 3600 \
  --statistics Sum
```

### Setting Up Alarms
```bash
# Create alarm for high blocked requests
aws cloudwatch put-metric-alarm \
  --alarm-name "WAF-High-Blocked-Requests" \
  --alarm-description "Alert when WAF blocks many requests" \
  --metric-name BlockedRequests \
  --namespace AWS/WAFV2 \
  --statistic Sum \
  --period 300 \
  --threshold 100 \
  --comparison-operator GreaterThanThreshold \
  --dimensions Name=WebACL,Value=basic-waf
```

## 🛡️ Security Coverage

### Protection Provided
| Attack Type | Protection Level | Rule Group |
|-------------|------------------|------------|
| XSS (Cross-site scripting) | High | Common Rule Set |
| SQL Injection | Very High | Common + SQLi Rule Sets |
| Local File Inclusion | High | Common Rule Set |
| Remote File Inclusion | High | Common Rule Set |
| Common Web Exploits | High | Common Rule Set |
| Path Traversal | Medium | Common Rule Set |
| Command Injection | Medium | Common Rule Set |

### What's NOT Covered (Consider for Advanced Examples)
- Rate limiting / DDoS protection
- Geographic blocking
- Bot detection
- Custom application-specific rules
- Size constraint validation
- Custom header inspection

## 🧪 Testing the WAF

### Basic Functionality Test
```bash
# Test normal request (should be allowed)
curl -v https://your-application.com/

# Test SQL injection (should be blocked)
curl -v "https://your-application.com/search?q='; DROP TABLE users; --"

# Test XSS (should be blocked)
curl -v "https://your-application.com/search?q=<script>alert('xss')</script>"
```

### Monitoring Test Results
Check CloudWatch metrics after testing to see:
- Blocked request count increases
- WAF logs show blocked requests
- Application remains accessible for legitimate traffic

## 🚨 Troubleshooting

### Common Issues

1. **WAF Not Blocking Expected Requests**
   - Check rule override actions are set to "none"
   - Verify default action is "allow"
   - Review CloudWatch logs for rule evaluation

2. **Legitimate Traffic Being Blocked**
   - Review sampled requests in AWS console
   - Consider using "count" mode temporarily
   - Check for false positives in application patterns

3. **High Costs**
   - Monitor WCU usage in CloudWatch
   - Review request volume and patterns
   - Consider optimizing rule configurations

### Debug Commands
```bash
# Check WAF configuration
aws wafv2 describe-web-acl --scope REGIONAL --id <web-acl-id>

# View recent sampled requests
aws wafv2 get-sampled-requests --web-acl-arn <web-acl-arn> --rule-metric-name <rule-name> --scope REGIONAL --time-window StartTime=<start>,EndTime=<end> --max-items 100

# Check rule group details
aws wafv2 describe-managed-rule-group --vendor-name AWS --name AWSManagedRulesCommonRuleSet --scope REGIONAL
```

## 🔄 Next Steps

After deploying the basic example, consider:

1. **Add Custom Rules**: Explore the `custom_rules_hybrid` example
2. **Create Rule Groups**: Check the `enhanced_rule_group` example
3. **Advanced Configuration**: Review the `waf_acl_module` example
4. **Logging**: Set up WAF logging with the `log_group` example
5. **Monitoring**: Create CloudWatch dashboards and alarms

## 📚 Related Examples

- **enhanced_rule_group**: Custom rule groups with advanced protection
- **custom_rules_hybrid**: Mix of simple and advanced custom rules
- **waf_acl_module**: Comprehensive WAF with multiple rule types
- **custom_rule_group_waf_acl**: Complete custom rule group integration

---

## Summary

The basic example provides:

- ✅ **Quick Deployment**: Get WAF protection in minutes
- ✅ **Essential Security**: AWS managed rules for common threats
- ✅ **Cost Effective**: ~$3/month for basic protection
- ✅ **Production Ready**: Suitable for small to medium applications
- ✅ **Extensible**: Foundation for more complex configurations
- ✅ **Well Monitored**: CloudWatch integration included

Perfect for developers who need immediate web application security without complex configuration!