# Example: terraform.tfvars.json - Inline rules (invalid - duplicate priorities)
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
      "name": "BlockAnotherSQLI",
      "priority": 1,
      "action": "block",
      "rule_type": "SQLI",
      "metric_name": "block_sqli_2",
      "statement": "sqli_match_statement { field_to_match { uri_path {} } text_transformations { priority = 0 type = \"NONE\" } }"
    }
  ]
}
```