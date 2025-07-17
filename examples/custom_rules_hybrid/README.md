# WAF Rule Group - Hybrid Custom Rules Example

This example demonstrates the updated WAF rule group module that supports both simple type-based rules and advanced statement configuration rules.

## Features Demonstrated

### 1. Simple Type-Based Rules (Original Approach)
Easy to use for common WAF rule types:
```hcl
{
  name           = "BlockSQLi"
  priority       = 0
  metric_name    = "SQLiRule"
  type           = "sqli"           # Simple type specification
  field_to_match = "body"
  action         = "block"
}
```

### 2. Advanced Statement Configuration Rules (New Approach)
For complex rules and advanced WAF features:
```hcl
{
  name         = "BlockSQLInjection"
  priority     = 1
  metric_name  = "block_sqli"
  action       = "block"
  statement_config = {              # Advanced configuration object
    type                          = "sqli"
    field_to_match               = "body"
    text_transformation_priority = 0
    text_transformation_type     = "NONE"
  }
}
```

## Supported Rule Types

### Simple Type-Based Rules
- `sqli` - SQL Injection protection
- `xss` - Cross-site scripting protection
- `ip_block` - IP address blocking (requires `ip_set_arn`)
- `regex` - Regex pattern matching (requires `regex_pattern_set`)
- `byte_match` - Byte string matching (requires `search_string`)

### Advanced Statement Config Rules
- `sqli` - SQL Injection with custom text transformations
- `xss` - XSS with custom text transformations
- `rate_based` - Rate limiting by IP
- `geo_match` - Geographic blocking
- `size_constraint` - Request size limits

## Migration from String Statements

If you previously used string statements like:
```hcl
# OLD - NOT SUPPORTED
{
  name      = "BlockSQLInjection"
  priority  = 1
  statement = "sqli_match_statement { field_to_match { body {} } text_transformations { priority = 0 type = \"NONE\" } }"
  action    = "block"
  metric_name = "block_sqli"
}
```

Convert to the new `statement_config` approach:
```hcl
# NEW - SUPPORTED
{
  name         = "BlockSQLInjection"
  priority     = 1
  metric_name  = "block_sqli"
  action       = "block"
  statement_config = {
    type                          = "sqli"
    field_to_match               = "body"
    text_transformation_priority = 0
    text_transformation_type     = "NONE"
  }
}
```

## Usage

```bash
terraform init
terraform plan
terraform apply
```

## Resources Created

- 1 WAF Rule Group with 5 different rule types
- CloudWatch metrics for monitoring
- Proper priority management
- Support for both simple and advanced rule configurations