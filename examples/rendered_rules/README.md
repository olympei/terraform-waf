# Rendered Rules Example

This example demonstrates the different rule rendering approaches available in the WAF Rule Group module. It showcases three distinct methods for creating WAF rules: standard type-based rules, template-rendered rules, and advanced statement configuration rules.

## Rule Rendering Approaches

### 1. Standard Type-Based Rules
- **Module**: `standard_waf_group`
- **Approach**: Simple type specification (`type = "sqli"`, `type = "xss"`)
- **Resource**: `aws_wafv2_rule_group.this[0]`
- **Capacity**: 100 WCUs
- **Use Case**: Simple, straightforward rule creation

### 2. Template-Rendered Rules
- **Module**: `template_waf_group`
- **Approach**: Uses `use_templatefile_rendering = true`
- **Resource**: `aws_wafv2_rule_group.templated[0]`
- **Capacity**: 50 WCUs (default for templated)
- **Use Case**: Template-based rule generation for complex scenarios

### 3. Advanced Statement Configuration
- **Module**: `advanced_waf_group`
- **Approach**: Uses `statement_config` objects for fine-grained control
- **Resource**: `aws_wafv2_rule_group.this[0]`
- **Capacity**: 150 WCUs (higher for advanced rules)
- **Use Case**: Complex rules requiring detailed configuration

## Resources Created

### Standard WAF Rule Group
```
- aws_wafv2_rule_group.this[0]
- 2 rules: BlockSQLi (priority 1), BlockXSS (priority 2)
- Type-based rule generation
- 100 WCU capacity
```

### Template-Rendered WAF Rule Group
```
- aws_wafv2_rule_group.templated[0]
- 2 rules: Same as standard but template-rendered
- Template file processing
- 50 WCU capacity (default)
```

### Advanced WAF Rule Group
```
- aws_wafv2_rule_group.this[0]
- 2 rules: AdvancedSQLi (priority 1), RateLimit (priority 2)
- Statement configuration approach
- 150 WCU capacity
```

## Rule Configurations

### Standard Rules (Type-Based)
```hcl
custom_rules = [
  {
    name        = "BlockSQLi"
    priority    = 1
    action      = "block"
    metric_name = "block_sql_metric"
    type        = "sqli"
    field_to_match = "body"
  },
  {
    name        = "BlockXSS"
    priority    = 2
    action      = "block"
    metric_name = "block_xss_metric"
    type        = "xss"
    field_to_match = "uri_path"
  }
]
```

### Advanced Rules (Statement Config)
```hcl
custom_rules = [
  {
    name         = "AdvancedSQLi"
    priority     = 1
    action       = "block"
    metric_name  = "advanced_sqli"
    statement_config = {
      type                          = "sqli"
      field_to_match               = "body"
      text_transformation_priority = 0
      text_transformation_type     = "NONE"
    }
  },
  {
    name         = "RateLimit"
    priority     = 2
    action       = "block"
    metric_name  = "rate_limit"
    statement_config = {
      type               = "rate_based"
      rate_limit         = 2000
      aggregate_key_type = "IP"
    }
  }
]
```

## Variables

### Configuration Variables
| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `rule_group_name` | string | `"rendered-rules-group"` | Base name for rule groups |
| `use_templatefile_rendering` | bool | `false` | Enable template rendering |
| `custom_rules` | list(object) | See below | Rule definitions |

### Custom Rules Object Structure
```hcl
{
  name           = string           # Rule name
  priority       = number           # Rule priority (unique)
  action         = string           # "block", "allow", or "count"
  metric_name    = string           # CloudWatch metric name
  type           = optional(string) # "sqli", "xss", "ip_block", etc.
  field_to_match = optional(string, "body") # Target field
}
```

## Usage

### Default Configuration
```bash
terraform init
terraform validate
terraform plan
terraform apply
```

### Using tfvars.json
```bash
terraform plan -var-file="terraform.tfvars.json"
terraform apply -var-file="terraform.tfvars.json"
```

### Custom Variables
```bash
terraform plan -var="rule_group_name=my-custom-group"
terraform apply -var="rule_group_name=my-custom-group"
```

## Configuration Files

### terraform.tfvars.json
```json
{
  "rule_group_name": "custom-group"
}
```

This simple configuration changes the base name for all rule groups from the default `rendered-rules-group` to `custom-group`.

## Rule Types Supported

### Standard Type-Based Rules
- **sqli**: SQL injection detection
- **xss**: Cross-site scripting detection
- **ip_block**: IP address blocking (requires `ip_set_arn`)
- **regex**: Regex pattern matching (requires `regex_pattern_set`)
- **byte_match**: Byte string matching (requires `search_string`)

### Advanced Statement Config Rules
- **sqli**: SQL injection with custom text transformations
- **xss**: XSS with custom text transformations
- **rate_based**: Rate limiting by IP or other keys
- **geo_match**: Geographic blocking
- **size_constraint**: Request size limits

## Template Rendering

### How It Works
When `use_templatefile_rendering = true`:
1. Rules are processed through template files
2. Creates `aws_wafv2_rule_group.templated` resource
3. Uses template files in `modules/waf_rule_group/templates/`
4. Allows for more complex rule generation logic

### Template Files
- `rule_statement.tftpl`: Template for generating rule statements
- `rules.tpl`: Template for complete rule group generation

### Benefits
- **Flexibility**: Complex rule generation logic
- **Reusability**: Template-based rule patterns
- **Maintainability**: Centralized rule logic

## Performance Considerations

### Capacity Planning
- **Standard Rules**: 100 WCUs (suitable for basic protection)
- **Template Rules**: 50 WCUs (default, adjust as needed)
- **Advanced Rules**: 150 WCUs (higher for complex rules)

### Rule Priority Strategy
- **Lower Numbers**: Execute first (higher priority)
- **Performance**: Place faster rules before slower ones
- **Logic**: Most common attacks should have lower priorities

### WCU Usage Guidelines
- **Simple Rules**: 1-10 WCUs each
- **Complex Rules**: 10-50 WCUs each
- **Rate-Based Rules**: 2 WCUs each
- **Regex Rules**: Variable based on complexity

## Monitoring and Metrics

### CloudWatch Metrics
Each rule group creates individual metrics:

#### Standard Group Metrics
- `block_sql_metric`: SQL injection blocks
- `block_xss_metric`: XSS blocks
- `standard_group_metric`: Overall group metrics

#### Template Group Metrics
- Same as standard but for template-rendered rules
- `custom-group-template_templated`: Overall template group metrics

#### Advanced Group Metrics
- `advanced_sqli`: Advanced SQL injection blocks
- `rate_limit`: Rate limiting blocks
- `advanced_group_metric`: Overall advanced group metrics

### Log Analysis
WAF logs will show:
- **Rule Matches**: Which rule triggered
- **Action Taken**: Block, allow, or count
- **Request Details**: Full request context
- **Performance**: Rule execution time

## Comparison of Approaches

| Aspect | Standard | Template | Advanced |
|--------|----------|----------|----------|
| **Complexity** | Low | Medium | High |
| **Flexibility** | Limited | High | Very High |
| **Performance** | Fast | Medium | Variable |
| **Maintenance** | Easy | Medium | Complex |
| **Use Case** | Basic protection | Complex patterns | Fine-tuned control |
| **WCU Usage** | Predictable | Variable | Optimizable |

## Best Practices

### Rule Design
1. **Start Simple**: Begin with standard type-based rules
2. **Measure Performance**: Monitor WCU usage and response times
3. **Iterate**: Move to advanced configurations as needed
4. **Test Thoroughly**: Use staging environments for rule testing

### Capacity Management
1. **Monitor Usage**: Track WCU consumption
2. **Plan Ahead**: Reserve capacity for peak traffic
3. **Optimize Rules**: Remove or consolidate inefficient rules
4. **Scale Appropriately**: Adjust capacity based on actual usage

### Template Usage
1. **Complex Scenarios**: Use templates for complex rule generation
2. **Reusable Patterns**: Create templates for common rule patterns
3. **Version Control**: Track template changes carefully
4. **Testing**: Test template changes thoroughly

## Troubleshooting

### Common Issues

#### High WCU Usage
- **Cause**: Complex rules or high traffic
- **Solution**: Optimize rules or increase capacity

#### Rule Not Triggering
- **Cause**: Incorrect field targeting or rule logic
- **Solution**: Verify field_to_match and test rule logic

#### Template Errors
- **Cause**: Invalid template syntax or variables
- **Solution**: Check template files and variable passing

#### Performance Issues
- **Cause**: Inefficient rule ordering or complex patterns
- **Solution**: Optimize rule priorities and simplify patterns

### Debugging Steps
1. **Enable Logging**: Ensure WAF logging is configured
2. **Check Metrics**: Monitor CloudWatch metrics for rule effectiveness
3. **Test Rules**: Use count mode to test rule behavior
4. **Review Logs**: Analyze WAF logs for rule matches and performance
5. **Validate Configuration**: Ensure all variables and references are correct

## Migration Path

### From Basic to Advanced
1. **Start**: Use standard type-based rules
2. **Measure**: Monitor performance and effectiveness
3. **Identify**: Find rules that need more control
4. **Migrate**: Convert specific rules to statement_config
5. **Optimize**: Fine-tune advanced configurations

### Template Adoption
1. **Evaluate**: Determine if templates add value
2. **Develop**: Create template files for your use cases
3. **Test**: Thoroughly test template-generated rules
4. **Deploy**: Gradually migrate to template-based approach
5. **Maintain**: Keep templates updated and documented

This example provides a comprehensive foundation for understanding and implementing different WAF rule rendering approaches, from simple type-based rules to complex template-driven configurations.