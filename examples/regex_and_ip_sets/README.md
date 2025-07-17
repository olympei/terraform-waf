# Regex and IP Sets Example

This example demonstrates how to use the IP Set and Regex Pattern Set modules together with the WAF Rule Group module to create comprehensive security rules that block both malicious IP addresses and dangerous content patterns.

## Architecture Overview

This example creates a complete security setup with:

1. **IP Set**: Blocks known malicious IP addresses
2. **Regex Pattern Set**: Defines patterns for malicious content detection
3. **WAF Rule Group**: Contains rules that reference both IP sets and regex patterns

## Example Configurations

### Root Configuration (`main.tf`)
- **IP Set**: `blocked-ips` with 2 CIDR blocks
- **Regex Patterns**: `bad-input-regex` with SQL injection patterns
- **Rule Group**: `dev-rules` with 2 security rules

### Dev Configuration (`dev/main.tf`)
- **IP Set**: `dev-ipset` with 1 CIDR block
- **Regex Patterns**: `dev-regex` with malware detection patterns
- **Rule Group**: `dev-waf-group` with 2 security rules

## Resources Created

### IP Set Module
- **Resource**: `aws_wafv2_ip_set`
- **Purpose**: Block requests from malicious IP addresses
- **Configuration**: IPv4 addresses with CIDR notation
- **Integration**: Referenced by WAF rules via ARN

### Regex Pattern Set Module
- **Resource**: `aws_wafv2_regex_pattern_set`
- **Purpose**: Detect malicious content patterns in requests
- **Configuration**: Case-insensitive regex patterns
- **Integration**: Referenced by WAF rules via ARN

### WAF Rule Group Module
- **Resource**: `aws_wafv2_rule_group`
- **Purpose**: Contains security rules using IP sets and regex patterns
- **Rules**: 2 rules with different priorities and actions
- **Integration**: Uses ARNs from IP set and regex pattern set modules

## Security Rules Demonstrated

### Root Configuration Rules

#### Rule 1: Regex Pattern Blocking (Priority 1)
```hcl
{
  name              = "RegexBlock"
  priority          = 1
  metric_name       = "regex_block"
  type              = "regex"
  field_to_match    = "body"
  regex_pattern_set = module.regex.arn
  action            = "block"
}
```
- **Target**: Request body content
- **Patterns**: SQL injection attempts (`(?i)malicious`, `(?i)drop table`)
- **Action**: Block matching requests

#### Rule 2: IP Address Blocking (Priority 2)
```hcl
{
  name         = "BlockIPs"
  priority     = 2
  metric_name  = "ip_block"
  type         = "ip_block"
  ip_set_arn   = module.ipset.arn
  action       = "block"
}
```
- **Target**: Source IP addresses
- **Addresses**: Known malicious IP ranges
- **Action**: Block requests from listed IPs

### Dev Configuration Rules

#### Rule 1: Regex Pattern Blocking (Priority 0)
```hcl
{
  name              = "RegexBlock"
  priority          = 0
  metric_name       = "regexBlock"
  type              = "regex"
  regex_pattern_set = module.regex.arn
  field_to_match    = "body"
  action            = "block"
}
```
- **Target**: Request body content
- **Patterns**: Malware detection (`(?i)drop`, `(?i)malware`)
- **Action**: Block matching requests

#### Rule 2: IP Address Blocking (Priority 1)
```hcl
{
  name         = "IPBlock"
  priority     = 1
  metric_name  = "ipBlock"
  type         = "ip_block"
  ip_set_arn   = module.ipset.arn
  action       = "block"
}
```
- **Target**: Source IP addresses
- **Addresses**: Test network range (`203.0.113.0/24`)
- **Action**: Block requests from listed IPs

## Module Integration

### ARN References
The example demonstrates proper module integration through ARN references:

```hcl
# IP Set ARN reference
ip_set_arn = module.ipset.arn

# Regex Pattern Set ARN reference
regex_pattern_set = module.regex.arn
```

### Dependency Management
Terraform automatically manages dependencies:
1. **IP Set** and **Regex Pattern Set** created first
2. **WAF Rule Group** created after, referencing the ARNs
3. Proper dependency chain ensures correct creation order

## Usage

### Root Configuration
```bash
cd waf-module-v1/examples/regex_and_ip_sets
terraform init
terraform validate
terraform plan
terraform apply
```

### Dev Configuration
```bash
cd waf-module-v1/examples/regex_and_ip_sets/dev
terraform init
terraform validate
terraform plan
terraform apply
```

## Configuration Differences

| Aspect | Root Configuration | Dev Configuration |
|--------|-------------------|-------------------|
| **IP Set Name** | `blocked-ips` | `dev-ipset` |
| **IP Addresses** | 2 CIDR blocks | 1 CIDR block |
| **Regex Set Name** | `bad-input-regex` | `dev-regex` |
| **Regex Patterns** | SQL injection | Malware detection |
| **Rule Group Name** | `dev-rules` | `dev-waf-group` |
| **Rule Priorities** | 1, 2 | 0, 1 |

## Security Patterns

### IP-Based Blocking
- **Use Case**: Block known malicious IP addresses or ranges
- **Advantages**: Fast, network-level blocking
- **Limitations**: IPs can change, may block legitimate users behind NAT

### Content-Based Blocking
- **Use Case**: Detect malicious content in requests
- **Advantages**: Catches attacks regardless of source IP
- **Limitations**: Higher processing overhead, potential false positives

### Combined Approach
- **Benefits**: Multi-layered security with both network and content inspection
- **Strategy**: IP blocking for known threats, regex for unknown attack patterns
- **Effectiveness**: Comprehensive protection against various attack vectors

## Regex Pattern Examples

### SQL Injection Detection
```regex
(?i)drop table     # Case-insensitive "drop table"
(?i)union select   # Case-insensitive "union select"
(?i)or 1=1         # Case-insensitive "or 1=1"
```

### Malware Detection
```regex
(?i)malware        # Case-insensitive "malware"
(?i)virus          # Case-insensitive "virus"
(?i)trojan         # Case-insensitive "trojan"
```

### XSS Detection
```regex
<script.*?>        # Script tags
javascript:        # JavaScript protocol
on\w+\s*=         # Event handlers
```

## IP Set Examples

### Known Malicious Ranges
```hcl
addresses = [
  "192.0.2.0/24",      # RFC 5737 test network
  "198.51.100.0/24",   # RFC 5737 test network
  "203.0.113.0/24"     # RFC 5737 test network
]
```

### Geographic Blocking
```hcl
addresses = [
  "1.2.3.0/24",        # Specific country ranges
  "4.5.6.0/24",        # (Example - use actual ranges)
  "7.8.9.0/24"
]
```

### Tor Exit Nodes
```hcl
addresses = [
  "10.0.0.1/32",       # Individual Tor exit nodes
  "10.0.0.2/32",       # (Example - use actual IPs)
  "10.0.0.3/32"
]
```

## Performance Considerations

### Rule Priority Order
- **Lower Priority Numbers**: Execute first
- **Strategy**: Place faster rules (IP blocking) before slower rules (regex)
- **Optimization**: Most common attacks should have lower priority numbers

### Regex Optimization
- **Simple Patterns**: Use simple regex patterns when possible
- **Anchoring**: Use `^` and `$` anchors to limit matching scope
- **Case Sensitivity**: Use `(?i)` flag for case-insensitive matching

### IP Set Optimization
- **CIDR Blocks**: Use CIDR notation for IP ranges instead of individual IPs
- **Consolidation**: Combine adjacent IP ranges into larger CIDR blocks
- **Regular Updates**: Keep IP sets updated with latest threat intelligence

## Monitoring and Metrics

### CloudWatch Metrics
Each rule creates individual metrics:
- `regex_block` / `regexBlock`: Regex pattern matches
- `ip_block` / `ipBlock`: IP address matches
- `devWAFGroup` / `devMetrics`: Overall rule group metrics

### Log Analysis
WAF logs will show:
- **Rule Matches**: Which rule triggered the action
- **Pattern Details**: What pattern or IP was matched
- **Request Context**: Full request details for analysis

### Alerting
Set up CloudWatch alarms for:
- **High Block Rates**: Unusual number of blocked requests
- **Pattern Matches**: Specific attack pattern detections
- **IP Blocks**: Requests from known malicious IPs

## Best Practices

### Pattern Management
1. **Regular Updates**: Keep regex patterns updated with latest attack signatures
2. **Testing**: Test patterns in count mode before switching to block
3. **False Positives**: Monitor for legitimate requests being blocked
4. **Performance**: Balance security coverage with processing performance

### IP Set Management
1. **Threat Intelligence**: Use reputable threat intelligence sources
2. **Automation**: Automate IP set updates with threat feeds
3. **Whitelisting**: Maintain separate IP sets for trusted sources
4. **Geographic**: Consider geographic blocking for region-specific threats

### Rule Group Management
1. **Priority Planning**: Plan rule priorities based on performance and effectiveness
2. **Capacity Planning**: Monitor WCU usage and adjust capacity as needed
3. **Testing**: Use staging environments to test rule changes
4. **Documentation**: Document the purpose and source of each rule

## Troubleshooting

### Common Issues

#### High False Positive Rate
- **Cause**: Overly broad regex patterns
- **Solution**: Refine patterns to be more specific

#### Performance Issues
- **Cause**: Complex regex patterns or large IP sets
- **Solution**: Optimize patterns and consolidate IP ranges

#### Rule Not Triggering
- **Cause**: Incorrect field targeting or pattern syntax
- **Solution**: Verify field_to_match and test patterns independently

### Debugging Steps
1. **Enable Logging**: Ensure WAF logging is enabled
2. **Test Patterns**: Test regex patterns with sample data
3. **Check Priorities**: Verify rule execution order
4. **Monitor Metrics**: Use CloudWatch metrics to track rule effectiveness

This example provides a solid foundation for implementing multi-layered WAF security using both IP-based and content-based protection mechanisms.