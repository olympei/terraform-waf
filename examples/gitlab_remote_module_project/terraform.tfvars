# Comprehensive GitLab Remote Module Project Configuration

# Basic Configuration
aws_region   = "us-east-1"
environment  = "production"
project_name = "enterprise-waf-demo"

# GitLab Repository Configuration
gitlab_repo_url = "git::ssh://git@gitlab.com/yourgroup/infrastructure/terraform-waf.git"
module_version  = "v1.0.0"

# Note: This example demonstrates all available WAF modules:
# - ip-set: For IP address management (malicious and trusted IPs)
# - regex-pattern-set: For advanced pattern matching (SQL injection, bot detection)
# - waf-rule-group: For custom security rules with cross-module integration
# - waf: For the main Web Application Firewall
# - s3-cross-account-replication: For WAF log management and backup
# - rule-group: For additional specialized application rules

# The configuration creates a comprehensive enterprise-grade WAF solution
# with multiple layers of protection and proper log management.