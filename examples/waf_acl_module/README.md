# WAF ACL Module Example

This example demonstrates comprehensive usage of the WAF module, showcasing different configuration patterns and the new object-based inline rules functionality.

## What This Example Creates

### 1. Custom Rule Group (`custom_rule_group`)
- **Purpose**: Demonstrates creating a reusable WAF rule group
- **Rules**: 
  - SQL Injection protection (body inspection)
  - XSS protection (URI path inspection)
- **Capacity**: 100 WCUs

### 2. WAF ACL with Custom Rules (`waf_acl_with_custom_rules`)
- **Purpose**: Shows how to use custom rule groups in a WAF ACL
- **Configuration**: References the custom rule group created above
- **Priority**: 100

### 3. WAF ACL with AWS Managed Rules (`waf_acl_with_aws_managed`)
- **Purpose**: Demonstrates AWS managed rule group integration
- **Rules**:
  - `AWSManagedRulesCommonRuleSet` (Priority 200)
  - `AWSManagedRulesSQLiRuleSet` (Priority 201)
- **Override Action**: None (rules will block/allow as configured)

### 4. WAF ACL with Object-Based Inline Rules (`waf_acl_with_object_inline_rules`) ⭐ NEW
- **Purpose**: Showcases the new object-based inline rule functionality
- **Rules**:
  - **SQL Injection Detection** (Priority 300): Inspects request body
  - **XSS Detection** (Priority 301): Inspects query string with URL decode
  - **Rate Limiting** (Priority 302): 2000 requests per 5 minutes per IP
  - **Geo Blocking** (Priority 303): Blocks traffic from CN, RU, KP
  - **Size Constraint** (Priority 304): Blocks requests with body > 8KB

### 5. Comprehensive WAF ACL (`waf_acl_comprehensive`)
- **Purpose**: Combines multiple rule types in a single WAF ACL
- **Configuration**: 
  - Custom rule group (Priority 100)
  - AWS managed rules (Priorities 200-201)

## Usage

### Prerequisites
- AWS CLI configured with appropriate credentials
- Terraform >= 1.0
- Appropriate AWS permissions for WAF, CloudWatch, and KMS

### Deployment

1. **Initialize Terraform**:
   ```bash
   terraform init
   ```

2. **Review the Plan**:
   ```bash
   terraform plan
   ```

3. **Apply the Configuration**:
   ```bash
   terraform apply
   ```

4. **Clean Up** (when done testing):
   ```bash
   terraform destroy
   ```

### Customization

You can customize the example by modifying the variables:

```hcl
# Override default values
variable "name" {
  default = "my-custom-waf"
}

variable "scope" {
  default = "CLOUDFRONT"  # For CloudFront distributions
}

variable "alb_arn_list" {
  default = [
    "arn:aws:elasticloadbalancing:us-east-1:123456789012:loadbalancer/app/my-alb/1234567890123456"
  ]
}
```

## Key Features Demonstrated

### ✅ Priority Management
- Automatic priority validation prevents conflicts
- Clear priority ranges for different rule types:
  - Custom rule groups: 100-199
  - AWS managed rules: 200-299  
  - Inline rules: 300+

### ✅ Object-Based Inline Rules (NEW)
- Structured configuration using `statement_config`
- Support for all major WAF statement types:
  - `sqli_match_statement`
  - `xss_match_statement`
  - `rate_based_statement`
  - `geo_match_statement`
  - `size_constraint_statement`

### ✅ Flexible Field Matching
- Body inspection
- URI path analysis
- Query string examination
- Header inspection
- Method checking

### ✅ Text Transformations
- URL decode
- HTML entity decode
- Lowercase conversion
- None (no transformation)

## Outputs

The example provides ARNs for all created WAF ACLs:

- `custom_rule_group_arn`: ARN of the custom rule group
- `waf_acl_custom_rules_arn`: WAF ACL using custom rules
- `waf_acl_aws_managed_arn`: WAF ACL using AWS managed rules
- `waf_acl_object_inline_rules_arn`: WAF ACL using object-based inline rules
- `waf_acl_comprehensive_arn`: Comprehensive WAF ACL

## Testing

Run the included validation script:

```bash
bash test_validation.sh
```

This script validates:
- Terraform initialization
- Configuration syntax
- Code formatting
- Plan generation (without AWS deployment)

## Cost Considerations

This example creates multiple WAF ACLs and rule groups. Be aware of AWS WAF pricing:

- **Web ACL**: $1.00 per month per Web ACL
- **Rule Group**: $1.00 per month per rule group
- **WCU (Web ACL Capacity Units)**: $0.60 per million WCUs per month
- **Requests**: $0.60 per million requests

**Estimated monthly cost for this example**: ~$6-10 USD (depending on traffic)

## Security Best Practices

This example demonstrates several security best practices:

1. **Defense in Depth**: Multiple rule types working together
2. **Rate Limiting**: Prevents DDoS and brute force attacks
3. **Geo Blocking**: Reduces attack surface from high-risk countries
4. **Input Validation**: SQL injection and XSS protection
5. **Size Limits**: Prevents large payload attacks
6. **Monitoring**: CloudWatch metrics enabled for all rules

## Troubleshooting

### Common Issues

1. **Priority Conflicts**: Ensure all rule priorities are unique across all rule types
2. **Capacity Limits**: Rule groups have WCU capacity limits (default: 100)
3. **AWS Credentials**: Ensure proper AWS credentials are configured
4. **Region Scope**: REGIONAL WAFs can only be associated with ALBs in the same region

### Debug Commands

```bash
# Check configuration
terraform validate

# Format code
terraform fmt

# Show detailed plan
terraform plan -detailed-exitcode

# Show current state
terraform show
```