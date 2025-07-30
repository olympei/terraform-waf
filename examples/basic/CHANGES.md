# Basic WAF Example - Recent Changes

## Added Custom Inline Rules

### 1. CrossSiteScripting_BODY Rule
- **Name**: `CrossSiteScripting_BODY`
- **Priority**: 300
- **Action**: Block
- **Purpose**: Protects against Cross-Site Scripting (XSS) attacks in request body
- **Configuration**:
  ```hcl
  {
    name        = "CrossSiteScripting_BODY"
    priority    = 300
    action      = "block"
    metric_name = "CrossSiteScripting_BODY"
    statement_config = {
      xss_match_statement = {
        field_to_match = {
          body = {}
        }
        text_transformation = {
          priority = 1
          type     = "HTML_ENTITY_DECODE"
        }
      }
    }
  }
  ```

### 2. SizeRestrictions_BODY Rule
- **Name**: `SizeRestrictions_BODY`
- **Priority**: 301
- **Action**: Block
- **Purpose**: Prevents large payload attacks by limiting request body size to 8KB
- **Configuration**:
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
          body = {}
        }
        text_transformation = {
          priority = 0
          type     = "NONE"
        }
      }
    }
  }
  ```

## Enhanced Outputs

### New Output: custom_rules_details
Provides detailed information about the custom inline rules:
```hcl
output "custom_rules_details" {
  description = "Details of the custom inline rules"
  value = {
    xss_protection = {
      name        = "CrossSiteScripting_BODY"
      priority    = 300
      action      = "block"
      description = "Blocks Cross-Site Scripting (XSS) attempts in request body"
      field       = "body"
      transformation = "HTML_ENTITY_DECODE"
    }
    size_restriction = {
      name        = "SizeRestrictions_BODY"
      priority    = 301
      action      = "block"
      description = "Blocks requests with body size greater than 8KB (8192 bytes)"
      field       = "body"
      size_limit  = "8192 bytes (8KB)"
    }
  }
}
```

### Updated Output: basic_waf_summary
Updated to include information about the new custom inline rules.

## New Documentation

### README.md
- Comprehensive documentation for the basic WAF example
- Detailed explanation of each custom rule
- Deployment instructions
- Monitoring and testing guidance
- Troubleshooting section

### terraform.tfvars.example
- Example configuration file
- Different environment examples
- Commented explanations

### test-rules.sh
- Automated test script for validating rule configuration
- Checks Terraform configuration validity
- Verifies rule priorities and settings
- Documentation verification

## Rule Priority Structure

The basic WAF now follows this priority structure:
- **100**: AWSManagedRulesCommonRuleSet
- **200**: AWSManagedRulesSQLiRuleSet
- **300**: CrossSiteScripting_BODY (Custom)
- **301**: SizeRestrictions_BODY (Custom)

## Security Enhancements

### What's Now Protected
- ✅ SQL injection attacks (existing AWS managed rule)
- ✅ Common web exploits (existing AWS managed rule)
- ✅ **NEW**: Cross-site scripting (XSS) in request body
- ✅ **NEW**: Large payload DoS attacks (8KB body limit)

### CloudWatch Metrics
New metrics available for monitoring:
- `CrossSiteScripting_BODY`: Count of XSS attempts blocked
- `SizeRestrictions_BODY`: Count of large payload requests blocked

## Testing

### XSS Protection Test
```bash
# This request should be blocked
curl -X POST https://your-domain.com/api/test \
  -H "Content-Type: application/json" \
  -d '{"comment": "<script>alert(\"XSS\")</script>"}'
```

### Size Restriction Test
```bash
# This request should be blocked (>8KB payload)
curl -X POST https://your-domain.com/api/test \
  -H "Content-Type: application/json" \
  -d "$(python3 -c 'print("{\"data\": \"" + "A" * 10000 + "\"}")')"
```

## Migration Notes

### From Previous Version
If you're upgrading from a previous version of the basic WAF example:

1. **No breaking changes**: The new rules are additive
2. **New outputs**: Additional outputs are available but optional
3. **Same variables**: All existing variables remain unchanged
4. **Enhanced protection**: Your WAF will now have additional security layers

### Terraform State
- No state migration required
- New rules will be added to existing WAF ACL
- Existing rules remain unchanged

## Cost Impact

### Additional Costs
- **Rule Evaluations**: ~$0.60 per million requests for the 2 new rules
- **CloudWatch Metrics**: Minimal cost for additional metrics
- **Total Impact**: <$1/month for typical small application traffic

### No Additional Fixed Costs
- No additional WAF ACL charges
- No additional rule group charges
- Uses existing WAF capacity

## Next Steps

### For Development
1. Test the new rules with your application
2. Monitor CloudWatch metrics for rule effectiveness
3. Adjust size limits if needed for your use case

### For Production
Consider upgrading to enterprise examples for:
- Geographic blocking
- Advanced rate limiting
- Comprehensive logging
- Compliance features

## Support

### Issues
If you encounter issues with the new rules:
1. Check CloudWatch metrics to identify which rule is triggering
2. Review the test scripts for validation
3. Consult the troubleshooting section in README.md

### Feedback
Please provide feedback on:
- Rule effectiveness
- False positive rates
- Documentation clarity
- Additional rule suggestions