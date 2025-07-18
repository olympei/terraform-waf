# GitLab Module Registry Usage Example

This example demonstrates how to use the WAF modules as if they were published to a GitLab Module Registry. It shows the integration of all four WAF modules working together to create a comprehensive web application firewall solution.

## Architecture Overview

This example creates a complete WAF setup with integrated modules:

1. **IP Set**: Defines malicious IP addresses for blocking
2. **Regex Pattern Set**: Contains SQL injection detection patterns
3. **WAF Rule Group**: Advanced security rules that **reference both IP Set and Regex Pattern Set**
4. **WAF Web ACL**: Main firewall that uses the integrated rule group

### Module Integration
The key feature of this example is that the **WAF Rule Group module uses both the IP Set and Regex Pattern Set modules** within its rules, demonstrating advanced module composition and dependency management.

## Modules Demonstrated

### 1. WAF Module (`modules/waf`)
- Creates the main WAF Web ACL
- Integrates with custom rule groups
- Configures default actions and logging
- **Real GitLab Registry Source**: `git::https://gitlab.com/your-namespace/terraform-waf-modules.git//modules/waf?ref=v1.0.0`

### 2. WAF Rule Group Module (`modules/waf-rule-group`)
- Creates custom rule groups with multiple rules
- Supports both simple type-based and advanced statement configurations
- **Real GitLab Registry Source**: `git::https://gitlab.com/your-namespace/terraform-waf-modules.git//modules/waf-rule-group?ref=v1.0.0`

### 3. Regex Pattern Set Module (`modules/regex-pattern-set`)
- Defines regex patterns for threat detection
- Used for advanced pattern matching in WAF rules
- **Real GitLab Registry Source**: `git::https://gitlab.com/your-namespace/terraform-waf-modules.git//modules/regex-pattern-set?ref=v1.0.0`

### 4. IP Set Module (`modules/ip-set`)
- Manages lists of IP addresses for blocking/allowing
- Supports both IPv4 and IPv6 addresses
- **Real GitLab Registry Source**: `git::https://gitlab.com/your-namespace/terraform-waf-modules.git//modules/ip-set?ref=v1.0.0`

## Resources Created

### IP Set
- **Name**: `gitlab-blocked-ips`
- **Type**: IPv4 addresses
- **Addresses**: 3 CIDR blocks for demonstration
- **Purpose**: Block known malicious IP ranges

### Regex Pattern Set
- **Name**: `gitlab-regex-patterns`
- **Patterns**: SQL injection detection patterns
  - `(?i)select.*from` - Detects SELECT statements
  - `(?i)union.*select` - Detects UNION-based injections
  - `(?i)drop.*table` - Detects DROP TABLE attempts

### WAF Rule Group (Integrated with IP Set and Regex Pattern Set)
- **Name**: `gitlab-registry-rule-group`
- **Capacity**: 200 WCUs (increased for advanced rules)
- **Rules**: 5 advanced integrated security rules
  - **BlockSQLiWithRegex** (Priority 10): Uses Regex Pattern Set for SQL injection detection
  - **BlockMaliciousIPs** (Priority 20): Uses IP Set to block known malicious addresses
  - **BlockRestrictedCountries** (Priority 30): Geographic blocking of restricted countries
  - **AllowLegitimateTraffic** (Priority 40): Complex allow rule combining User-Agent validation with IP Set exclusion
  - **AdvancedSQLiDetection** (Priority 50): Multi-field SQL injection detection using Regex Pattern Set

### WAF Web ACL
- **Name**: `gitlab-registry-waf`
- **Scope**: REGIONAL
- **Default Action**: Allow (with rules blocking specific threats)
- **Rule Groups**: References the custom rule group

## Configuration

### Variables
The example uses variables to configure security policies:

```hcl
variable "blocked_countries" {
  description = "List of country codes to block"
  type        = list(string)
  default     = ["CN", "RU", "KP"]
}

variable "allowed_user_agents" {
  description = "List of allowed user agent patterns"
  type        = list(string)
  default     = ["Mozilla", "Chrome", "Safari", "Edge", "Firefox"]
}
```

### Advanced Module Integration
The WAF Rule Group module integrates with IP Set and Regex Pattern Set modules using ARN references in statement configurations:

```hcl
# Example: SQL Injection detection using Regex Pattern Set
{
  name        = "BlockSQLiWithRegex"
  priority    = 10
  action      = "block"
  metric_name = "block_sqli_regex"
  statement_config = {
    regex_pattern_set_reference_statement = {
      arn = module.regex_pattern_set.arn
      field_to_match = {
        body = {}
      }
      text_transformation = {
        priority = 0
        type     = "URL_DECODE"
      }
    }
  }
}

# Example: IP blocking using IP Set
{
  name        = "BlockMaliciousIPs"
  priority    = 20
  action      = "block"
  metric_name = "block_malicious_ips"
  statement_config = {
    ip_set_reference_statement = {
      arn = module.ip_set.arn
    }
  }
}
```

### WAF Web ACL Integration
The WAF Web ACL references the integrated rule group:

```hcl
rule_group_arn_list = [
  {
    arn      = module.waf_rule_group.waf_rule_group_arn
    name     = "custom-rule-group"
    priority = 100
  }
]
```

## Usage

### Local Development (Current Setup)
```bash
terraform init
terraform validate
terraform plan
terraform apply
```

### GitLab Module Registry (Production Setup)
When published to GitLab Module Registry, update the source references:

```hcl
module "waf" {
  source = "git::https://gitlab.com/your-namespace/terraform-waf-modules.git//modules/waf?ref=v1.0.0"
  # ... configuration
}
```

## Outputs

The example provides four key outputs:

- `waf_arn`: ARN of the main WAF Web ACL
- `waf_rule_group_arn`: ARN of the custom rule group
- `regex_pattern_set_arn`: ARN of the regex pattern set
- `ip_set_arn`: ARN of the IP set

## GitLab Module Registry Benefits

### Version Control
- **Semantic Versioning**: Use Git tags for version management
- **Immutable Releases**: Specific versions ensure consistency
- **Rollback Capability**: Easy to revert to previous versions

### Access Control
- **Private Repositories**: Control who can access your modules
- **Authentication**: GitLab authentication for module access
- **Audit Trail**: Track module usage and changes

### CI/CD Integration
- **Automated Testing**: Test modules before publishing
- **Documentation**: Auto-generate documentation
- **Quality Gates**: Ensure modules meet standards

## Publishing to GitLab Module Registry

### 1. Repository Structure
```
terraform-waf-modules/
├── modules/
│   ├── waf/
│   ├── waf-rule-group/
│   ├── ip-set/
│   └── regex-pattern-set/
├── examples/
└── README.md
```

### 2. Version Tagging
```bash
git tag v1.0.0
git push origin v1.0.0
```

### 3. Module Usage
```hcl
module "waf" {
  source = "git::https://gitlab.com/your-namespace/terraform-waf-modules.git//modules/waf?ref=v1.0.0"
}
```

## Security Considerations

- **Private Repositories**: Keep WAF configurations private
- **Access Tokens**: Use GitLab deploy tokens for CI/CD
- **Version Pinning**: Always specify module versions
- **Security Scanning**: Scan modules for vulnerabilities

## Cost Optimization

- **Rule Capacity**: Monitor WCU usage for cost optimization
- **CloudWatch Metrics**: Use metrics to optimize rule performance
- **Regional Deployment**: Deploy only in required regions
- **Rule Efficiency**: Optimize rule order for better performance

This example demonstrates enterprise-ready WAF module usage patterns suitable for GitLab-based infrastructure management.