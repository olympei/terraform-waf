# Enterprise WAF Deployment Guide

This guide provides comprehensive instructions for deploying AWS WAF v2 modules in enterprise environments.

## 🏢 Enterprise Deployment Scenarios

### Scenario 1: New Enterprise Deployment

For organizations deploying WAF for the first time:

```hcl
# terraform/environments/prod/main.tf
module "enterprise_waf" {
  source = "../../../examples/enterprise_secure_waf"
  
  # Basic Configuration
  name         = "prod-enterprise-waf"
  environment  = "prod"
  scope        = "REGIONAL"
  alb_arn_list = [
    "arn:aws:elasticloadbalancing:us-east-1:123456789012:loadbalancer/app/prod-web-alb/1234567890123456",
    "arn:aws:elasticloadbalancing:us-east-1:123456789012:loadbalancer/app/prod-api-alb/1234567890123457"
  ]
  
  # Security Configuration
  high_risk_countries = ["CN", "RU", "KP", "IR", "SY", "CU", "SD", "MM", "AF", "IQ"]
  rate_limit_strict   = 100
  rate_limit_api      = 1000
  rate_limit_web      = 5000
  
  # Logging Configuration
  enable_logging           = true
  create_log_group        = true
  log_group_retention_days = 365
  enable_kms_encryption   = true
  
  # Enterprise Tags
  tags = {
    Environment     = "production"
    Application     = "enterprise-web"
    Owner          = "security-team"
    CostCenter     = "security"
    Compliance     = "pci-dss-sox-hipaa"
    Criticality    = "high"
    BackupRequired = "true"
    MonitoringLevel = "enhanced"
  }
}
```

### Scenario 2: Using Existing Log Group and KMS Key

For organizations with existing logging infrastructure:

```hcl
module "enterprise_waf_existing_resources" {
  source = "../../../examples/enterprise_secure_waf"
  
  name         = "prod-enterprise-waf"
  environment  = "prod"
  alb_arn_list = var.alb_arns
  
  # Use existing logging resources
  enable_logging         = true
  create_log_group      = false
  existing_log_group_arn = "arn:aws:logs:us-east-1:123456789012:log-group:/security/waf/prod"
  enable_kms_encryption = true
  kms_key_id           = "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"
  
  # Security settings
  high_risk_countries = var.blocked_countries
  rate_limit_strict   = 50
  rate_limit_api      = 500
  rate_limit_web      = 2000
  
  tags = var.common_tags
}
```

### Scenario 3: Multi-Region Deployment

For global applications requiring WAF in multiple regions:

```hcl
# US East (Primary)
module "waf_us_east" {
  source = "../../../examples/enterprise_secure_waf"
  
  providers = {
    aws = aws.us_east_1
  }
  
  name         = "global-enterprise-waf-use1"
  environment  = "prod"
  scope        = "REGIONAL"
  alb_arn_list = var.us_east_alb_arns
  
  # Regional configuration
  high_risk_countries      = var.global_blocked_countries
  rate_limit_strict       = 100
  enable_logging          = true
  log_group_retention_days = 365
  
  tags = merge(var.common_tags, {
    Region = "us-east-1"
  })
}

# EU West (Secondary)
module "waf_eu_west" {
  source = "../../../examples/enterprise_secure_waf"
  
  providers = {
    aws = aws.eu_west_1
  }
  
  name         = "global-enterprise-waf-euw1"
  environment  = "prod"
  scope        = "REGIONAL"
  alb_arn_list = var.eu_west_alb_arns
  
  # Regional configuration
  high_risk_countries      = var.global_blocked_countries
  rate_limit_strict       = 100
  enable_logging          = true
  log_group_retention_days = 365
  
  tags = merge(var.common_tags, {
    Region = "eu-west-1"
  })
}
```

## 🔧 Environment-Specific Configurations

### Production Environment

```hcl
# environments/prod/terraform.tfvars
name                     = "prod-enterprise-waf"
environment             = "prod"
scope                   = "REGIONAL"

# ALB Configuration
alb_arn_list = [
  "arn:aws:elasticloadbalancing:us-east-1:123456789012:loadbalancer/app/prod-web/1234567890123456",
  "arn:aws:elasticloadbalancing:us-east-1:123456789012:loadbalancer/app/prod-api/1234567890123457"
]

# Security Configuration
high_risk_countries = ["CN", "RU", "KP", "IR", "SY", "CU", "SD", "MM", "AF", "IQ"]
rate_limit_strict   = 100
rate_limit_api      = 1000
rate_limit_web      = 5000

# Logging Configuration
enable_logging           = true
create_log_group        = true
log_group_retention_days = 365
enable_kms_encryption   = true

# Tags
tags = {
  Environment     = "production"
  Application     = "enterprise-web"
  Owner          = "security-team"
  CostCenter     = "security"
  Compliance     = "pci-dss-sox-hipaa"
  Criticality    = "high"
  DataClass      = "confidential"
  BackupRequired = "true"
}
```

### Staging Environment

```hcl
# environments/staging/terraform.tfvars
name                     = "staging-enterprise-waf"
environment             = "staging"
scope                   = "REGIONAL"

# ALB Configuration
alb_arn_list = [
  "arn:aws:elasticloadbalancing:us-east-1:123456789012:loadbalancer/app/staging-web/1234567890123456"
]

# Relaxed Security Configuration for Testing
high_risk_countries = ["KP", "IR"]  # Reduced list for testing
rate_limit_strict   = 500
rate_limit_api      = 2000
rate_limit_web      = 10000

# Logging Configuration
enable_logging           = true
create_log_group        = true
log_group_retention_days = 90
enable_kms_encryption   = false  # Cost optimization for staging

# Tags
tags = {
  Environment     = "staging"
  Application     = "enterprise-web"
  Owner          = "development-team"
  CostCenter     = "development"
  Criticality    = "medium"
  AutoShutdown   = "true"
}
```

### Development Environment

```hcl
# environments/dev/terraform.tfvars
name                     = "dev-enterprise-waf"
environment             = "dev"
scope                   = "REGIONAL"

# ALB Configuration
alb_arn_list = [
  "arn:aws:elasticloadbalancing:us-east-1:123456789012:loadbalancer/app/dev-web/1234567890123456"
]

# Minimal Security Configuration
high_risk_countries = []  # No geographic blocking in dev
rate_limit_strict   = 1000
rate_limit_api      = 5000
rate_limit_web      = 20000

# Basic Logging
enable_logging           = true
create_log_group        = true
log_group_retention_days = 30
enable_kms_encryption   = false

# Tags
tags = {
  Environment     = "development"
  Application     = "enterprise-web"
  Owner          = "development-team"
  CostCenter     = "development"
  Criticality    = "low"
  AutoShutdown   = "true"
  DeleteAfter    = "30-days"
}
```

## 🏗️ Infrastructure as Code Structure

### Recommended Directory Structure

```
terraform/
├── environments/
│   ├── prod/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   ├── terraform.tfvars
│   │   └── backend.tf
│   ├── staging/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   ├── terraform.tfvars
│   │   └── backend.tf
│   └── dev/
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       ├── terraform.tfvars
│       └── backend.tf
├── modules/
│   └── waf-module-v1/  # This repository as a submodule
└── shared/
    ├── variables.tf
    ├── locals.tf
    └── data.tf
```

### Backend Configuration

```hcl
# environments/prod/backend.tf
terraform {
  backend "s3" {
    bucket         = "your-org-terraform-state-prod"
    key            = "waf/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock-prod"
    
    # Additional security
    kms_key_id = "arn:aws:kms:us-east-1:123456789012:key/terraform-state-key"
  }
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  
  required_version = ">= 1.5"
}
```

## 🔐 Security Hardening

### IAM Permissions

Create dedicated IAM roles for WAF deployment:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "wafv2:*",
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams",
        "kms:CreateKey",
        "kms:DescribeKey",
        "kms:GetKeyPolicy",
        "kms:PutKeyPolicy",
        "kms:EnableKeyRotation",
        "elasticloadbalancing:DescribeLoadBalancers",
        "elasticloadbalancing:ModifyLoadBalancerAttributes"
      ],
      "Resource": "*"
    }
  ]
}
```

### Network Security

Ensure WAF deployment follows network security best practices:

```hcl
# Network ACL rules for WAF management
resource "aws_network_acl_rule" "waf_management" {
  network_acl_id = var.management_nacl_id
  rule_number    = 100
  protocol       = "tcp"
  rule_action    = "allow"
  port_range {
    from = 443
    to   = 443
  }
  cidr_block = "10.0.0.0/8"  # Internal management network
}
```

## 📊 Monitoring and Alerting

### CloudWatch Alarms

```hcl
# High blocked request rate alarm
resource "aws_cloudwatch_metric_alarm" "waf_high_blocked_requests" {
  alarm_name          = "waf-high-blocked-requests-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "BlockedRequests"
  namespace           = "AWS/WAFV2"
  period              = "300"
  statistic           = "Sum"
  threshold           = "1000"
  alarm_description   = "High number of blocked requests detected"
  alarm_actions       = [aws_sns_topic.security_alerts.arn]

  dimensions = {
    WebACL = module.enterprise_waf.enterprise_waf_id
    Region = var.aws_region
  }

  tags = var.tags
}

# WAF rule group capacity alarm
resource "aws_cloudwatch_metric_alarm" "waf_capacity_utilization" {
  alarm_name          = "waf-capacity-utilization-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "ConsumedCapacity"
  namespace           = "AWS/WAFV2"
  period              = "300"
  statistic           = "Maximum"
  threshold           = "1400"  # 70% of 2000 WCU limit
  alarm_description   = "WAF capacity utilization is high"
  alarm_actions       = [aws_sns_topic.operations_alerts.arn]

  dimensions = {
    WebACL = module.enterprise_waf.enterprise_waf_id
  }

  tags = var.tags
}
```

### Log Analysis Dashboard

```hcl
resource "aws_cloudwatch_dashboard" "waf_security_dashboard" {
  dashboard_name = "WAF-Security-Dashboard-${var.environment}"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/WAFV2", "AllowedRequests", "WebACL", module.enterprise_waf.enterprise_waf_id],
            [".", "BlockedRequests", ".", "."],
            [".", "CountedRequests", ".", "."]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "WAF Request Metrics"
          period  = 300
        }
      },
      {
        type   = "log"
        x      = 0
        y      = 6
        width  = 24
        height = 6

        properties = {
          query   = "SOURCE '${module.enterprise_waf.waf_log_group_name}' | fields @timestamp, action, terminatingRuleId, httpRequest.clientIp, httpRequest.country\n| filter action = \"BLOCK\"\n| stats count() by terminatingRuleId\n| sort count desc"
          region  = var.aws_region
          title   = "Top Blocking Rules"
        }
      }
    ]
  })
}
```

## 🚀 Deployment Pipeline

### GitLab CI/CD Pipeline

```yaml
# .gitlab-ci.yml
stages:
  - validate
  - plan
  - deploy
  - test

variables:
  TF_ROOT: terraform/environments
  TF_VERSION: "1.5.7"

.terraform_base: &terraform_base
  image: hashicorp/terraform:$TF_VERSION
  before_script:
    - cd $TF_ROOT/$ENVIRONMENT
    - terraform init -backend-config="bucket=$TF_STATE_BUCKET"

validate:
  <<: *terraform_base
  stage: validate
  script:
    - terraform validate
    - terraform fmt -check
  parallel:
    matrix:
      - ENVIRONMENT: [dev, staging, prod]

plan_dev:
  <<: *terraform_base
  stage: plan
  variables:
    ENVIRONMENT: dev
  script:
    - terraform plan -var-file="terraform.tfvars" -out=plan.out
  artifacts:
    paths:
      - $TF_ROOT/dev/plan.out
    expire_in: 1 hour
  only:
    - develop

plan_staging:
  <<: *terraform_base
  stage: plan
  variables:
    ENVIRONMENT: staging
  script:
    - terraform plan -var-file="terraform.tfvars" -out=plan.out
  artifacts:
    paths:
      - $TF_ROOT/staging/plan.out
    expire_in: 1 hour
  only:
    - main

plan_prod:
  <<: *terraform_base
  stage: plan
  variables:
    ENVIRONMENT: prod
  script:
    - terraform plan -var-file="terraform.tfvars" -out=plan.out
  artifacts:
    paths:
      - $TF_ROOT/prod/plan.out
    expire_in: 1 hour
  only:
    - main
  when: manual

deploy_dev:
  <<: *terraform_base
  stage: deploy
  variables:
    ENVIRONMENT: dev
  script:
    - terraform apply plan.out
  dependencies:
    - plan_dev
  only:
    - develop

deploy_staging:
  <<: *terraform_base
  stage: deploy
  variables:
    ENVIRONMENT: staging
  script:
    - terraform apply plan.out
  dependencies:
    - plan_staging
  only:
    - main
  when: manual

deploy_prod:
  <<: *terraform_base
  stage: deploy
  variables:
    ENVIRONMENT: prod
  script:
    - terraform apply plan.out
  dependencies:
    - plan_prod
  only:
    - main
  when: manual
  environment:
    name: production

waf_test:
  stage: test
  image: alpine:latest
  before_script:
    - apk add --no-cache curl jq
  script:
    - |
      # Test WAF is blocking malicious requests
      response=$(curl -s -o /dev/null -w "%{http_code}" "https://your-app.com/?id=1' OR '1'='1")
      if [ "$response" != "403" ]; then
        echo "WAF is not blocking SQL injection attempts"
        exit 1
      fi
      echo "WAF is working correctly"
  only:
    - main
  when: manual
```

## 📋 Compliance Checklist

### Pre-Deployment Checklist

- [ ] **Security Review**: Security team has reviewed WAF configuration
- [ ] **Compliance Approval**: Compliance team has approved logging configuration
- [ ] **Network Review**: Network team has reviewed ALB associations
- [ ] **Cost Approval**: Finance team has approved estimated costs
- [ ] **Backup Plan**: Rollback procedures are documented and tested
- [ ] **Monitoring Setup**: CloudWatch alarms and dashboards are configured
- [ ] **Documentation**: Deployment guide and runbooks are updated

### Post-Deployment Checklist

- [ ] **Functionality Test**: WAF is blocking malicious requests
- [ ] **Performance Test**: Application performance is not impacted
- [ ] **Logging Verification**: Logs are being generated and stored correctly
- [ ] **Monitoring Verification**: Alarms and dashboards are working
- [ ] **Documentation Update**: As-built documentation is updated
- [ ] **Team Notification**: Operations and security teams are notified

## 🆘 Troubleshooting Guide

### Common Issues and Solutions

#### Issue: WAF Rules Not Blocking Traffic

**Symptoms**: Malicious requests are not being blocked

**Diagnosis**:
```bash
# Check WAF metrics
aws cloudwatch get-metric-statistics \
  --namespace AWS/WAFV2 \
  --metric-name BlockedRequests \
  --dimensions Name=WebACL,Value=your-waf-name \
  --start-time 2024-01-01T00:00:00Z \
  --end-time 2024-01-01T23:59:59Z \
  --period 3600 \
  --statistics Sum
```

**Solutions**:
1. Verify rule priorities and actions
2. Check rule statement configuration
3. Review CloudWatch logs for rule evaluation

#### Issue: High WCU Consumption

**Symptoms**: WAF capacity alarms triggering

**Diagnosis**:
```bash
# Check WCU usage by rule
aws wafv2 get-web-acl --scope REGIONAL --id your-waf-id
```

**Solutions**:
1. Optimize rule complexity
2. Remove redundant rules
3. Consider rule group consolidation

#### Issue: Logging Not Working

**Symptoms**: No logs appearing in CloudWatch

**Diagnosis**:
```bash
# Check log group configuration
aws logs describe-log-groups --log-group-name-prefix /aws/wafv2/
```

**Solutions**:
1. Verify IAM permissions
2. Check log group configuration
3. Ensure logging is enabled on WAF ACL

## 📞 Support and Escalation

### Support Tiers

1. **Level 1**: Development team (configuration issues)
2. **Level 2**: Security team (rule effectiveness, false positives)
3. **Level 3**: Cloud architecture team (infrastructure issues)
4. **Level 4**: AWS Support (platform issues)

### Escalation Procedures

1. **Immediate**: Security incidents, service outages
2. **High**: Performance degradation, compliance issues
3. **Medium**: Configuration changes, optimization requests
4. **Low**: Documentation updates, enhancement requests

---

This enterprise deployment guide provides comprehensive instructions for deploying AWS WAF v2 modules in production environments with proper security, compliance, and operational considerations.