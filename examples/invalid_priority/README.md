# Invalid Priority Example - Priority Validation Testing

This example demonstrates comprehensive priority validation testing for AWS WAF configurations. It includes multiple test cases designed to trigger validation errors when rule priorities conflict, helping developers understand and test the priority validation logic in the WAF module.

## 🎯 Purpose

This example serves as a comprehensive test suite for priority validation functionality, demonstrating:

- **Priority Conflict Detection**: Various scenarios where rule priorities conflict
- **Validation Logic Testing**: Ensuring the WAF module correctly identifies priority conflicts
- **Error Handling**: Understanding how Terraform handles priority validation errors
- **Best Practices**: Learning proper priority assignment patterns

## 🏗️ Architecture Overview

The example creates 7 different WAF configurations, each testing specific priority conflict scenarios:

```
┌─────────────────────────────────────────────────────────────────┐
│                    PRIORITY VALIDATION TEST SUITE               │
├─────────────────────────────────────────────────────────────────┤
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐ │
│  │   Test Case 1   │  │   Test Case 2   │  │   Test Case 3   │ │
│  │ Duplicate Rule  │  │ Duplicate AWS   │  │ Mixed Priority  │ │
│  │ Group Priorities│  │ Managed Rules   │  │   Conflicts     │ │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘ │
│                                                                 │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐ │
│  │   Test Case 4   │  │   Test Case 5   │  │   Test Case 6   │ │
│  │ Inline Rule     │  │   Edge Case     │  │ Valid Priorities│ │
│  │   Conflicts     │  │   Conflicts     │  │ (Control Test)  │ │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘ │
│                                                                 │
│  ┌─────────────────┐                                           │
│  │   Test Case 7   │                                           │
│  │  Sequential     │                                           │
│  │   Conflicts     │                                           │
│  └─────────────────┘                                           │
└─────────────────────────────────────────────────────────────────┘
```

## 📋 Test Cases

### Test Case 1: Duplicate Rule Group Priorities
**Module**: `waf_duplicate_rule_groups`
- **Purpose**: Tests duplicate priorities in custom rule groups
- **Conflict**: Two rule groups with priority 100
- **Expected Result**: ❌ VALIDATION_ERROR

### Test Case 2: Duplicate AWS Managed Rule Priorities
**Module**: `waf_duplicate_aws_managed`
- **Purpose**: Tests duplicate priorities in AWS managed rules
- **Conflict**: Two AWS managed rules with priority 200
- **Expected Result**: ❌ VALIDATION_ERROR

### Test Case 3: Mixed Priority Conflicts
**Module**: `waf_mixed_priority_conflicts`
- **Purpose**: Tests priority conflicts across different rule types
- **Conflicts**: 
  - Custom rule group vs AWS managed rule (priority 100)
  - AWS managed rule vs inline rule (priority 300)
- **Expected Result**: ❌ VALIDATION_ERROR

### Test Case 4: Multiple Inline Rule Conflicts
**Module**: `waf_inline_rule_conflicts`
- **Purpose**: Tests multiple inline rule priority conflicts
- **Conflicts**: Three inline rules with priority 500
- **Expected Result**: ❌ VALIDATION_ERROR

### Test Case 5: Edge Case Priority Conflicts
**Module**: `waf_edge_case_conflicts`
- **Purpose**: Tests edge cases and boundary conditions
- **Conflicts**: 
  - Two rule groups with minimum priority (1)
  - Rule group vs AWS managed rule (priority 1)
- **Expected Result**: ❌ VALIDATION_ERROR

### Test Case 6: Valid Priority Configuration
**Module**: `waf_valid_priorities`
- **Purpose**: Control test with valid priority configuration
- **Conflicts**: None (all priorities unique)
- **Expected Result**: ✅ SUCCESS

### Test Case 7: Sequential Priority Conflicts
**Module**: `waf_sequential_conflicts`
- **Purpose**: Tests conflicts in sequential priority assignments
- **Conflicts**: 
  - Rule group vs AWS managed rule (priority 20)
  - AWS managed rule vs inline rule (priority 40)
- **Expected Result**: ❌ VALIDATION_ERROR

## 🚀 Quick Start

### Prerequisites
- Terraform >= 1.3.0
- AWS CLI configured (for actual deployment)
- Understanding that this example is designed to fail validation

### Running the Tests

1. **Navigate to the example directory**
   ```bash
   cd waf-module-v1/examples/invalid_priority
   ```

2. **Run the validation script**
   ```bash
   # Linux/macOS/WSL
   bash test_validation.sh
   
   # Windows PowerShell
   powershell -ExecutionPolicy Bypass -File test_validation.ps1
   ```

3. **Manual testing steps**
   ```bash
   # Initialize Terraform
   terraform init
   
   # Validate configuration (should detect conflicts)
   terraform validate
   
   # Plan deployment (should fail due to conflicts)
   terraform plan
   
   # Test individual valid module (should work)
   terraform plan -target=module.waf_valid_priorities
   ```

## 📊 Expected Results

### Validation Failures (Expected)
The following modules should **fail** validation due to priority conflicts:

| Module | Conflict Type | Priority Conflicts |
|--------|---------------|-------------------|
| `waf_duplicate_rule_groups` | Rule Groups | 2 groups with priority 100 |
| `waf_duplicate_aws_managed` | AWS Managed | 2 rules with priority 200 |
| `waf_mixed_priority_conflicts` | Mixed Types | Multiple conflicts across types |
| `waf_inline_rule_conflicts` | Inline Rules | 3 rules with priority 500 |
| `waf_edge_case_conflicts` | Edge Cases | Multiple conflicts at priority 1 |
| `waf_sequential_conflicts` | Sequential | Conflicts in sequence (20, 40) |

### Validation Success (Expected)
The following module should **pass** validation:

| Module | Purpose | Result |
|--------|---------|--------|
| `waf_valid_priorities` | Control Test | ✅ All priorities unique |

## 🔍 Priority Validation Rules

The WAF module enforces these priority validation rules:

1. **Uniqueness**: All rule priorities must be unique across:
   - Custom rule groups (`rule_group_arn_list`)
   - AWS managed rules (`aws_managed_rule_groups`)
   - Inline rules (`custom_inline_rules`)

2. **Range**: Priority values must be positive integers

3. **Evaluation Order**: Lower priority values are evaluated first

4. **Conflict Detection**: The module includes built-in validation logic to detect conflicts

## 🧪 Testing Methodology

### Validation Approach
- **Intentional Conflicts**: Each test case includes deliberate priority conflicts
- **Comprehensive Coverage**: Tests all rule types and conflict scenarios
- **Control Test**: Includes one valid configuration to ensure validation logic works correctly
- **Automated Testing**: Validation scripts automate the testing process

### Test Execution Flow
1. **Structure Validation**: Verify all test cases are present
2. **Conflict Detection**: Analyze configuration for expected conflicts
3. **Terraform Init**: Initialize the configuration
4. **Validation Testing**: Run `terraform validate` (should fail for most cases)
5. **Plan Testing**: Run `terraform plan` (should fail due to conflicts)
6. **Individual Testing**: Test the valid configuration separately
7. **Results Analysis**: Verify expected outcomes

## 📈 Validation Script Features

### Bash Script (`test_validation.sh`)
- Comprehensive test coverage
- Detailed conflict analysis
- Automated result verification
- Clear success/failure reporting

### PowerShell Script (`test_validation.ps1`)
- Windows-compatible testing
- Colored output for clarity
- Same functionality as bash script
- Cross-platform consistency

### Key Features
- **Environment Checks**: Verify Terraform installation
- **Configuration Analysis**: Count modules, conflicts, and outputs
- **Automated Testing**: Run all validation steps automatically
- **Result Reporting**: Clear summary of test results
- **Documentation Validation**: Verify configuration is properly documented

## 🔧 Configuration Details

### Variables
```hcl
variable "aws_region" {
  description = "AWS region for deployment"
  default     = "us-east-1"
}

variable "name" {
  description = "Base name for WAF resources"
  default     = "priority-validation-test"
}

variable "scope" {
  description = "Scope of the WAF (REGIONAL or CLOUDFRONT)"
  default     = "REGIONAL"
}
```

### Tags
All resources are tagged for easy identification:
```hcl
tags = {
  Environment = "test"
  Purpose     = "Priority Validation Testing"
  Example     = "invalid-priority"
  TestType    = "validation-failure-expected"
}
```

## 📤 Outputs

The example provides comprehensive outputs for analysis:

- **Individual WAF ARNs**: ARN for each test case WAF
- **Validation Summary**: Detailed summary of all test cases
- **Conflict Analysis**: List of expected priority conflicts
- **Testing Metadata**: Information about the testing approach

## ⚠️ Important Notes

### This Example is Designed to Fail
- **Intentional Conflicts**: Priority conflicts are deliberate for testing
- **Expected Behavior**: Most modules should fail validation
- **Control Test**: Only `waf_valid_priorities` should deploy successfully
- **Learning Tool**: Use this to understand priority validation behavior

### Production Usage
- **Don't Deploy**: This configuration should not be deployed to production
- **Learning Purpose**: Use for understanding priority validation logic
- **Reference**: Use the `waf_valid_priorities` module as a reference for correct configuration

## 🛠️ Troubleshooting

### Common Issues

1. **All Tests Pass Unexpectedly**
   - Check if priority validation logic is working correctly
   - Verify conflicts are properly configured
   - Review module validation implementation

2. **Terraform Init Fails**
   - Ensure you're in the correct directory
   - Check module paths are correct
   - Verify Terraform version compatibility

3. **Valid Priorities Module Fails**
   - Check for any unintended priority conflicts
   - Verify all priorities are unique
   - Review module configuration

### Debugging Steps
1. Run validation scripts for detailed analysis
2. Check Terraform error messages for specific conflicts
3. Review individual module configurations
4. Verify priority assignments are as expected

## 📚 Learning Outcomes

After running this example, you should understand:

- **Priority Validation**: How WAF priority validation works
- **Conflict Detection**: What causes priority conflicts
- **Error Handling**: How Terraform reports validation errors
- **Best Practices**: Proper priority assignment patterns
- **Testing Methodology**: How to test validation logic

## 🔗 Related Examples

- **Basic WAF**: Simple WAF configuration without conflicts
- **Enterprise WAF**: Complex WAF with proper priority management
- **Custom Rules**: Examples of custom rule configurations

This comprehensive priority validation example ensures robust testing of the WAF module's validation logic and helps developers understand proper priority management in AWS WAF configurations.