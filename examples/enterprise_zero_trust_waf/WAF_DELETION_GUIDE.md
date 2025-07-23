# WAF Deletion Guide: Handling Associated Resource Dependencies

## 🚨 Issue Description

**Error**: `WAFAssociatedItemException: AWS WAF couldn't perform the operation because your resource is being used by another resource or it's associated with another resource`

**Root Cause**: AWS WAF prevents deletion of rule groups that are still referenced by Web ACLs.

## 🔍 Understanding WAF Dependencies

### Resource Hierarchy
```
ALB/CloudFront Distribution
    ↓ (associated with)
WAF Web ACL
    ↓ (references)
WAF Rule Groups
    ↓ (contains)
Individual Rules
```

### Deletion Order Requirements
AWS requires resources to be deleted in reverse dependency order:
1. **Disassociate Web ACL** from ALB/CloudFront
2. **Remove Rule Group references** from Web ACL
3. **Delete Rule Groups**
4. **Delete Web ACL**

## ✅ Solution Methods

### Method 1: Terraform Destroy with Proper Steps

#### Step 1: Remove ALB Association (if applicable)
```bash
# Option A: Set alb_arn_list to empty
terraform apply -var='alb_arn_list=[]'

# Option B: Comment out alb_arn_list in terraform.tfvars
# alb_arn_list = []
```

#### Step 2: Remove Rule Group References
```bash
# Temporarily remove rule groups from Web ACL
terraform apply -var='rule_group_arn_list=[]'
```

#### Step 3: Full Destroy
```bash
# Now safe to destroy everything
terraform destroy
```

### Method 2: AWS CLI Manual Cleanup

#### Step 1: List Associated Resources
```bash
# Find your Web ACL
aws wafv2 list-web-acls --scope REGIONAL

# Get Web ACL details
aws wafv2 get-web-acl --scope REGIONAL --id <web-acl-id>
```

#### Step 2: Disassociate from ALB
```bash
# Find associated ALBs
aws wafv2 list-resources-for-web-acl --web-acl-arn <web-acl-arn>

# Disassociate from ALB
aws wafv2 disassociate-web-acl --resource-arn <alb-arn>
```

#### Step 3: Update Web ACL (Remove Rule Groups)
```bash
# Get current Web ACL configuration
aws wafv2 get-web-acl --scope REGIONAL --id <web-acl-id> > current-acl.json

# Edit the JSON to remove rule group references
# Update Web ACL with empty rules
aws wafv2 update-web-acl --cli-input-json file://updated-acl.json
```

#### Step 4: Delete Resources
```bash
# Delete rule groups
aws wafv2 delete-rule-group --scope REGIONAL --id <rule-group-id>

# Delete Web ACL
aws wafv2 delete-web-acl --scope REGIONAL --id <web-acl-id>
```

### Method 3: Terraform Targeted Destroy

#### Step 1: Target Specific Resources
```bash
# Remove ALB association first
terraform destroy -target="aws_wafv2_web_acl_association.this"

# Remove rule group references
terraform apply -var='rule_group_arn_list=[]'

# Destroy rule groups
terraform destroy -target="module.zero_trust_allow_rules"

# Destroy Web ACL
terraform destroy -target="module.enterprise_zero_trust_waf.aws_wafv2_web_acl.this"
```

## 🛠️ Prevention Strategies

### 1. Enhanced Lifecycle Management
The modules now include lifecycle rules to handle dependencies better:

```hcl
resource "aws_wafv2_rule_group" "this" {
  # ... configuration ...
  
  lifecycle {
    create_before_destroy = true
    prevent_destroy       = false
  }
}
```

### 2. Dependency Ordering
Ensure proper `depends_on` relationships:

```hcl
resource "aws_wafv2_web_acl_logging_configuration" "this" {
  # ... configuration ...
  
  depends_on = [aws_wafv2_web_acl.this]
}
```

### 3. Conditional Resource Creation
Use variables to control resource creation:

```hcl
variable "enable_waf" {
  description = "Enable WAF resources"
  type        = bool
  default     = true
}

resource "aws_wafv2_web_acl" "this" {
  count = var.enable_waf ? 1 : 0
  # ... configuration ...
}
```

## 🚀 Automated Cleanup Script

Create a cleanup script for safe WAF deletion:

```bash
#!/bin/bash
# waf_cleanup.sh

set -e

echo "🧹 Starting WAF Cleanup Process..."

# Step 1: Remove ALB associations
echo "1️⃣ Removing ALB associations..."
terraform apply -var='alb_arn_list=[]' -auto-approve

# Step 2: Remove rule group references
echo "2️⃣ Removing rule group references..."
terraform apply -var='rule_group_arn_list=[]' -auto-approve

# Step 3: Wait for propagation
echo "⏳ Waiting for changes to propagate..."
sleep 30

# Step 4: Destroy everything
echo "3️⃣ Destroying all WAF resources..."
terraform destroy -auto-approve

echo "✅ WAF cleanup completed successfully!"
```

Usage:
```bash
chmod +x waf_cleanup.sh
./waf_cleanup.sh
```

## 📋 Troubleshooting Common Issues

### Issue 1: "Resource still in use"
**Solution**: Wait longer for AWS propagation (up to 5 minutes)
```bash
sleep 300  # Wait 5 minutes
terraform destroy
```

### Issue 2: "Cannot delete Web ACL with associated resources"
**Solution**: Check for hidden associations
```bash
# List all resources associated with Web ACL
aws wafv2 list-resources-for-web-acl --web-acl-arn <arn>

# Manually disassociate each resource
aws wafv2 disassociate-web-acl --resource-arn <resource-arn>
```

### Issue 3: "Rule group has dependent resources"
**Solution**: Check for multiple Web ACLs using the same rule group
```bash
# Search for Web ACLs that might reference the rule group
aws wafv2 list-web-acls --scope REGIONAL
```

## ⚠️ Important Notes

### AWS Propagation Delays
- WAF changes can take 1-5 minutes to propagate globally
- Always wait between disassociation and deletion steps
- Use `sleep` commands in automation scripts

### Cost Considerations
- WAF resources continue to incur costs until fully deleted
- Monitor AWS billing during cleanup process
- Ensure all resources are actually deleted

### Backup Considerations
- Export WAF configurations before deletion
- Save rule group definitions for potential recreation
- Document custom rule logic

## 🔧 Emergency Recovery

If you need to quickly remove WAF protection:

### Emergency Disassociation
```bash
# Quick ALB disassociation (emergency only)
aws wafv2 disassociate-web-acl --resource-arn <alb-arn>
```

### Emergency Web ACL Update
```bash
# Remove all rules from Web ACL (emergency only)
aws wafv2 update-web-acl \
  --scope REGIONAL \
  --id <web-acl-id> \
  --default-action Allow={} \
  --rules '[]'
```

## ✅ Best Practices

1. **Plan Destruction**: Always plan the destruction process before starting
2. **Use Staging**: Test destruction process in staging environment first
3. **Monitor Costs**: Watch for unexpected charges during cleanup
4. **Document Process**: Keep records of custom configurations
5. **Automate Safely**: Use scripts but include safety checks
6. **Verify Completion**: Confirm all resources are deleted in AWS Console

---

*This guide ensures safe and complete removal of WAF resources while avoiding dependency conflicts.*