# Example: terraform.tfvars.json - Inline rules
```json
{
  "custom_inline_rules": [
    {
      "name": "BlockSQLInjection",
      "priority": 1,
      "action": "block",
      "rule_type": "SQLI",
      "metric_name": "block_sqli",
      "statement": "sqli_match_statement { field_to_match { body {} } text_transformations { priority = 0 type = \"NONE\" } }"
    },
    {
      "name": "BlockXSS",
      "priority": 2,
      "action": "block",
      "rule_type": "XSS",
      "metric_name": "block_xss",
      "statement": "xss_match_statement { field_to_match { body {} } text_transformations { priority = 0 type = \"NONE\" } }"
    }
  ]
}
```