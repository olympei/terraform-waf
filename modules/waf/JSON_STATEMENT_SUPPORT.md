# Enhanced WAF Module - JSON Statement Support

## 🎯 **Overview**

The WAF module has been enhanced to support complex JSON-encoded statements in the legacy `statement` field. This enables advanced logical operations using `and_statement`, `not_statement`, and `or_statement` combinations while maintaining backward compatibility.

## 🚀 **New Capabilities**

### **JSON-Encoded Complex Statements**
The module now supports parsing and processing JSON-encoded complex statements using `jsondecode()` function:

```hcl
custom_inline_rules = [
  {
    name        = "ComplexRule"
    priority    = 10
    action      = "block"
    metric_name = "complex_rule"
    statement = jsonencode({
      and_statement = {
        statements = [
          {
            xss_match_statement = {
              field_to_match = { body = {} }
              text_transformations = [
                { priority = 1, type = "URL_DECODE" },
                { priority = 2, type = "HTML_ENTITY_DECODE" }
              ]
            }
          },
          {
            not_statement = {
              statement = {
                or_statement = {
                  statements = [
                    {
                      byte_match_statement = {
                        field_to_match = { uri_path = {} }
                        positional_constraint = "STARTS_WITH"
                        search_string = "/exception1/"
                        text_transformations = [
                          { priority = 1, type = "LOWERCASE" }
                        ]
                      }
                    },
                    {
                      byte_match_statement = {
                        field_to_match = { uri_path = {} }
                        positional_constraint = "STARTS_WITH"
                        search_string = "/exception2/"
                        text_transformations = [
                          { priority = 1, type = "LOWERCASE" }
                        ]
                      }
                    }
                  ]
                }
              }
            }
          }
        ]
      }
    })
  }
]
```

## 🛡️ **Supported Statement Types**

### **1. AND Statement**
Combines multiple conditions with logical AND:
```json
{
  "and_statement": {
    "statements": [
      { "xss_match_statement": {...} },
      { "not_statement": {...} }
    ]
  }
}
```

### **2. NOT Statement**
Negates a condition (used for exceptions):
```json
{
  "not_statement": {
    "statement": {
      "or_statement": {...}
    }
  }
}
```

### **3. OR Statement**
Combines multiple conditions with logical OR:
```json
{
  "or_statement": {
    "statements": [
      { "byte_match_statement": {...} },
      { "byte_match_statement": {...} }
    ]
  }
}
```

### **4. Nested Statement Types**
- **XSS Match Statement**: Detects cross-site scripting patterns
- **Size Constraint Statement**: Enforces size limits
- **Byte Match Statement**: Matches specific byte patterns
- **Multiple Text Transformations**: URL_DECODE, HTML_ENTITY_DECODE, LOWERCASE, etc.

## 🔧 **Implementation Details**

### **Module Enhancement**
The WAF module's `main.tf` has been enhanced with:

1. **JSON Parsing Logic**:
   ```hcl
   dynamic "and_statement" {
     for_each = try(
       rule.value.statement != null && 
       jsondecode(rule.value.statement).and_statement != null ? 
       [jsondecode(rule.value.statement).and_statement] : [], 
       []
     )
     content { ... }
   }
   ```

2. **Complex Nested Structures**:
   - Support for deeply nested logical statements
   - Dynamic field matching for all AWS WAF field types
   - Multiple text transformation support
   - Error handling with `try()` function

3. **Backward Compatibility**:
   - Existing `statement_config` approach still works
   - Legacy string statements still supported
   - No breaking changes to existing configurations

## 📋 **Usage Examples**

### **Example 1: XSS Protection with URI Exceptions**
```hcl
{
  name = "XSS_With_Exceptions"
  statement = jsonencode({
    and_statement = {
      statements = [
        {
          xss_match_statement = {
            field_to_match = { body = {} }
            text_transformations = [
              { priority = 1, type = "URL_DECODE" },
              { priority = 2, type = "HTML_ENTITY_DECODE" }
            ]
          }
        },
        {
          not_statement = {
            statement = {
              or_statement = {
                statements = [
                  {
                    byte_match_statement = {
                      field_to_match = { uri_path = {} }
                      positional_constraint = "STARTS_WITH"
                      search_string = "/api/safe/"
                      text_transformations = [{ priority = 1, type = "LOWERCASE" }]
                    }
                  }
                ]
              }
            }
          }
        }
      ]
    }
  })
}
```

### **Example 2: Size Restriction with Multiple Exceptions**
```hcl
{
  name = "Size_Restriction_With_Exceptions"
  statement = jsonencode({
    and_statement = {
      statements = [
        {
          size_constraint_statement = {
            field_to_match = { body = {} }
            comparison_operator = "GT"
            size = 8192
            text_transformations = [{ priority = 1, type = "NONE" }]
          }
        },
        {
          not_statement = {
            statement = {
              or_statement = {
                statements = [
                  {
                    byte_match_statement = {
                      field_to_match = { uri_path = {} }
                      positional_constraint = "STARTS_WITH"
                      search_string = "/upload/large/"
                      text_transformations = [{ priority = 1, type = "LOWERCASE" }]
                    }
                  },
                  {
                    byte_match_statement = {
                      field_to_match = { uri_path = {} }
                      positional_constraint = "STARTS_WITH"
                      search_string = "/api/bulk/"
                      text_transformations = [{ priority = 1, type = "LOWERCASE" }]
                    }
                  }
                ]
              }
            }
          }
        }
      ]
    }
  })
}
```

## 🎯 **Benefits**

### **Performance**
- **Single Rule Evaluation**: Complex logic in one rule instead of multiple rules
- **Efficient Processing**: Native AWS WAF v2 logical statement evaluation
- **Reduced Rule Count**: Fewer rules = faster processing

### **Maintainability**
- **Self-Contained Logic**: Each rule contains its own exception logic
- **Clear Structure**: JSON structure clearly shows logical relationships
- **Easy Debugging**: JSON format is human-readable and debuggable

### **Flexibility**
- **Complex Conditions**: Support for deeply nested logical operations
- **Multiple Exceptions**: Easy to add/remove exception conditions
- **Advanced Transformations**: Multiple text transformations per statement

## 🔍 **Validation**

### **Testing the Enhanced Module**
```bash
# Run the comprehensive test
bash test_json_statements.sh

# Validate Terraform syntax
terraform validate

# Check the plan
terraform plan
```

### **Expected Results**
- ✅ Terraform validation passes
- ✅ JSON statements are properly parsed
- ✅ Complex logical structures are supported
- ✅ Exception logic works as expected
- ✅ Backward compatibility maintained

## 🚀 **Migration Guide**

### **From Priority-Based to Embedded Exceptions**

**Before (Priority-Based)**:
```hcl
custom_inline_rules = [
  {
    name = "AllowException"
    priority = 50
    action = "allow"
    statement_config = {
      byte_match_statement = {
        search_string = "/exception/"
        field_to_match = { uri_path = {} }
        positional_constraint = "CONTAINS"
        text_transformation = { priority = 0, type = "NONE" }
      }
    }
  },
  {
    name = "BlockXSS"
    priority = 100
    action = "block"
    statement_config = {
      xss_match_statement = {
        field_to_match = { body = {} }
        text_transformation = { priority = 1, type = "HTML_ENTITY_DECODE" }
      }
    }
  }
]
```

**After (JSON-Encoded Embedded)**:
```hcl
custom_inline_rules = [
  {
    name = "XSS_With_Embedded_Exception"
    priority = 50
    action = "block"
    statement = jsonencode({
      and_statement = {
        statements = [
          {
            xss_match_statement = {
              field_to_match = { body = {} }
              text_transformations = [
                { priority = 1, type = "HTML_ENTITY_DECODE" }
              ]
            }
          },
          {
            not_statement = {
              statement = {
                byte_match_statement = {
                  field_to_match = { uri_path = {} }
                  positional_constraint = "CONTAINS"
                  search_string = "/exception/"
                  text_transformations = [
                    { priority = 1, type = "NONE" }
                  ]
                }
              }
            }
          }
        ]
      }
    })
  }
]
```

## 🎉 **Conclusion**

The enhanced WAF module now provides full support for complex JSON-encoded statements, enabling advanced logical operations while maintaining backward compatibility. This enhancement allows for more efficient, maintainable, and powerful WAF rule configurations that follow AWS WAF v2 best practices.