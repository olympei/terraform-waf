# Basic WAF Example - Configuration Variations

This document shows different ways to configure the basic WAF example for various use cases.

## 1. Default Configuration (Current)

**Use Case**: Basic web application protection with AWS managed rules

```hcl
# Uses default values from variables
terraform apply
```

**Result**:
- Name: `basic-waf-example`
- Scope: `REGIONAL`
- Default Action: `allow`
- Rules: AWS Common + SQLi rule sets

## 2. CloudFront Configuration

**Use Case**: Protecting CloudFront distributions

```bash
terraform apply \
  -var="name=cloudfront-waf" \
  -var="scope=CLOUDFRONT"
```

**terraform.tfvars**:
```hcl
name  = "cloudfront-waf"
scope = "CLOUDFRONT"
tags = {
  Environment = "production"
  Service     = "cloudfront"
}
```

## 3. ALB Integration

**Use Case**: Protecting Application Load Balancers

```bash
terraform apply \
  -var="name=alb-waf" \
  -var='alb_arn_list=["arn:aws:elasticloadbalancing:us-east-1:123456789012:loadbalancer/app/my-alb/1234567890123456"]'
```

**terraform.tfvars**:
```hcl
name = "alb-waf"
alb_arn_list = [
  "arn:aws:elasticloadbalancing:us-east-1:123456789012:loadbalancer/app/my-alb/1234567890123456"
]
```

## 4. Strict Security Configuration

**Use Case**: High-security applications with block-by-default

```bash
terraform apply \
  -var="name=strict-waf" \
  -var="default_action=block"
```

**terraform.tfvars**:
```hcl
name           = "strict-waf"
default_action = "block"
tags = {
  Environment   = "production"
  SecurityLevel = "high"
}
```

⚠️ **Warning**: Using `default_action=block` means all traffic is blocked by default unless explicitly allowed by rules. Use with caution.

## 5. Development Environment

**Use Case**: Development/testing with relaxed settings

```bash
terraform apply \
  -var="name=dev-waf" \
  -var="default_action=allow"
```

**terraform.tfvars**:
```hcl
name           = "dev-waf"
default_action = "allow"
tags = {
  Environment = "development"
  Purpose     = "testing"
  AutoDelete  = "true"
}
```

## 6. Multi-Environment Setup

**Use Case**: Different configurations per environment

### Development
```hcl
# dev.tfvars
name           = "dev-basic-waf"
default_action = "allow"
tags = {
  Environment = "development"
  CostCenter  = "engineering"
}
```

### Staging
```hcl
# staging.tfvars
name           = "staging-basic-waf"
default_action = "allow"
alb_arn_list = [
  "arn:aws:elasticloadbalancing:us-east-1:123456789012:loadbalancer/app/staging-alb/1234567890123456"
]
tags = {
  Environment = "staging"
  CostCenter  = "engineering"
}
```

### Production
```hcl
# prod.tfvars
name           = "prod-basic-waf"
default_action = "allow"
alb_arn_list = [
  "arn:aws:elasticloadbalancing:us-east-1:123456789012:loadbalancer/app/prod-alb/1234567890123456"
]
tags = {
  Environment = "production"
  CostCenter  = "security"
  Compliance  = "required"
}
```

**Deployment**:
```bash
# Deploy to different environments
terraform apply -var-file="dev.tfvars"
terraform apply -var-file="staging.tfvars"
terraform apply -var-file="prod.tfvars"
```

## 7. Cost-Optimized Configuration

**Use Case**: Minimal cost while maintaining essential protection

The current basic configuration is already cost-optimized with only essential AWS managed rules. For even lower costs, you could create a minimal version:

```hcl
# minimal-waf.tfvars
name = "minimal-waf"
# Remove one of the AWS managed rule groups if budget is very tight
# Note: This reduces security coverage
```

## 8. Testing Configuration

**Use Case**: Testing WAF rules without blocking traffic

```bash
# Deploy with count mode for testing
terraform apply \
  -var="name=test-waf"

# Then manually change rule actions to "count" in AWS console for testing
# Or create a custom version with count override actions
```

## Configuration File Templates

### Basic terraform.tfvars
```hcl
name           = "my-basic-waf"
scope          = "REGIONAL"
default_action = "allow"
alb_arn_list   = []
tags = {
  Environment = "production"
  Application = "web-app"
  Owner       = "platform-team"
}
```

### Advanced terraform.tfvars
```hcl
name           = "advanced-basic-waf"
scope          = "REGIONAL"
default_action = "allow"
alb_arn_list = [
  "arn:aws:elasticloadbalancing:us-east-1:123456789012:loadbalancer/app/web-app-alb/1234567890123456",
  "arn:aws:elasticloadbalancing:us-east-1:123456789012:loadbalancer/app/api-app-alb/1234567890123456"
]
tags = {
  Environment     = "production"
  Application     = "web-platform"
  Owner          = "platform-team"
  CostCenter     = "engineering"
  Compliance     = "sox-compliant"
  BackupRequired = "true"
}
```

## Validation Commands

For each configuration, validate before applying:

```bash
# Validate configuration
terraform validate

# Check plan
terraform plan -var-file="your-config.tfvars"

# Apply with confirmation
terraform apply -var-file="your-config.tfvars"

# Verify outputs
terraform output basic_waf_summary
```

## Common Customization Patterns

### 1. Name Patterns
```hcl
# Environment-based naming
name = "${var.environment}-${var.application}-waf"

# Service-based naming  
name = "${var.service}-basic-waf"

# Region-based naming
name = "basic-waf-${var.region}"
```

### 2. Tag Patterns
```hcl
tags = {
  Environment   = var.environment
  Application   = var.application
  Owner        = var.team
  CostCenter   = var.cost_center
  CreatedBy    = "terraform"
  Module       = "basic-waf"
  LastModified = timestamp()
}
```

### 3. Conditional ALB Association
```hcl
# Only associate with ALB in production
alb_arn_list = var.environment == "production" ? var.production_alb_arns : []
```

These examples show how flexible the basic WAF configuration can be while maintaining simplicity and essential security protection.