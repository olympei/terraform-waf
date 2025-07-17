# Invalid Priority Example

This example demonstrates the WAF module's priority validation feature. It intentionally creates WAF configurations with duplicate priorities to show how the validation system catches and prevents these conflicts.

## Purpose

WAF rules must have unique priorities within a Web ACL. This example shows:

1. **Priority Conflict Detection**: How the module detects duplicate priorities
2. **Validation Errors**: Clear error messages when conflicts occur
3. **Multiple Rule Types**: Validation across rule groups and AWS managed rules
4. **Prevention**: Stops deployment before creating invalid configurations

## Test Scenarios

### Scenario 1: Rule Group Priority Conflicts
```hcl
rule_group_arn_list = [
  {
    arn      = "arn:aws:wafv2:us-east-1:123456789012:regional/rulegroup/sample-group-1/abc123"
    name     = "sample-group-1"
    priority = 100  # First rule group with priority 100
  },
  {
    arn      = "arn:aws:wafv2:us-east-1:123456789012:regional/rulegroup/sample-group-2/def456"
    name     = "sample-group-2"
    priority = 100  # Duplicate priority - should cause validation error
  }
]
```

**Expected Error:**
```
Duplicate priorities detected across WAF rules. All priorities must be unique. Found priorities: 100, 100
```

### Scenario 2: AWS Managed Rules Priority Conflicts
```hcl
aws_managed_rule_groups = [
  {
    name            = "AWSManagedRulesCommonRuleSet"
    vendor_name     = "AWS"
    priority        = 200
    override_action = "none"
  },
  {
    name            = "AWSManagedRulesSQLiRuleSet"
    vendor_name     = "AWS"
    priority        = 200  # Duplicate priority - should cause validation error
    override_action = "none"
  }
]
```

**Expected Error:**
```
Duplicate priorities detected across WAF rules. All priorities must be unique. Found priorities: 200, 200
```

## How Priority Validation Works

### 1. Priority Collection
The module collects priorities from all rule sources:
```hcl
locals {
  inline_priorities      = [for r in var.custom_inline_rules : r.priority]
  rulegroup_priorities   = [for i, r in var.rule_group_arn_list : coalesce(r.priority, 100 + i)]
  aws_managed_priorities = [for r in var.aws_managed_rule_groups : r.priority]
  all_waf_priorities     = concat(local.inline_priorities, local.rulegroup_priorities, local.aws_managed_priorities)
}
```

### 2. Duplicate Detection
```hcl
locals {
  unique_priorities      = distinct(local.all_waf_priorities)
  has_duplicate_priorities = length(local.all_waf_priorities) != length(local.unique_priorities)
}
```

### 3. Validation Check
```hcl
resource "null_resource" "priority_validation" {
  count = var.validate_priorities ? 1 : 0
  
  lifecycle {
    precondition {
      condition     = !local.has_duplicate_priorities
      error_message = "Duplicate priorities detected across WAF rules. All priorities must be unique. Found priorities: ${join(", ", local.all_waf_priorities)}"
    }
  }
}
```

## Testing the Example

### 1. Initialize Terraform
```bash
terraform init
```

### 2. Validate Configuration (Syntax Check)
```bash
terraform validate
# Should pass - syntax is correct
```

### 3. Plan Deployment (Priority Validation)
```bash
terraform plan
# Should fail with priority validation errors
```

### Expected Output
```
Error: Resource precondition failed

Duplicate priorities detected across WAF rules. All priorities must be unique. Found priorities: 100, 100

Error: Resource precondition failed

Duplicate priorities detected across WAF rules. All priorities must be unique. Found priorities: 200, 200
```

## Fixing Priority Conflicts

To resolve priority conflicts, ensure each rule has a unique priority:

### ✅ Correct Configuration
```hcl
rule_group_arn_list = [
  {
    arn      = "arn:aws:wafv2:us-east-1:123456789012:regional/rulegroup/sample-group-1/abc123"
    name     = "sample-group-1"
    priority = 100  # Unique priority
  },
  {
    arn      = "arn:aws:wafv2:us-east-1:123456789012:regional/rulegroup/sample-group-2/def456"
    name     = "sample-group-2"
    priority = 101  # Different priority
  }
]

aws_managed_rule_groups = [
  {
    name            = "AWSManagedRulesCommonRuleSet"
    vendor_name     = "AWS"
    priority        = 200  # Unique priority
    override_action = "none"
  },
  {
    name            = "AWSManagedRulesSQLiRuleSet"
    vendor_name     = "AWS"
    priority        = 201  # Different priority
    override_action = "none"
  }
]
```

## Priority Best Practices

### 1. Priority Ranges
- **Custom Inline Rules**: 1-99
- **Rule Groups**: 100-199
- **AWS Managed Rules**: 200-299
- **Rate Limiting**: 300-399

### 2. Priority Spacing
Leave gaps between priorities for future rules:
```hcl
priority = 100  # First rule
priority = 110  # Second rule (gap of 10)
priority = 120  # Third rule
```

### 3. Documentation
Document your priority scheme:
```hcl
# Priority Scheme:
# 1-99:    Custom inline rules
# 100-199: Custom rule groups
# 200-299: AWS managed rules
# 300-399: Rate limiting rules
```

## Validation Control

### Enable/Disable Validation
```hcl
module "waf" {
  source = "../../modules/waf"
  
  validate_priorities = true  # Enable validation (default)
  # validate_priorities = false # Disable validation (not recommended)
  
  # ... other configuration
}
```

### When to Disable Validation
- **Testing**: Temporary disable for testing scenarios
- **Migration**: During complex migrations with temporary conflicts
- **Advanced Use Cases**: When you need specific priority arrangements

**⚠️ Warning**: Disabling validation can lead to deployment failures at the AWS level.

## Error Resolution

### Common Priority Conflicts
1. **Duplicate Explicit Priorities**: Two rules with same priority number
2. **Default Priority Conflicts**: Auto-assigned priorities conflicting with explicit ones
3. **Cross-Type Conflicts**: Rule groups conflicting with AWS managed rules

### Debugging Steps
1. **List All Priorities**: Check the error message for all priority values
2. **Identify Sources**: Determine which rules have conflicting priorities
3. **Reassign Priorities**: Update priorities to be unique
4. **Test Again**: Run `terraform plan` to verify fixes

This example serves as both a demonstration of the validation system and a testing tool for ensuring your WAF configurations have proper priority management.