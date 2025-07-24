# Enterprise AWS WAF v2 Terraform Modules

[![Terraform](https://img.shields.io/badge/terraform-%235835CC.svg?style=for-the-badge&logo=terraform&logoColor=white)](https://www.terraform.io/)
[![AWS](https://img.shields.io/badge/AWS-%23FF9900.svg?style=for-the-badge&logo=amazon-aws&logoColor=white)](https://aws.amazon.com/)
[![Security](https://img.shields.io/badge/Security-Critical-red?style=for-the-badge)](https://github.com/your-org/waf-module-v1)
[![Enterprise](https://img.shields.io/badge/Enterprise-Ready-blue?style=for-the-badge)](https://github.com/your-org/waf-module-v1)

**Production-ready AWS WAF v2 Terraform modules** designed for enterprise environments with comprehensive security controls, compliance features, and operational excellence. Battle-tested in production environments protecting critical applications and APIs.

## 🏢 Enterprise Features

### Security & Compliance
- **🛡️ Zero Trust Security Model**: Default-deny with explicit allow rules and comprehensive threat protection
- **🌍 Multi-Layer Protection**: Geographic blocking, application security, behavioral analysis, and bot protection
- **📋 Compliance Ready**: Built-in logging, monitoring, audit capabilities for PCI DSS, SOX, HIPAA, GDPR
- **🔐 Advanced Threat Protection**: SQL injection, XSS, path traversal, command injection, and file upload security
- **🚫 Rate Limiting**: Multi-tier rate limiting with IP reputation and forwarded IP support

### Operational Excellence
- **💰 Cost Optimized**: Efficient WCU usage, rule prioritization, and capacity management
- **🏭 Production Hardened**: Battle-tested configurations protecting enterprise workloads
- **📊 Comprehensive Monitoring**: CloudWatch metrics, logs, insights queries, and real-time alerting
- **🔄 Infrastructure as Code**: Fully automated deployment with Terraform best practices
- **📈 Scalable Architecture**: Modular design supporting multi-environment and multi-application deployments

### Enterprise Integration
- **🏗️ Modular Design**: Reusable components for WAF ACLs, rule groups, and security policies
- **🔗 ALB Integration**: Seamless integration with Application Load Balancers
- **📝 Comprehensive Logging**: CloudWatch integration with KMS encryption and configurable retention
- **🏷️ Resource Tagging**: Consistent tagging strategy for cost allocation and governance
- **🔧 Flexible Configuration**: Support for existing resources and custom security requirements

## 📁 Module Architecture

```
waf-module-v1/
├── modules/
│   ├── waf/                    # Core WAF ACL module
│   └── waf-rule-group/         # Custom rule group module
├── examples/
│   ├── basic/                  # Simple WAF setup
│   ├── enterprise_zero_trust_waf/  # Zero-trust enterprise configuration
│   └── enterprise_secure_waf/      # Comprehensive security configuration
└── docs/                       # Documentation and guides
```

### Core Modules

#### 🛡️ WAF Module (`modules/waf`)
- **Purpose**: Creates AWS WAF v2 Web ACL with comprehensive enterprise protection
- **Features**: Rule group association, ALB integration, CloudWatch logging
- **Use Case**: Main WAF deployment for applications and APIs

#### � WAF Rule Group Module (`modules/waf-rule-group`)
- **Purpose**: Creates reusable custom rule groups
- **Features**: Dynamic rule creation, complex statement logic, AND/OR operations
- **Use Case**: Specialized security rules, compliance requirements

## 🚀 Quick Start Guide

### 1. Basic WAF Deployment

```hcl
module "basic_waf" {
  source = "./modules/waf"
  
  name           = "my-application-waf"
  scope          = "REGIONAL"
  default_action = "allow"
  alb_arn_list   = ["arn:aws:elasticloadbalancing:us-east-1:123456789012:loadbalancer/app/my-alb/1234567890123456"]
  
  aws_managed_rule_groups = [
    {
      name            = "AWSManagedRulesCommonRuleSet"
      vendor_name     = "AWS"
      priority        = 100
      override_action = "none"
    }
  ]
  
  tags = {
    Environment = "production"
    Application = "web-app"
  }
}
```

### 2. Enterprise Zero Trust WAF

```hcl
module "enterprise_zero_trust_waf" {
  source = "./examples/enterprise_zero_trust_waf"
  
  name                    = "enterprise-zero-trust-waf"
  environment            = "prod"
  alb_arn_list           = var.alb_arns
  high_risk_countries    = ["CN", "RU", "KP", "IR"]
  rate_limit_strict      = 100
  enable_logging         = true
  enable_kms_encryption  = true
  
  tags = {
    Environment     = "production"
    SecurityLevel   = "maximum"
    Compliance      = "pci-dss-sox"
    CostCenter      = "security"
  }
}
```

### 3. Custom Rule Group

```hcl
module "api_protection_rules" {
  source = "./modules/waf-rule-group"
  
  rule_group_name = "api-protection-rules"
  name            = "api-protection"
  scope           = "REGIONAL"
  capacity        = 200
  
  custom_rules = [
    {
      name        = "BlockSQLInjection"
      priority    = 10
      action      = "block"
      metric_name = "block_sqli"
      statement_config = {
        sqli_match_statement = {
          field_to_match = {
            all_query_arguments = {}
          }
          text_transformation = {
            priority = 1
            type     = "URL_DECODE"
          }
        }
      }
    }
  ]
}
```

## 🏢 Enterprise Deployment Patterns

### Pattern 1: Multi-Environment Setup

```hcl
# Production Environment
module "prod_waf" {
  source = "./examples/enterprise_secure_waf"
  
  name                    = "prod-enterprise-waf"
  environment            = "prod"
  alb_arn_list           = var.prod_alb_arns
  
  # Production security settings
  rate_limit_strict      = 100
  rate_limit_api         = 1000
  rate_limit_web         = 5000
  high_risk_countries    = ["CN", "RU", "KP", "IR", "SY", "CU", "SD", "MM", "AF", "IQ"]
  
  # Production logging and compliance
  enable_logging           = true
  create_log_group        = true
  log_group_retention_days = 365
  enable_kms_encryption   = true
  
  tags = {
    Environment     = "production"
    Criticality     = "high"
    Compliance      = "pci-dss-sox-hipaa"
    SecurityLevel   = "maximum"
    CostCenter      = "security"
    Owner           = "security-team"
    BackupRequired  = "true"
  }
}

# Staging Environment
module "staging_waf" {
  source = "./examples/enterprise_secure_waf"
  
  name                    = "staging-enterprise-waf"
  environment            = "staging"
  alb_arn_list           = var.staging_alb_arns
  
  # Relaxed settings for testing
  rate_limit_strict      = 500
  rate_limit_api         = 2000
  rate_limit_web         = 10000
  high_risk_countries    = ["CN", "RU", "KP", "IR"]  # Reduced list for testing
  
  # Staging logging
  enable_logging           = true
  create_log_group        = true
  log_group_retention_days = 90
  enable_kms_encryption   = false
  
  tags = {
    Environment   = "staging"
    Criticality   = "medium"
    Purpose       = "testing"
    CostCenter    = "development"
  }
}

# Development Environment
module "dev_waf" {
  source = "./examples/basic"
  
  name                = "dev-basic-waf"
  alb_arn_list       = var.dev_alb_arns
  enable_logging     = false  # Minimal logging for dev
  
  tags = {
    Environment = "development"
    Criticality = "low"
    Purpose     = "development"
  }
}
```

### Pattern 2: Shared Rule Groups Architecture

```hcl
# Corporate Security Baseline
module "corporate_security_rules" {
  source = "./modules/waf-rule-group"
  
  rule_group_name = "corporate-security-baseline"
  name            = "corporate-baseline"
  scope           = "REGIONAL"
  capacity        = 300
  metric_name     = "CorporateSecurityBaseline"
  
  custom_rules = [
    # Corporate IP whitelist
    {
      name        = "AllowCorporateIPs"
      priority    = 10
      action      = "allow"
      metric_name = "allow_corporate_ips"
      statement_config = {
        ip_set_reference_statement = {
          arn = aws_wafv2_ip_set.corporate_ips.arn
        }
      }
    },
    # Block known malicious IPs
    {
      name        = "BlockMaliciousIPs"
      priority    = 20
      action      = "block"
      metric_name = "block_malicious_ips"
      statement_config = {
        ip_set_reference_statement = {
          arn = aws_wafv2_ip_set.malicious_ips.arn
        }
      }
    }
  ]
  
  tags = {
    RuleGroupType = "Corporate-Baseline"
    Scope         = "Global"
    Criticality   = "high"
  }
}

# Industry-Specific Rules (e.g., Financial Services)
module "finserv_compliance_rules" {
  source = "./modules/waf-rule-group"
  
  rule_group_name = "finserv-compliance-rules"
  name            = "finserv-compliance"
  scope           = "REGIONAL"
  capacity        = 200
  
  custom_rules = [
    # PCI DSS specific rules
    {
      name        = "BlockCreditCardPatterns"
      priority    = 10
      action      = "block"
      metric_name = "block_cc_patterns"
      statement_config = {
        regex_pattern_set_reference_statement = {
          arn = aws_wafv2_regex_pattern_set.credit_card_patterns.arn
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
  ]
  
  tags = {
    RuleGroupType = "Compliance"
    Industry      = "Financial-Services"
    Standard      = "PCI-DSS"
  }
}

# Application-Specific WAF with Shared Rules
module "trading_app_waf" {
  source = "./modules/waf"
  
  name           = "trading-application-waf"
  scope          = "REGIONAL"
  default_action = "allow"
  alb_arn_list   = var.trading_app_alb_arns
  
  # Shared rule groups (ordered by priority)
  rule_group_arn_list = [
    {
      arn      = module.corporate_security_rules.waf_rule_group_arn
      name     = "corporate-baseline"
      priority = 100
    },
    {
      arn      = module.finserv_compliance_rules.waf_rule_group_arn
      name     = "finserv-compliance"
      priority = 200
    }
  ]
  
  # AWS managed rules
  aws_managed_rule_groups = [
    {
      name            = "AWSManagedRulesCommonRuleSet"
      vendor_name     = "AWS"
      priority        = 300
      override_action = "none"
    },
    {
      name            = "AWSManagedRulesSQLiRuleSet"
      vendor_name     = "AWS"
      priority        = 301
      override_action = "none"
    }
  ]
  
  # Application-specific inline rules
  custom_inline_rules = [
    {
      name        = "ProtectTradingAPI"
      priority    = 500
      action      = "block"
      metric_name = "protect_trading_api"
      statement_config = {
        byte_match_statement = {
          search_string         = "/api/trading"
          positional_constraint = "STARTS_WITH"
          field_to_match = {
            uri_path = {}
          }
          text_transformation = {
            priority = 0
            type     = "LOWERCASE"
          }
        }
      }
    }
  ]
  
  tags = {
    Application   = "trading-platform"
    Environment   = "production"
    Criticality   = "critical"
    DataClass     = "restricted"
  }
}
```

### Pattern 3: Multi-Region Enterprise Deployment

```hcl
# Primary Region (us-east-1)
module "primary_region_waf" {
  source = "./examples/enterprise_secure_waf"
  
  providers = {
    aws = aws.primary
  }
  
  name                    = "enterprise-waf-primary"
  environment            = "prod"
  alb_arn_list           = var.primary_region_alb_arns
  
  # Primary region gets full protection
  rate_limit_strict      = 100
  rate_limit_api         = 1000
  rate_limit_web         = 5000
  
  # Centralized logging
  enable_logging           = true
  create_log_group        = true
  log_group_name          = "/aws/wafv2/enterprise-primary"
  log_group_retention_days = 365
  enable_kms_encryption   = true
  
  tags = {
    Region        = "primary"
    Environment   = "production"
    Criticality   = "critical"
  }
}

# Secondary Region (us-west-2)
module "secondary_region_waf" {
  source = "./examples/enterprise_secure_waf"
  
  providers = {
    aws = aws.secondary
  }
  
  name                    = "enterprise-waf-secondary"
  environment            = "prod"
  alb_arn_list           = var.secondary_region_alb_arns
  
  # Slightly relaxed for DR scenarios
  rate_limit_strict      = 200
  rate_limit_api         = 2000
  rate_limit_web         = 8000
  
  # Regional logging
  enable_logging           = true
  create_log_group        = true
  log_group_name          = "/aws/wafv2/enterprise-secondary"
  log_group_retention_days = 180
  enable_kms_encryption   = true
  
  tags = {
    Region        = "secondary"
    Environment   = "production"
    Purpose       = "disaster-recovery"
  }
}
```

### Pattern 4: Compliance-Focused Deployment

```hcl
module "compliance_waf" {
  source = "./examples/enterprise_secure_waf"
  
  name        = "compliance-enterprise-waf"
  environment = "prod"
  
  # Extended geographic blocking for compliance
  high_risk_countries = [
    # OFAC sanctioned countries
    "CN", "RU", "KP", "IR", "SY", "CU", "SD", "MM", "AF", "IQ",
    "LY", "SO", "YE", "VE", "BY", "NI", "ZW"
  ]
  
  # Strict rate limiting for compliance
  rate_limit_strict = 50   # Very strict for suspicious activity
  rate_limit_api    = 500  # Conservative API limits
  rate_limit_web    = 2000 # Conservative web limits
  
  # Compliance logging requirements
  enable_logging           = true
  create_log_group        = true
  log_group_retention_days = 2557  # 7 years for regulatory compliance
  enable_kms_encryption   = true
  
  # Comprehensive tagging for compliance
  tags = {
    Environment       = "production"
    Compliance        = "pci-dss-level-1"
    DataClassification = "restricted"
    RetentionPolicy   = "7-years"
    AuditRequired     = "true"
    SOXCompliance     = "true"
    HIPAACompliance   = "true"
    GDPRCompliance    = "true"
    Owner             = "compliance-team"
    ContactEmail      = "compliance@company.com"
    ReviewDate        = "2024-12-31"
    ApprovalRequired  = "true"
  }
}
```

### Pattern 5: Microservices Architecture

```hcl
# API Gateway WAF
module "api_gateway_waf" {
  source = "./examples/enterprise_secure_waf"
  
  name                = "api-gateway-waf"
  scope              = "REGIONAL"
  environment        = "prod"
  
  # API-focused rate limiting
  rate_limit_strict  = 100
  rate_limit_api     = 2000  # Higher for API traffic
  rate_limit_web     = 1000  # Lower for non-API
  
  # API-specific rules
  custom_inline_rules = [
    {
      name        = "ProtectAPIEndpoints"
      priority    = 500
      action      = "count"  # Monitor first
      metric_name = "api_endpoint_access"
      statement_config = {
        byte_match_statement = {
          search_string         = "/api/"
          positional_constraint = "CONTAINS"
          field_to_match = {
            uri_path = {}
          }
          text_transformation = {
            priority = 0
            type     = "LOWERCASE"
          }
        }
      }
    }
  ]
  
  tags = {
    Service     = "api-gateway"
    Architecture = "microservices"
    Purpose     = "api-protection"
  }
}

# Frontend Application WAF
module "frontend_waf" {
  source = "./examples/enterprise_secure_waf"
  
  name                = "frontend-app-waf"
  environment        = "prod"
  
  # Web-focused configuration
  rate_limit_web     = 10000  # Higher for web assets
  rate_limit_api     = 500    # Lower for API calls
  
  # Frontend-specific protection
  custom_inline_rules = [
    {
      name        = "ProtectStaticAssets"
      priority    = 500
      action      = "allow"
      metric_name = "static_assets"
      statement_config = {
        byte_match_statement = {
          search_string         = "/static/"
          positional_constraint = "STARTS_WITH"
          field_to_match = {
            uri_path = {}
          }
          text_transformation = {
            priority = 0
            type     = "LOWERCASE"
          }
        }
      }
    }
  ]
  
  tags = {
    Service     = "frontend"
    Architecture = "microservices"
    Purpose     = "web-protection"
  }
}
```

## 🔧 Configuration Options

### WAF Module Variables

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `name` | string | - | Name of the WAF ACL |
| `scope` | string | `"REGIONAL"` | WAF scope (REGIONAL/CLOUDFRONT) |
| `default_action` | string | `"allow"` | Default action (allow/block) |
| `alb_arn_list` | list(string) | `[]` | List of ALB ARNs to associate |
| `create_log_group` | bool | `false` | Create CloudWatch log group |
| `enable_kms_encryption` | bool | `false` | Enable KMS encryption for logs |
| `aws_managed_rule_groups` | list(object) | `[]` | AWS managed rule groups |
| `custom_inline_rules` | list(object) | `[]` | Custom inline rules |
| `rule_group_arn_list` | list(object) | `[]` | Custom rule group ARNs |

### Rule Group Module Variables

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `rule_group_name` | string | - | Name of the rule group |
| `scope` | string | `"REGIONAL"` | Rule group scope |
| `capacity` | number | `100` | WCU capacity for the rule group |
| `custom_rules` | list(object) | `[]` | List of custom rules |
| `metric_name` | string | - | CloudWatch metric name |

## 📊 Enterprise Examples

### 1. Enterprise Zero Trust WAF
- **Location**: `examples/enterprise_zero_trust_waf/`
- **Use Case**: Maximum security with zero-trust principles
- **Features**: Geographic blocking, advanced threat protection, strict rate limiting
- **Cost**: ~$15-25/month

### 2. Enterprise Secure WAF
- **Location**: `examples/enterprise_secure_waf/`
- **Use Case**: Comprehensive enterprise security with compliance features
- **Features**: Multi-layer protection, extensive logging, monitoring capabilities
- **Cost**: ~$18-28/month

### 3. Basic WAF
- **Location**: `examples/basic/`
- **Use Case**: Simple WAF setup for development or small applications
- **Features**: Basic AWS managed rules, minimal configuration
- **Cost**: ~$5-10/month

## 🔍 Monitoring and Observability

### CloudWatch Metrics

All WAF deployments automatically create CloudWatch metrics:

- `AllowedRequests`: Number of allowed requests
- `BlockedRequests`: Number of blocked requests
- `CountedRequests`: Number of counted requests
- `SampledRequests`: Sampled request details

### Log Analysis Commands

```bash
# Real-time log monitoring
aws logs tail $(terraform output -raw waf_log_group_name) --follow

# Security event analysis
aws logs filter-log-events \
  --log-group-name $(terraform output -raw waf_log_group_name) \
  --filter-pattern '{ $.action = "BLOCK" }'

# Geographic attack analysis
aws logs filter-log-events \
  --log-group-name $(terraform output -raw waf_log_group_name) \
  --filter-pattern '{ $.terminatingRuleId = "BlockHighRiskCountries" }'
```

### CloudWatch Insights Queries

```sql
-- Top attacking countries
fields @timestamp, httpRequest.country
| filter action = "BLOCK" and terminatingRuleId = "BlockHighRiskCountries"
| stats count() by httpRequest.country
| sort count desc
| limit 20

-- Hourly attack patterns
fields @timestamp, action
| filter action = "BLOCK"
| stats count() by bin(1h)
| sort @timestamp desc
```

## 🛡️ Security Best Practices

### 1. Rule Prioritization
- **1-99**: Custom high-priority rules (geographic blocking, IP whitelists)
- **100-199**: Custom rule groups (application-specific rules)
- **200-299**: Rate limiting rules
- **300-399**: AWS managed rule groups (core protection)
- **400-499**: AWS managed rule groups (specialized)
- **500+**: Custom inline rules (application-specific)

### 2. Rate Limiting Strategy
- **Strict (50-100 req/5min)**: Suspicious IPs, failed authentication
- **API (500-1000 req/5min)**: API endpoints, authenticated users
- **Web (2000-5000 req/5min)**: General web traffic, static content

### 3. Logging and Compliance
- **Production**: 365+ day retention, KMS encryption enabled
- **Compliance**: 7-year retention, comprehensive audit logging
- **Development**: 30-90 day retention, encryption optional

### 4. Cost Optimization
- **WCU Management**: Monitor capacity usage, optimize rule complexity
- **Log Filtering**: Use sampling for high-volume applications
- **Rule Efficiency**: Place most effective rules at higher priorities

## 🔄 Enterprise Deployment Workflow

### Phase 1: Planning and Design

#### 1.1 Requirements Gathering
```bash
# Create requirements document
cat > requirements.md << EOF
# WAF Requirements Document

## Business Requirements
- Application: ${APP_NAME}
- Environment: ${ENVIRONMENT}
- Compliance: ${COMPLIANCE_FRAMEWORKS}
- Expected Traffic: ${EXPECTED_RPS} requests/second
- Geographic Scope: ${ALLOWED_COUNTRIES}

## Security Requirements
- Threat Protection: SQL injection, XSS, CSRF
- Rate Limiting: API (1000/5min), Web (5000/5min)
- Geographic Blocking: ${BLOCKED_COUNTRIES}
- Logging: ${LOG_RETENTION_DAYS} days retention

## Operational Requirements
- Monitoring: CloudWatch metrics and alarms
- Alerting: SNS notifications to security team
- Backup: Terraform state in S3 with versioning
- Recovery: RTO < 1 hour, RPO < 15 minutes
EOF
```

#### 1.2 Architecture Review
```bash
# Generate architecture diagram
terraform graph | dot -Tpng > waf-architecture.png

# Security review checklist
cat > security-review.md << EOF
# WAF Security Review Checklist

## Configuration Review
- [ ] Default action is appropriate (allow/block)
- [ ] Rule priorities are correctly ordered
- [ ] Rate limiting thresholds are appropriate
- [ ] Geographic restrictions align with business needs
- [ ] Logging is enabled with appropriate retention
- [ ] KMS encryption is enabled for sensitive data

## Compliance Review
- [ ] PCI DSS requirements addressed
- [ ] SOX audit trail requirements met
- [ ] HIPAA security controls implemented
- [ ] GDPR data protection measures in place

## Operational Review
- [ ] Monitoring and alerting configured
- [ ] Incident response procedures documented
- [ ] Change management process defined
- [ ] Backup and recovery procedures tested
EOF
```

### Phase 2: Development and Testing

#### 2.1 Environment Setup
```bash
# Development environment
cd environments/dev
terraform init -backend-config="key=waf/dev/terraform.tfstate"

# Staging environment
cd ../staging
terraform init -backend-config="key=waf/staging/terraform.tfstate"

# Production environment
cd ../prod
terraform init -backend-config="key=waf/prod/terraform.tfstate"
```

#### 2.2 Configuration Validation
```bash
# Validate all environments
for env in dev staging prod; do
  echo "Validating $env environment..."
  cd environments/$env
  terraform validate
  terraform plan -var-file="$env.tfvars" -out="$env.tfplan"
  cd ../..
done

# Security scan
checkov -f environments/prod/main.tf --framework terraform
tfsec environments/prod/
```

#### 2.3 Testing Strategy
```bash
# Unit tests for Terraform modules
cd tests/
terraform test

# Integration tests
./scripts/integration-tests.sh

# Security tests
./scripts/security-tests.sh

# Performance tests
./scripts/load-tests.sh
```

### Phase 3: Deployment Pipeline

#### 3.1 CI/CD Pipeline Configuration
```yaml
# .github/workflows/waf-deployment.yml
name: WAF Deployment Pipeline

on:
  push:
    branches: [main]
    paths: ['environments/**', 'modules/**']
  pull_request:
    branches: [main]

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: hashicorp/setup-terraform@v2
      
      - name: Terraform Format Check
        run: terraform fmt -check -recursive
        
      - name: Terraform Validate
        run: |
          for env in dev staging prod; do
            cd environments/$env
            terraform init -backend=false
            terraform validate
            cd ../..
          done
          
      - name: Security Scan
        run: |
          checkov -d . --framework terraform
          tfsec .

  plan:
    needs: validate
    runs-on: ubuntu-latest
    strategy:
      matrix:
        environment: [dev, staging, prod]
    steps:
      - uses: actions/checkout@v3
      - uses: hashicorp/setup-terraform@v2
      
      - name: Configure AWS Credentials
        uses: aws-actions/configure-aws-credentials@v2
        with:
          role-to-assume: ${{ secrets.AWS_ROLE_ARN }}
          aws-region: us-east-1
          
      - name: Terraform Plan
        run: |
          cd environments/${{ matrix.environment }}
          terraform init
          terraform plan -var-file="${{ matrix.environment }}.tfvars" -out="${{ matrix.environment }}.tfplan"
          
      - name: Upload Plan
        uses: actions/upload-artifact@v3
        with:
          name: ${{ matrix.environment }}-plan
          path: environments/${{ matrix.environment }}/${{ matrix.environment }}.tfplan

  deploy-dev:
    needs: plan
    if: github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    environment: development
    steps:
      - uses: actions/checkout@v3
      - uses: hashicorp/setup-terraform@v2
      
      - name: Download Plan
        uses: actions/download-artifact@v3
        with:
          name: dev-plan
          path: environments/dev/
          
      - name: Terraform Apply
        run: |
          cd environments/dev
          terraform init
          terraform apply dev.tfplan
          
      - name: Post-Deployment Tests
        run: ./scripts/post-deployment-tests.sh dev

  deploy-staging:
    needs: [deploy-dev]
    runs-on: ubuntu-latest
    environment: staging
    steps:
      - name: Deploy to Staging
        run: |
          cd environments/staging
          terraform init
          terraform apply staging.tfplan
          
      - name: Integration Tests
        run: ./scripts/integration-tests.sh staging

  deploy-prod:
    needs: [deploy-staging]
    runs-on: ubuntu-latest
    environment: production
    steps:
      - name: Security Approval Required
        uses: trstringer/manual-approval@v1
        with:
          secret: ${{ github.TOKEN }}
          approvers: security-team,compliance-team
          
      - name: Deploy to Production
        run: |
          cd environments/prod
          terraform init
          terraform apply prod.tfplan
          
      - name: Production Verification
        run: ./scripts/production-verification.sh
```

#### 3.2 Deployment Scripts
```bash
#!/bin/bash
# scripts/deploy.sh

set -e

ENVIRONMENT=$1
APPROVE=${2:-false}

if [ -z "$ENVIRONMENT" ]; then
    echo "Usage: $0 <environment> [approve]"
    exit 1
fi

echo "Deploying WAF to $ENVIRONMENT environment..."

# Pre-deployment checks
echo "Running pre-deployment checks..."
./scripts/pre-deployment-checks.sh $ENVIRONMENT

# Initialize Terraform
cd environments/$ENVIRONMENT
terraform init

# Plan deployment
echo "Planning deployment..."
terraform plan -var-file="$ENVIRONMENT.tfvars" -out="$ENVIRONMENT.tfplan"

# Apply deployment
if [ "$APPROVE" = "true" ]; then
    echo "Applying deployment..."
    terraform apply "$ENVIRONMENT.tfplan"
else
    echo "Plan generated. Run with 'approve' parameter to apply."
    exit 0
fi

# Post-deployment verification
echo "Running post-deployment verification..."
cd ../..
./scripts/post-deployment-verification.sh $ENVIRONMENT

echo "Deployment completed successfully!"
```

### Phase 4: Monitoring and Operations

#### 4.1 Operational Monitoring
```bash
# Real-time monitoring dashboard
cat > scripts/monitoring-dashboard.sh << 'EOF'
#!/bin/bash

WAF_NAME=$1
REGION=${2:-us-east-1}

if [ -z "$WAF_NAME" ]; then
    echo "Usage: $0 <waf-name> [region]"
    exit 1
fi

echo "WAF Monitoring Dashboard for $WAF_NAME"
echo "========================================"

# Get WAF metrics
echo "Current WAF Metrics:"
aws cloudwatch get-metric-statistics \
    --namespace AWS/WAFV2 \
    --metric-name AllowedRequests \
    --dimensions Name=WebACL,Value=$WAF_NAME \
    --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
    --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
    --period 300 \
    --statistics Sum \
    --region $REGION

aws cloudwatch get-metric-statistics \
    --namespace AWS/WAFV2 \
    --metric-name BlockedRequests \
    --dimensions Name=WebACL,Value=$WAF_NAME \
    --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
    --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
    --period 300 \
    --statistics Sum \
    --region $REGION

# Check recent blocked requests
echo -e "\nRecent Blocked Requests:"
aws logs filter-log-events \
    --log-group-name "/aws/wafv2/$WAF_NAME" \
    --start-time $(date -d '1 hour ago' +%s)000 \
    --filter-pattern '{ $.action = "BLOCK" }' \
    --region $REGION \
    | jq -r '.events[] | "\(.eventTime) - \(.message | fromjson | .httpRequest.clientIp) - \(.message | fromjson | .terminatingRuleId)"'

# Check alarm status
echo -e "\nAlarm Status:"
aws cloudwatch describe-alarms \
    --alarm-names "${WAF_NAME}-blocked-requests-high" "${WAF_NAME}-rate-limit-triggered" \
    --region $REGION \
    | jq -r '.MetricAlarms[] | "\(.AlarmName): \(.StateValue)"'
EOF

chmod +x scripts/monitoring-dashboard.sh
```

#### 4.2 Incident Response Procedures
```bash
# Incident response playbook
cat > docs/incident-response-playbook.md << 'EOF'
# WAF Incident Response Playbook

## Incident Types

### 1. High Volume of Blocked Requests
**Symptoms**: CloudWatch alarm triggered for blocked requests
**Response**:
1. Check monitoring dashboard: `./scripts/monitoring-dashboard.sh <waf-name>`
2. Analyze attack patterns: `./scripts/analyze-attack-patterns.sh <waf-name>`
3. If legitimate traffic blocked: Adjust rules or add exceptions
4. If attack confirmed: Escalate to security team

### 2. WAF Performance Issues
**Symptoms**: High WCU usage, slow response times
**Response**:
1. Check WCU consumption: `aws wafv2 get-web-acl --scope REGIONAL --id <waf-id>`
2. Optimize rules: Review rule complexity and order
3. Consider rule group consolidation
4. Scale up capacity if needed

### 3. Configuration Drift
**Symptoms**: Terraform plan shows unexpected changes
**Response**:
1. Compare current state: `terraform plan`
2. Check CloudTrail for unauthorized changes
3. Restore from known good state
4. Investigate root cause

## Emergency Contacts
- Security Team: security-team@company.com
- On-Call Engineer: +1-555-ONCALL
- Compliance Team: compliance@company.com
EOF
```

#### 4.3 Maintenance and Updates
```bash
# Maintenance script
cat > scripts/maintenance.sh << 'EOF'
#!/bin/bash

set -e

ACTION=$1
ENVIRONMENT=$2

case $ACTION in
    "update-threat-intel")
        echo "Updating threat intelligence IP sets..."
        ./scripts/update-threat-intel.sh $ENVIRONMENT
        ;;
    "rotate-logs")
        echo "Rotating log groups..."
        ./scripts/rotate-logs.sh $ENVIRONMENT
        ;;
    "backup-config")
        echo "Backing up WAF configuration..."
        ./scripts/backup-config.sh $ENVIRONMENT
        ;;
    "health-check")
        echo "Running health checks..."
        ./scripts/health-check.sh $ENVIRONMENT
        ;;
    *)
        echo "Usage: $0 {update-threat-intel|rotate-logs|backup-config|health-check} <environment>"
        exit 1
        ;;
esac
EOF

chmod +x scripts/maintenance.sh
```

### Phase 5: Compliance and Auditing

#### 5.1 Compliance Reporting
```bash
# Generate compliance report
cat > scripts/compliance-report.sh << 'EOF'
#!/bin/bash

ENVIRONMENT=$1
OUTPUT_DIR="reports/$(date +%Y-%m-%d)"

mkdir -p $OUTPUT_DIR

echo "Generating compliance report for $ENVIRONMENT..."

# WAF configuration report
terraform show -json environments/$ENVIRONMENT/terraform.tfstate > $OUTPUT_DIR/waf-config.json

# Security controls report
cat > $OUTPUT_DIR/security-controls.md << EOL
# WAF Security Controls Report

## Environment: $ENVIRONMENT
## Generated: $(date)

### Geographic Controls
$(jq -r '.values.root_module.resources[] | select(.type=="aws_wafv2_web_acl") | .values.rule[] | select(.name | contains("Geographic")) | "- \(.name): \(.statement.geo_match_statement.country_codes | join(", "))"' $OUTPUT_DIR/waf-config.json)

### Rate Limiting Controls
$(jq -r '.values.root_module.resources[] | select(.type=="aws_wafv2_web_acl") | .values.rule[] | select(.name | contains("Rate")) | "- \(.name): \(.statement.rate_based_statement.limit) requests per 5 minutes"' $OUTPUT_DIR/waf-config.json)

### Logging Configuration
$(jq -r '.values.root_module.resources[] | select(.type=="aws_cloudwatch_log_group") | "- Log Group: \(.values.name)\n- Retention: \(.values.retention_in_days) days\n- Encryption: \(if .values.kms_key_id then "Enabled" else "Disabled" end)"' $OUTPUT_DIR/waf-config.json)
EOL

# Audit log analysis
aws logs filter-log-events \
    --log-group-name "/aws/wafv2/$(terraform output -raw waf_log_group_name)" \
    --start-time $(date -d '30 days ago' +%s)000 \
    --filter-pattern '{ $.action = "BLOCK" }' \
    | jq -r '.events[] | .message | fromjson | "\(.timestamp) - \(.httpRequest.clientIp) - \(.terminatingRuleId)"' \
    > $OUTPUT_DIR/blocked-requests-30days.log

echo "Compliance report generated in $OUTPUT_DIR"
EOF

chmod +x scripts/compliance-report.sh
```

#### 5.2 Audit Trail Management
```bash
# Audit trail setup
cat > audit/cloudtrail-waf.tf << 'EOF'
resource "aws_cloudtrail" "waf_audit" {
  name           = "waf-audit-trail"
  s3_bucket_name = aws_s3_bucket.audit_logs.bucket
  
  event_selector {
    read_write_type                 = "All"
    include_management_events       = true
    
    data_resource {
      type   = "AWS::WAFV2::WebACL"
      values = ["arn:aws:wafv2:*:${data.aws_caller_identity.current.account_id}:*/webacl/*"]
    }
    
    data_resource {
      type   = "AWS::WAFV2::RuleGroup"
      values = ["arn:aws:wafv2:*:${data.aws_caller_identity.current.account_id}:*/rulegroup/*"]
    }
  }
  
  tags = {
    Purpose    = "waf-audit"
    Compliance = "sox,pci-dss,hipaa"
  }
}

resource "aws_s3_bucket" "audit_logs" {
  bucket        = "waf-audit-logs-${random_id.bucket_suffix.hex}"
  force_destroy = false
  
  tags = {
    Purpose = "audit-logs"
    Retention = "7-years"
  }
}

resource "aws_s3_bucket_versioning" "audit_logs" {
  bucket = aws_s3_bucket.audit_logs.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "audit_logs" {
  bucket = aws_s3_bucket.audit_logs.id
  
  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.audit_logs.arn
      sse_algorithm     = "aws:kms"
    }
  }
}
EOF
```

## 🏛️ Enterprise Governance and Operations

### Enterprise Architecture Principles

#### 1. Security by Design
```hcl
# Example: Defense in Depth Strategy
module "enterprise_waf_stack" {
  source = "./examples/enterprise_secure_waf"
  
  # Layer 1: Geographic Controls
  high_risk_countries = var.blocked_countries
  
  # Layer 2: Rate Limiting
  rate_limit_strict = 100
  rate_limit_api    = 1000
  rate_limit_web    = 5000
  
  # Layer 3: Application Security
  aws_managed_rule_groups = [
    # Core protection
    { name = "AWSManagedRulesCommonRuleSet", vendor_name = "AWS", priority = 300, override_action = "none" },
    # SQL injection protection
    { name = "AWSManagedRulesSQLiRuleSet", vendor_name = "AWS", priority = 301, override_action = "none" },
    # Known bad inputs
    { name = "AWSManagedRulesKnownBadInputsRuleSet", vendor_name = "AWS", priority = 302, override_action = "none" },
    # IP reputation
    { name = "AWSManagedRulesAmazonIpReputationList", vendor_name = "AWS", priority = 305, override_action = "none" }
  ]
  
  # Layer 4: Monitoring and Compliance
  enable_logging           = true
  log_group_retention_days = 365
  enable_kms_encryption   = true
}
```

#### 2. Infrastructure as Code Standards
```hcl
# Standard enterprise tagging
locals {
  enterprise_tags = {
    # Governance
    Environment     = var.environment
    Application     = var.application_name
    Owner           = var.owner_team
    CostCenter      = var.cost_center
    
    # Security
    SecurityLevel   = var.security_classification
    DataClass       = var.data_classification
    Compliance      = join(",", var.compliance_frameworks)
    
    # Operations
    BackupRequired  = var.backup_required
    MonitoringLevel = var.monitoring_level
    SupportTier     = var.support_tier
    
    # Lifecycle
    CreatedBy       = var.created_by
    CreatedDate     = formatdate("YYYY-MM-DD", timestamp())
    ReviewDate      = var.next_review_date
    
    # Automation
    TerraformManaged = "true"
    ModuleVersion    = var.module_version
  }
}

module "enterprise_waf" {
  source = "./examples/enterprise_secure_waf"
  
  name = "${var.application_name}-${var.environment}-waf"
  tags = local.enterprise_tags
}
```

#### 3. Multi-Environment Strategy
```hcl
# environments/prod/main.tf
module "prod_waf" {
  source = "../../examples/enterprise_secure_waf"
  
  name                    = "prod-${var.app_name}-waf"
  environment            = "prod"
  
  # Production security settings
  rate_limit_strict      = 100
  high_risk_countries    = var.prod_blocked_countries
  enable_logging         = true
  log_group_retention_days = 365
  enable_kms_encryption  = true
  
  # Production compliance
  tags = merge(local.base_tags, {
    Environment     = "production"
    Criticality     = "high"
    Compliance      = "pci-dss,sox,hipaa"
    BackupRequired  = "true"
    MonitoringLevel = "comprehensive"
  })
}

# environments/staging/main.tf
module "staging_waf" {
  source = "../../examples/enterprise_secure_waf"
  
  name                    = "staging-${var.app_name}-waf"
  environment            = "staging"
  
  # Staging settings (more permissive for testing)
  rate_limit_strict      = 500
  high_risk_countries    = slice(var.prod_blocked_countries, 0, 5)  # Subset for testing
  enable_logging         = true
  log_group_retention_days = 90
  enable_kms_encryption  = false
  
  tags = merge(local.base_tags, {
    Environment     = "staging"
    Criticality     = "medium"
    Purpose         = "testing"
    MonitoringLevel = "standard"
  })
}
```

### Enterprise Security Governance

#### 1. Security Control Framework
```hcl
# security-controls/waf-baseline.tf
module "security_baseline_rules" {
  source = "./modules/waf-rule-group"
  
  rule_group_name = "enterprise-security-baseline"
  name            = "security-baseline"
  scope           = "REGIONAL"
  capacity        = 500
  
  custom_rules = [
    # SC-1: Geographic Access Control
    {
      name        = "EnforceGeographicPolicy"
      priority    = 10
      action      = "block"
      metric_name = "geographic_policy_violation"
      statement_config = {
        geo_match_statement = {
          country_codes = var.prohibited_countries
        }
      }
    },
    
    # SC-2: Corporate Network Access
    {
      name        = "AllowCorporateNetworks"
      priority    = 20
      action      = "allow"
      metric_name = "corporate_network_access"
      statement_config = {
        ip_set_reference_statement = {
          arn = aws_wafv2_ip_set.corporate_networks.arn
        }
      }
    },
    
    # SC-3: Threat Intelligence Integration
    {
      name        = "BlockThreatIntelligence"
      priority    = 30
      action      = "block"
      metric_name = "threat_intel_block"
      statement_config = {
        ip_set_reference_statement = {
          arn = aws_wafv2_ip_set.threat_intelligence.arn
        }
      }
    }
  ]
  
  tags = {
    SecurityControl = "baseline"
    Framework       = "enterprise-security-framework"
    Version         = "1.0"
    ApprovedBy      = "security-committee"
  }
}
```

#### 2. Compliance Automation
```hcl
# compliance/pci-dss.tf
module "pci_dss_waf" {
  source = "./examples/enterprise_secure_waf"
  
  name = "pci-dss-compliant-waf"
  
  # PCI DSS Requirement 6.5.1: Injection flaws
  aws_managed_rule_groups = [
    { name = "AWSManagedRulesSQLiRuleSet", vendor_name = "AWS", priority = 300, override_action = "none" }
  ]
  
  # PCI DSS Requirement 6.5.7: Cross-site scripting (XSS)
  custom_inline_rules = [
    {
      name        = "PCIDSSXSSProtection"
      priority    = 500
      action      = "block"
      metric_name = "pci_dss_xss_protection"
      statement_config = {
        xss_match_statement = {
          field_to_match = {
            all_query_arguments = {}
          }
          text_transformation = {
            priority = 1
            type     = "HTML_ENTITY_DECODE"
          }
        }
      }
    }
  ]
  
  # PCI DSS Requirement 10: Logging
  enable_logging           = true
  log_group_retention_days = 365  # Minimum 1 year retention
  enable_kms_encryption   = true  # Encrypt sensitive log data
  
  tags = {
    Compliance    = "pci-dss"
    Requirement   = "6.5.1,6.5.7,10.1"
    AuditRequired = "true"
    ReviewCycle   = "quarterly"
  }
}
```

### Operational Excellence

#### 1. Monitoring and Alerting
```hcl
# monitoring/cloudwatch-alarms.tf
resource "aws_cloudwatch_metric_alarm" "waf_blocked_requests_high" {
  alarm_name          = "${var.waf_name}-blocked-requests-high"
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
    WebACL = module.enterprise_waf.web_acl_id
  }

  tags = {
    AlertType   = "security"
    Severity    = "high"
    Runbook     = "https://wiki.company.com/waf-incident-response"
  }
}

resource "aws_cloudwatch_metric_alarm" "waf_rate_limit_triggered" {
  alarm_name          = "${var.waf_name}-rate-limit-triggered"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "BlockedRequests"
  namespace           = "AWS/WAFV2"
  period              = "60"
  statistic           = "Sum"
  threshold           = "100"
  alarm_description   = "Rate limiting actively blocking requests"
  alarm_actions       = [aws_sns_topic.security_alerts.arn]

  dimensions = {
    WebACL = module.enterprise_waf.web_acl_id
    Rule   = "StrictRateLimit"
  }
}
```

#### 2. Automated Security Response
```hcl
# security-automation/lambda-response.tf
resource "aws_lambda_function" "waf_security_response" {
  filename         = "waf-security-response.zip"
  function_name    = "waf-security-response"
  role            = aws_iam_role.lambda_security_response.arn
  handler         = "index.handler"
  runtime         = "python3.9"
  timeout         = 300

  environment {
    variables = {
      WAF_ACL_ID = module.enterprise_waf.web_acl_id
      SNS_TOPIC  = aws_sns_topic.security_alerts.arn
    }
  }

  tags = {
    Purpose = "security-automation"
    Type    = "incident-response"
  }
}

# CloudWatch Event Rule for automated response
resource "aws_cloudwatch_event_rule" "waf_security_event" {
  name        = "waf-security-event"
  description = "Trigger security response for WAF events"

  event_pattern = jsonencode({
    source      = ["aws.wafv2"]
    detail-type = ["AWS WAF Rule Match"]
    detail = {
      action = ["BLOCK"]
    }
  })
}

resource "aws_cloudwatch_event_target" "lambda_target" {
  rule      = aws_cloudwatch_event_rule.waf_security_event.name
  target_id = "TriggerSecurityResponse"
  arn       = aws_lambda_function.waf_security_response.arn
}
```

#### 3. Cost Management and Optimization
```hcl
# cost-management/waf-cost-optimization.tf
resource "aws_cloudwatch_metric_alarm" "waf_wcu_usage_high" {
  alarm_name          = "${var.waf_name}-wcu-usage-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "3"
  metric_name         = "ConsumedCapacity"
  namespace           = "AWS/WAFV2"
  period              = "300"
  statistic           = "Average"
  threshold           = "1000"  # Adjust based on your capacity
  alarm_description   = "WAF WCU usage is high - consider optimization"
  alarm_actions       = [aws_sns_topic.cost_alerts.arn]

  dimensions = {
    WebACL = module.enterprise_waf.web_acl_id
  }

  tags = {
    AlertType = "cost-optimization"
    Action    = "review-rules"
  }
}

# Cost allocation tags
locals {
  cost_allocation_tags = {
    CostCenter      = var.cost_center
    Project         = var.project_name
    Environment     = var.environment
    Service         = "waf"
    BillingContact  = var.billing_contact
  }
}
```

## 📋 Compliance and Governance

### Supported Compliance Frameworks

#### PCI DSS (Payment Card Industry Data Security Standard)
```hcl
module "pci_dss_waf" {
  source = "./examples/enterprise_secure_waf"
  
  # PCI DSS Requirements
  enable_logging           = true
  log_group_retention_days = 365  # Req 10.7: Retain audit logs for at least one year
  enable_kms_encryption   = true  # Req 3.4: Encrypt sensitive data
  
  # PCI DSS 6.5.1: Injection flaws (SQL injection)
  aws_managed_rule_groups = [
    { name = "AWSManagedRulesSQLiRuleSet", vendor_name = "AWS", priority = 300, override_action = "none" }
  ]
  
  tags = {
    Compliance = "pci-dss"
    Level      = "level-1"
    QSA        = "qualified-security-assessor-name"
  }
}
```

#### SOX (Sarbanes-Oxley Act)
```hcl
module "sox_compliant_waf" {
  source = "./examples/enterprise_secure_waf"
  
  # SOX Requirements
  enable_logging           = true
  log_group_retention_days = 2557  # 7 years retention for financial records
  enable_kms_encryption   = true
  
  # Comprehensive audit trail
  custom_inline_rules = [
    {
      name        = "AuditFinancialTransactions"
      priority    = 500
      action      = "count"  # Log all financial API access
      metric_name = "financial_api_access"
      statement_config = {
        byte_match_statement = {
          search_string         = "/api/financial"
          positional_constraint = "STARTS_WITH"
          field_to_match = { uri_path = {} }
          text_transformation = { priority = 0, type = "LOWERCASE" }
        }
      }
    }
  ]
  
  tags = {
    Compliance    = "sox"
    Section       = "404"
    AuditRequired = "true"
    CFO_Approved  = "true"
  }
}
```

#### HIPAA (Health Insurance Portability and Accountability Act)
```hcl
module "hipaa_waf" {
  source = "./examples/enterprise_secure_waf"
  
  # HIPAA Security Rule requirements
  enable_logging           = true
  log_group_retention_days = 2190  # 6 years for healthcare records
  enable_kms_encryption   = true
  
  # Enhanced geographic restrictions for PHI protection
  high_risk_countries = [
    "CN", "RU", "KP", "IR", "SY", "CU", "SD", "MM", "AF", "IQ",
    "LY", "SO", "YE", "VE", "BY", "NI", "ZW"
  ]
  
  # Strict rate limiting for PHI endpoints
  rate_limit_strict = 50
  rate_limit_api    = 200
  
  tags = {
    Compliance     = "hipaa"
    PHI_Protected  = "true"
    BAA_Required   = "true"
    Privacy_Officer = "privacy-officer@company.com"
  }
}
```

#### GDPR (General Data Protection Regulation)
```hcl
module "gdpr_waf" {
  source = "./examples/enterprise_secure_waf"
  
  # GDPR Article 32: Security of processing
  enable_logging           = true
  log_group_retention_days = 2557  # 7 years for legal compliance
  enable_kms_encryption   = true
  
  # EU-specific geographic controls
  custom_inline_rules = [
    {
      name        = "LogEUDataAccess"
      priority    = 500
      action      = "count"
      metric_name = "eu_data_access"
      statement_config = {
        geo_match_statement = {
          country_codes = ["AT", "BE", "BG", "HR", "CY", "CZ", "DK", "EE", "FI", "FR", "DE", "GR", "HU", "IE", "IT", "LV", "LT", "LU", "MT", "NL", "PL", "PT", "RO", "SK", "SI", "ES", "SE"]
        }
      }
    }
  ]
  
  tags = {
    Compliance = "gdpr"
    DPO        = "data-protection-officer@company.com"
    LegalBasis = "legitimate-interest"
  }
}
```

### Governance Features

#### 1. Enterprise Tagging Strategy
```hcl
# governance/tagging-strategy.tf
locals {
  mandatory_tags = {
    # Business
    Environment     = var.environment
    Application     = var.application_name
    Owner           = var.owner_team
    CostCenter      = var.cost_center
    Project         = var.project_name
    
    # Security
    SecurityLevel   = var.security_classification  # public, internal, confidential, restricted
    DataClass       = var.data_classification      # public, internal, sensitive, restricted
    Compliance      = join(",", var.compliance_frameworks)
    
    # Operations
    BackupRequired  = var.backup_required
    MonitoringLevel = var.monitoring_level         # basic, standard, comprehensive
    SupportTier     = var.support_tier            # bronze, silver, gold, platinum
    
    # Governance
    CreatedBy       = var.created_by
    CreatedDate     = formatdate("YYYY-MM-DD", timestamp())
    ReviewDate      = var.next_review_date
    ApprovalRequired = var.approval_required
    
    # Automation
    TerraformManaged = "true"
    ModuleVersion    = var.module_version
    LastModified     = formatdate("YYYY-MM-DD", timestamp())
  }
  
  optional_tags = var.additional_tags
  
  all_tags = merge(local.mandatory_tags, local.optional_tags)
}
```

#### 2. Access Controls and RBAC
```hcl
# iam/waf-deployment-roles.tf
# WAF Deployment Role (for CI/CD)
resource "aws_iam_role" "waf_deployment" {
  name = "WAFDeploymentRole"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${var.cicd_account_id}:root"
        }
        Condition = {
          StringEquals = {
            "sts:ExternalId" = var.external_id
          }
        }
      }
    ]
  })
}

# WAF Management Policy
resource "aws_iam_policy" "waf_management" {
  name = "WAFManagementPolicy"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "wafv2:*",
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams",
          "kms:CreateKey",
          "kms:DescribeKey",
          "kms:GetKeyPolicy",
          "kms:PutKeyPolicy"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "elasticloadbalancing:DescribeLoadBalancers"
        ]
        Resource = "*"
      }
    ]
  })
}

# WAF Read-Only Role (for monitoring/auditing)
resource "aws_iam_role" "waf_readonly" {
  name = "WAFReadOnlyRole"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          AWS = [
            "arn:aws:iam::${var.account_id}:role/SecurityAuditRole",
            "arn:aws:iam::${var.account_id}:role/ComplianceAuditRole"
          ]
        }
      }
    ]
  })
}
```

#### 3. Change Management and Approval Workflows
```hcl
# governance/change-management.tf
resource "aws_sns_topic" "waf_changes" {
  name = "waf-change-notifications"
  
  tags = {
    Purpose = "change-management"
    Team    = "security"
  }
}

resource "aws_sns_topic_subscription" "security_team" {
  topic_arn = aws_sns_topic.waf_changes.arn
  protocol  = "email"
  endpoint  = "security-team@company.com"
}

resource "aws_sns_topic_subscription" "compliance_team" {
  topic_arn = aws_sns_topic.waf_changes.arn
  protocol  = "email"
  endpoint  = "compliance-team@company.com"
}

# CloudTrail for WAF change auditing
resource "aws_cloudtrail" "waf_audit" {
  name           = "waf-audit-trail"
  s3_bucket_name = aws_s3_bucket.audit_logs.bucket
  
  event_selector {
    read_write_type                 = "All"
    include_management_events       = true
    data_resource {
      type   = "AWS::WAFV2::WebACL"
      values = ["arn:aws:wafv2:*:${var.account_id}:*/webacl/*"]
    }
    data_resource {
      type   = "AWS::WAFV2::RuleGroup"
      values = ["arn:aws:wafv2:*:${var.account_id}:*/rulegroup/*"]
    }
  }
  
  tags = {
    Purpose    = "audit"
    Compliance = "sox,pci-dss"
  }
}
```

## 🆘 Troubleshooting

### Common Issues

#### 1. WCU Capacity Exceeded
```bash
# Check current WCU usage
aws wafv2 get-web-acl --scope REGIONAL --id your-waf-id

# Solution: Optimize rules or increase capacity
```

#### 2. Rule Priority Conflicts
```bash
# Validate priorities
terraform plan

# Solution: Ensure unique priorities across all rules
```

#### 3. Logging Not Working
```bash
# Check log group permissions
aws logs describe-log-groups --log-group-name-prefix /aws/wafv2/

# Solution: Verify IAM permissions and log group configuration
```

### Support Resources
- **Documentation**: `/docs` directory
- **Examples**: `/examples` directory with working configurations
- **Issues**: GitHub issues for bug reports and feature requests

## 🤝 Contributing

1. **Fork** the repository
2. **Create** a feature branch
3. **Test** your changes thoroughly
4. **Submit** a pull request with detailed description

### Development Guidelines
- Follow Terraform best practices
- Include comprehensive documentation
- Add examples for new features
- Ensure backward compatibility

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🏷️ Version History

- **v1.0.0**: Initial enterprise release
- **v1.1.0**: Added zero-trust configuration
- **v1.2.0**: Enhanced rule group support
- **v1.3.0**: Comprehensive logging and monitoring

## 📞 Enterprise Support and Resources

### Support Tiers

#### Tier 1: Community Support
- **GitHub Issues**: Bug reports and feature requests
- **Documentation**: Comprehensive guides and examples
- **Community Forums**: Stack Overflow, Reddit, Discord
- **Response Time**: Best effort, community-driven

#### Tier 2: Professional Support
- **Email Support**: Direct access to module maintainers
- **Priority Issues**: Faster response for production issues
- **Custom Configurations**: Assistance with complex deployments
- **Response Time**: 24-48 hours for critical issues

#### Tier 3: Enterprise Support
- **Dedicated Support**: Named support engineer
- **24/7 Support**: Round-the-clock assistance
- **Custom Development**: Tailored features and integrations
- **Training**: On-site or virtual training sessions
- **Response Time**: 4 hours for critical, 24 hours for standard

### Professional Services

#### Security Assessment
- **WAF Configuration Review**: Expert analysis of your WAF setup
- **Threat Modeling**: Identify potential attack vectors
- **Compliance Gap Analysis**: Ensure regulatory compliance
- **Performance Optimization**: Optimize rules for cost and performance

#### Implementation Services
- **Custom Rule Development**: Tailored security rules for your applications
- **Multi-Environment Setup**: Standardized deployment across environments
- **Integration Services**: Connect with existing security tools
- **Migration Services**: Migrate from existing WAF solutions

#### Training and Enablement
- **WAF Best Practices Workshop**: 2-day intensive training
- **Terraform for Security Teams**: Infrastructure as Code training
- **Incident Response Training**: WAF-specific incident handling
- **Compliance Training**: Regulatory requirements and implementation

### Enterprise Resources

#### Documentation
- **Architecture Guides**: `/docs/architecture/`
- **Security Playbooks**: `/docs/security/`
- **Compliance Guides**: `/docs/compliance/`
- **Troubleshooting**: `/docs/troubleshooting/`
- **API Reference**: `/docs/api/`

#### Tools and Utilities
- **WAF Analyzer**: Analyze WAF logs and performance
- **Rule Optimizer**: Optimize rule order and complexity
- **Compliance Scanner**: Automated compliance checking
- **Cost Calculator**: Estimate WAF costs and optimization opportunities

#### Integration Partners
- **SIEM Integration**: Splunk, QRadar, ArcSight
- **Monitoring Tools**: Datadog, New Relic, Dynatrace
- **Security Tools**: CrowdStrike, Palo Alto, Fortinet
- **Compliance Tools**: Rapid7, Qualys, Tenable

### Contact Information

#### General Inquiries
- **Email**: waf-support@company.com
- **Phone**: +1-800-WAF-HELP
- **Website**: https://waf-modules.company.com

#### Emergency Support (Tier 3 Only)
- **24/7 Hotline**: +1-800-EMERGENCY
- **Slack Channel**: #waf-emergency-support
- **PagerDuty**: waf-emergency@company.pagerduty.com

#### Regional Support
- **Americas**: americas-support@company.com
- **EMEA**: emea-support@company.com
- **APAC**: apac-support@company.com

### Service Level Agreements (SLA)

#### Response Times
| Severity | Tier 1 | Tier 2 | Tier 3 |
|----------|--------|--------|--------|
| Critical | Best Effort | 24 hours | 4 hours |
| High | Best Effort | 48 hours | 8 hours |
| Medium | Best Effort | 5 days | 24 hours |
| Low | Best Effort | 10 days | 48 hours |

#### Resolution Times
| Severity | Description | Target Resolution |
|----------|-------------|-------------------|
| Critical | Production down, security breach | 24 hours |
| High | Major functionality impacted | 72 hours |
| Medium | Minor functionality impacted | 1 week |
| Low | Enhancement requests | 1 month |

### Enterprise Licensing

#### Open Source License
- **License**: MIT License
- **Usage**: Unlimited commercial and non-commercial use
- **Support**: Community support only
- **Warranty**: No warranty provided

#### Commercial License
- **License**: Commercial license with support
- **Usage**: Enterprise use with professional support
- **Support**: Professional or Enterprise tier support
- **Warranty**: Limited warranty and indemnification

#### Enterprise License
- **License**: Enterprise license with full support
- **Usage**: Large-scale enterprise deployments
- **Support**: Dedicated support team
- **Warranty**: Full warranty and indemnification
- **Extras**: Custom development, training, consulting

### Feedback and Contributions

#### How to Contribute
1. **Fork** the repository on GitHub
2. **Create** a feature branch (`git checkout -b feature/amazing-feature`)
3. **Commit** your changes (`git commit -m 'Add amazing feature'`)
4. **Push** to the branch (`git push origin feature/amazing-feature`)
5. **Open** a Pull Request

#### Contribution Guidelines
- Follow Terraform best practices and style guide
- Include comprehensive tests for new features
- Update documentation for any changes
- Ensure backward compatibility
- Sign the Contributor License Agreement (CLA)

#### Recognition Program
- **Contributor of the Month**: Recognition and swag
- **Annual Contributors**: Special recognition at conferences
- **Enterprise Contributors**: Invitation to advisory board

---

## 🏆 Success Stories

### Fortune 500 Financial Services Company
*"The enterprise WAF modules helped us achieve PCI DSS Level 1 compliance while reducing our security operations overhead by 60%. The comprehensive logging and monitoring capabilities have been game-changing for our SOC team."*

**Results:**
- 99.9% uptime maintained during implementation
- 40% reduction in false positives
- $2M annual savings in security operations costs
- PCI DSS Level 1 compliance achieved in 3 months

### Global Healthcare Provider
*"HIPAA compliance was our biggest challenge. These modules provided the security controls and audit capabilities we needed while maintaining the performance our applications require."*

**Results:**
- HIPAA compliance achieved across 15 applications
- 50% improvement in threat detection
- Zero security incidents post-implementation
- 30% reduction in compliance audit time

### E-commerce Platform
*"Scaling our WAF across multiple regions and environments was seamless with these modules. The cost optimization features alone saved us $500K annually."*

**Results:**
- Deployed across 5 AWS regions
- 25% reduction in WAF costs through optimization
- 99.99% availability during Black Friday traffic
- 80% faster deployment of new security rules

---

**🚀 Ready to Get Started?**

Choose your deployment path:
- **Quick Start**: Use our basic example for simple deployments
- **Enterprise Zero Trust**: Maximum security with zero-trust principles  
- **Compliance-Ready**: Built-in compliance for regulated industries
- **Custom Solution**: Work with our team for tailored implementations

**📧 Contact Us**: For enterprise support, custom configurations, or professional services, contact enterprise-support@company.com or visit our [Enterprise Portal](https://enterprise.waf-modules.company.com).