# GitLab Remote Module Project - Comprehensive Enterprise WAF

This example demonstrates a complete enterprise-grade Web Application Firewall (WAF) solution using **all available modules** from a GitLab remote repository. It showcases advanced module composition, cross-module integration, and real-world security use cases.

## 🏗️ Architecture Overview

This comprehensive example creates a multi-layered security architecture using all 6 available WAF modules:

```
┌─────────────────────────────────────────────────────────────────┐
│                    ENTERPRISE WAF ARCHITECTURE                  │
├─────────────────────────────────────────────────────────────────┤
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐ │
│  │   IP Sets       │  │ Regex Patterns  │  │  Rule Groups    │ │
│  │                 │  │                 │  │                 │ │
│  │ • Malicious IPs │  │ • SQL Injection │  │ • Security      │ │
│  │ • Trusted IPs   │  │ • Bot Detection │  │ • Rate Limiting │ │
│  │                 │  │                 │  │ • App Specific  │ │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘ │
│           │                     │                     │         │
│           └─────────────────────┼─────────────────────┘         │
│                                 │                               │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │                    MAIN WAF (Web ACL)                      │ │
│  │                                                             │ │
│  │ • Custom Rule Groups Integration                            │ │
│  │ • AWS Managed Rules (OWASP, SQLi, Linux, Bad Inputs)      │ │
│  │ • Inline Rules (Health Checks, Admin Protection)          │ │
│  │ • Comprehensive Logging                                    │ │
│  └─────────────────────────────────────────────────────────────┘ │
│                                 │                               │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │              S3 CROSS-ACCOUNT REPLICATION                  │ │
│  │                                                             │ │
│  │ • WAF Log Management                                        │ │
│  │ • Cross-Region Backup                                      │ │
│  │ • Compliance & Audit Trail                                 │ │
│  └─────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

## 📦 Modules Demonstrated

### 1. **IP Set Module** (`modules/ip-set`)
- **Purpose**: IP address management for security policies
- **Use Cases**:
  - **Malicious IP Set**: Blocks known bad actors, bot networks, suspicious ranges
  - **Trusted IP Set**: Allows corporate networks, VPN gateways, admin access IPs
- **GitLab Source**: `${gitlab_repo_url}//modules/ip-set?ref=${module_version}`

### 2. **Regex Pattern Set Module** (`modules/regex-pattern-set`)
- **Purpose**: Advanced pattern matching for threat detection
- **Use Cases**:
  - **SQL Injection Patterns**: Detects various SQL injection techniques
  - **Bot Detection Patterns**: Identifies automated traffic and scrapers
- **GitLab Source**: `${gitlab_repo_url}//modules/regex-pattern-set?ref=${module_version}`

### 3. **WAF Rule Group Module** (`modules/waf-rule-group`)
- **Purpose**: Custom security rules with cross-module integration
- **Use Cases**:
  - **Security Rule Group**: Integrates IP sets and regex patterns for comprehensive protection
  - **Rate Limiting Group**: API and general traffic rate limiting
- **GitLab Source**: `${gitlab_repo_url}//modules/waf-rule-group?ref=${module_version}`

### 4. **Main WAF Module** (`modules/waf`)
- **Purpose**: Central Web Application Firewall orchestration
- **Features**:
  - Integrates all custom rule groups
  - AWS managed rule sets
  - Custom inline rules
  - Comprehensive logging with KMS encryption
- **GitLab Source**: `${gitlab_repo_url}//modules/waf?ref=${module_version}`

### 5. **S3 Cross-Account Replication Module** (`modules/s3-cross-account-replication`)
- **Purpose**: WAF log management and compliance
- **Features**:
  - Cross-region log replication
  - Cross-account backup
  - Compliance and audit trail
- **GitLab Source**: `${gitlab_repo_url}//modules/s3-cross-account-replication?ref=${module_version}`

### 6. **Rule Group Module** (`modules/rule-group`)
- **Purpose**: Specialized application-specific rules
- **Use Cases**:
  - API endpoint protection
  - Authentication validation
  - Application-specific security policies
- **GitLab Source**: `${gitlab_repo_url}//modules/rule-group?ref=${module_version}`

## 🛡️ Security Use Cases Implemented

### Layer 1: Network-Level Protection
- **Malicious IP Blocking**: 5 IP ranges/addresses blocked
- **Trusted IP Allowlisting**: 4 corporate/admin IP ranges allowed
- **Geographic Restrictions**: Blocks traffic from CN, RU, KP, IR

### Layer 2: Application-Level Protection
- **SQL Injection Detection**: 12 advanced regex patterns
- **Bot/Scraper Detection**: 9 automated traffic patterns
- **XSS Protection**: Script injection prevention

### Layer 3: Rate Limiting
- **API Rate Limiting**: 2,000 requests per 5 minutes for `/api/` endpoints
- **General Rate Limiting**: 10,000 requests per 5 minutes per IP

### Layer 4: Application-Specific Rules
- **Admin Panel Protection**: Restricts `/admin` access to trusted IPs only
- **API Authentication**: Blocks `/api/v1/sensitive` without Bearer token
- **Health Check Allowlisting**: Always allows `/health` endpoint

### Layer 5: AWS Managed Protection
- **OWASP Top 10**: Common web vulnerabilities
- **Known Bad Inputs**: AWS threat intelligence
- **SQL Injection**: AWS-managed SQLi protection
- **Linux-Specific**: Linux system attack patterns

### Layer 6: Logging & Compliance
- **Comprehensive Logging**: All WAF events logged to CloudWatch
- **Cross-Region Backup**: Logs replicated to us-west-2
- **KMS Encryption**: Logs encrypted at rest
- **90-Day Retention**: Compliance-ready log retention

## 🚀 Quick Start

### Prerequisites
- AWS CLI configured with appropriate permissions
- Terraform >= 1.3.0
- Access to GitLab repository with WAF modules
- SSH key configured for GitLab access

### Deployment Steps

1. **Clone and Navigate**
   ```bash
   git clone <your-repo>
   cd waf-module-v1/examples/gitlab_remote_module_project
   ```

2. **Configure Variables**
   ```bash
   # Edit terraform.tfvars
   vim terraform.tfvars
   
   # Update these key variables:
   # - gitlab_repo_url: Your GitLab repository URL
   # - module_version: Your module version/tag
   # - aws_region: Your target AWS region
   # - project_name: Your project identifier
   ```

3. **Initialize and Deploy**
   ```bash
   terraform init
   terraform validate
   terraform plan
   terraform apply
   ```

4. **Verify Deployment**
   ```bash
   # Check outputs
   terraform output
   
   # Verify WAF in AWS Console
   aws wafv2 list-web-acls --scope=REGIONAL --region=us-east-1
   ```

## 📋 Configuration Variables

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `aws_region` | AWS region for deployment | `us-east-1` | No |
| `environment` | Environment name | `production` | No |
| `project_name` | Project name for resources | `enterprise-waf-demo` | No |
| `gitlab_repo_url` | GitLab repository URL | `git::ssh://git@gitlab.com/yourgroup/infrastructure/terraform-waf.git` | Yes |
| `module_version` | Module version/branch | `v1.0.0` | No |

## 📊 Resource Summary

### Created Resources
- **2 IP Sets**: Malicious and trusted IP management
- **2 Regex Pattern Sets**: SQL injection and bot detection
- **3 WAF Rule Groups**: Security, rate limiting, and app-specific rules
- **1 Main WAF**: Central firewall with 11 total rule integrations
- **1 S3 Replication**: Cross-account log management
- **CloudWatch Log Groups**: Comprehensive logging infrastructure
- **KMS Keys**: Encryption for logs and replication

### Total Rule Coverage
- **5 Custom Security Rules**: IP-based and pattern-based protection
- **2 Rate Limiting Rules**: API and general traffic control
- **1 Application Rule**: Endpoint-specific protection
- **4 AWS Managed Rule Sets**: Industry-standard protections
- **2 Inline Rules**: Health checks and admin protection

## 🔧 Advanced Configuration

### Custom IP Ranges
Edit the IP sets in `main.tf` to match your environment:

```hcl
# Malicious IPs - Add your known bad actors
addresses = [
  "192.0.2.0/24",      # Example malicious network
  "198.51.100.0/24",   # Known bot network
  "203.0.113.0/24",    # Suspicious IP range
  # Add your specific threats here
]

# Trusted IPs - Add your corporate networks
addresses = [
  "203.0.113.100/32",  # Office IP
  "198.51.100.50/32",  # VPN gateway
  # Add your trusted networks here
]
```

### Custom Regex Patterns
Extend the regex patterns for your specific threats:

```hcl
regex_strings = [
  "(?i)select.*from",     # SQL SELECT statements
  "(?i)union.*select",    # UNION-based injections
  # Add your custom patterns here
]
```

### Rate Limiting Adjustment
Modify rate limits based on your traffic patterns:

```hcl
# API rate limiting
limit = 2000  # Requests per 5 minutes

# General rate limiting  
limit = 10000 # Requests per 5 minutes
```

## 🔍 Monitoring & Observability

### CloudWatch Metrics
Monitor these key metrics:
- `AWS/WAFV2/BlockedRequests`: Blocked request count
- `AWS/WAFV2/AllowedRequests`: Allowed request count
- `AWS/WAFV2/SampledRequests`: Sample of requests for analysis

### Log Analysis
WAF logs are available in:
- **Primary**: CloudWatch Logs in deployment region
- **Backup**: S3 bucket with cross-region replication
- **Format**: JSON with detailed request information

### Alerting Setup
Consider setting up CloudWatch alarms for:
- High blocked request rates (potential attack)
- Rate limiting triggers (traffic spikes)
- Geographic blocking events (unusual traffic sources)

## 🔒 Security Best Practices

### GitLab Repository Security
- Use private repositories for WAF configurations
- Implement branch protection rules
- Require code reviews for changes
- Use deploy keys for CI/CD access

### Module Version Management
- Pin specific module versions in production
- Test new versions in staging first
- Use semantic versioning for releases
- Maintain changelog for module updates

### Access Control
- Limit WAF modification permissions
- Use IAM roles for Terraform execution
- Enable CloudTrail for audit logging
- Implement least-privilege access

## 🚨 Troubleshooting

### Common Issues

1. **GitLab Access Denied**
   ```bash
   # Verify SSH key access
   ssh -T git@gitlab.com
   
   # Check repository permissions
   git clone ${gitlab_repo_url}
   ```

2. **Module Not Found**
   ```bash
   # Verify module path and version
   terraform init -upgrade
   
   # Check GitLab repository structure
   ```

3. **Rate Limiting Too Aggressive**
   ```bash
   # Adjust rate limits in terraform.tfvars
   # Redeploy with terraform apply
   ```

4. **False Positives**
   ```bash
   # Review CloudWatch logs
   # Adjust regex patterns or IP sets
   # Test with terraform plan
   ```

## 📈 Performance Considerations

### WAF Capacity Units (WCUs)
- **Security Rule Group**: 300 WCUs
- **Rate Limiting Group**: 200 WCUs  
- **App-Specific Group**: 150 WCUs
- **Total Custom**: 650 WCUs
- **AWS Managed**: ~400 WCUs
- **Total Estimated**: ~1,050 WCUs

### Cost Optimization
- Monitor WCU usage with CloudWatch
- Optimize rule order for efficiency
- Use appropriate AWS managed rules
- Consider regional deployment strategy

## 🔄 CI/CD Integration

### GitLab CI Pipeline Example
```yaml
stages:
  - validate
  - plan
  - apply

terraform-validate:
  stage: validate
  script:
    - terraform init
    - terraform validate
    - terraform fmt -check

terraform-plan:
  stage: plan
  script:
    - terraform plan -out=tfplan
  artifacts:
    paths:
      - tfplan

terraform-apply:
  stage: apply
  script:
    - terraform apply tfplan
  when: manual
  only:
    - main
```

## 📚 Additional Resources

- [AWS WAF Developer Guide](https://docs.aws.amazon.com/waf/)
- [Terraform AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [GitLab CI/CD Documentation](https://docs.gitlab.com/ee/ci/)
- [WAF Security Best Practices](https://aws.amazon.com/waf/security-best-practices/)

## 🤝 Contributing

1. Fork the GitLab repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a merge request
6. Update documentation

This comprehensive example demonstrates enterprise-ready WAF deployment patterns using GitLab remote modules with advanced security configurations and proper operational practices.