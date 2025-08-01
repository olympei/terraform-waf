# ============================================================================
# COMPREHENSIVE GITLAB REMOTE MODULE PROJECT EXAMPLE
# This example demonstrates all available WAF modules in enterprise scenarios
# ============================================================================

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.3.0"
}

provider "aws" {
  region = var.aws_region
}

# Variables for comprehensive configuration
variable "aws_region" {
  description = "AWS region for deployment"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "enterprise-waf"
}

variable "gitlab_repo_url" {
  description = "GitLab repository URL for modules"
  type        = string
  default     = "git::ssh://git@gitlab.com/yourgroup/infrastructure/terraform-waf.git"
}

variable "module_version" {
  description = "Module version/branch to use"
  type        = string
  default     = "v1.0.0"
}

# ============================================================================
# USE CASE 1: IP SET MODULE - Malicious IP Blocking
# ============================================================================

module "malicious_ip_set" {
  source = "git::ssh://git@gitlab.com/yourgroup/infrastructure/terraform-waf.git//modules/ip-set?ref=v1.0.0"

  name               = "${var.project_name}-malicious-ips"
  scope              = "REGIONAL"
  ip_address_version = "IPV4"
  addresses = [
    "192.0.2.0/24",      # Example malicious network
    "198.51.100.0/24",   # Known bot network
    "203.0.113.0/24",    # Suspicious IP range
    "10.0.0.100/32",     # Specific malicious IP
    "172.16.0.0/16"      # Internal network to block
  ]

  tags = {
    Environment = var.environment
    Project     = var.project_name
    Purpose     = "Block malicious IPs"
    Module      = "ip-set"
    Source      = "GitLab Remote"
  }
}

module "trusted_ip_set" {
  source = "git::ssh://git@gitlab.com/yourgroup/infrastructure/terraform-waf.git//modules/ip-set?ref=v1.0.0"

  name               = "${var.project_name}-trusted-ips"
  scope              = "REGIONAL"
  ip_address_version = "IPV4"
  addresses = [
    "203.0.113.100/32",  # Office IP
    "198.51.100.50/32",  # VPN gateway
    "192.0.2.200/32",    # Admin access IP
    "10.1.0.0/16"        # Corporate network
  ]

  tags = {
    Environment = var.environment
    Project     = var.project_name
    Purpose     = "Allow trusted IPs"
    Module      = "ip-set"
    Source      = "GitLab Remote"
  }
}

# ============================================================================
# USE CASE 2: REGEX PATTERN SET MODULE - Advanced Threat Detection
# ============================================================================

module "sql_injection_patterns" {
  source = "git::ssh://git@gitlab.com/yourgroup/infrastructure/terraform-waf.git//modules/regex-pattern-set?ref=v1.0.0"

  name  = "${var.project_name}-sqli-patterns"
  scope = "REGIONAL"
  regex_strings = [
    "(?i)select.*from",
    "(?i)union.*select",
    "(?i)drop.*table",
    "(?i)insert.*into",
    "(?i)delete.*from",
    "(?i)update.*set",
    "(?i)exec.*sp_",
    "(?i)script.*alert",
    "(?i)javascript:",
    "(?i)vbscript:",
    "(?i)onload.*=",
    "(?i)onerror.*="
  ]

  tags = {
    Environment = var.environment
    Project     = var.project_name
    Purpose     = "SQL injection and XSS detection"
    Module      = "regex-pattern-set"
    Source      = "GitLab Remote"
  }
}

module "bot_detection_patterns" {
  source = "git::ssh://git@gitlab.com/yourgroup/infrastructure/terraform-waf.git//modules/regex-pattern-set?ref=v1.0.0"

  name  = "${var.project_name}-bot-patterns"
  scope = "REGIONAL"
  regex_strings = [
    "(?i)bot",
    "(?i)crawler",
    "(?i)spider",
    "(?i)scraper",
    "(?i)wget",
    "(?i)curl",
    "(?i)python-requests",
    "(?i)automated",
    "(?i)headless"
  ]

  tags = {
    Environment = var.environment
    Project     = var.project_name
    Purpose     = "Bot and automated traffic detection"
    Module      = "regex-pattern-set"
    Source      = "GitLab Remote"
  }
}

# ============================================================================
# USE CASE 3: WAF RULE GROUP MODULE - Security Rules with Integration
# ============================================================================

module "security_rule_group" {
  source = "git::ssh://git@gitlab.com/yourgroup/infrastructure/terraform-waf.git//modules/waf-rule-group?ref=v1.0.0"

  rule_group_name = "${var.project_name}-security-rules"
  name            = "${var.project_name}-security-rules"
  scope           = "REGIONAL"
  capacity        = 300
  metric_name     = "SecurityRuleGroup"

  custom_rules = [
    # Rule 1: Block malicious IPs
    {
      name        = "BlockMaliciousIPs"
      priority    = 10
      action      = "block"
      metric_name = "block_malicious_ips"
      statement_config = {
        ip_set_reference_statement = {
          arn = module.malicious_ip_set.arn
        }
      }
    },

    # Rule 2: Allow trusted IPs
    {
      name        = "AllowTrustedIPs"
      priority    = 20
      action      = "allow"
      metric_name = "allow_trusted_ips"
      statement_config = {
        ip_set_reference_statement = {
          arn = module.trusted_ip_set.arn
        }
      }
    },

    # Rule 3: Block SQL injection attempts
    {
      name        = "BlockSQLInjection"
      priority    = 30
      action      = "block"
      metric_name = "block_sql_injection"
      statement_config = {
        regex_pattern_set_reference_statement = {
          arn = module.sql_injection_patterns.arn
          field_to_match = {
            body = {}
          }
          text_transformation = {
            priority = 0
            type     = "URL_DECODE"
          }
        }
      }
    },

    # Rule 4: Block bots and automated traffic
    {
      name        = "BlockBots"
      priority    = 40
      action      = "block"
      metric_name = "block_bots"
      statement_config = {
        regex_pattern_set_reference_statement = {
          arn = module.bot_detection_patterns.arn
          field_to_match = {
            single_header = {
              name = "user-agent"
            }
          }
          text_transformation = {
            priority = 0
            type     = "LOWERCASE"
          }
        }
      }
    },

    # Rule 5: Geographic blocking
    {
      name        = "BlockRestrictedCountries"
      priority    = 50
      action      = "block"
      metric_name = "block_restricted_countries"
      statement_config = {
        geo_match_statement = {
          country_codes = ["CN", "RU", "KP", "IR"]
        }
      }
    }
  ]

  tags = {
    Environment = var.environment
    Project     = var.project_name
    Purpose     = "Comprehensive security rules"
    Module      = "waf-rule-group"
    Source      = "GitLab Remote"
  }
}

module "rate_limiting_rule_group" {
  source = "git::ssh://git@gitlab.com/yourgroup/infrastructure/terraform-waf.git//modules/waf-rule-group?ref=v1.0.0"

  rule_group_name = "${var.project_name}-rate-limiting"
  name            = "${var.project_name}-rate-limiting"
  scope           = "REGIONAL"
  capacity        = 200
  metric_name     = "RateLimitingRuleGroup"

  custom_rules = [
    # Rule 1: API rate limiting
    {
      name        = "APIRateLimit"
      priority    = 10
      action      = "block"
      metric_name = "api_rate_limit"
      statement_config = {
        and_statement = {
          statements = [
            {
              byte_match_statement = {
                search_string         = "/api/"
                positional_constraint = "STARTS_WITH"
                field_to_match = {
                  uri_path = {}
                }
                text_transformation = {
                  priority = 0
                  type     = "LOWERCASE"
                }
              }
            },
            {
              rate_based_statement = {
                limit              = 2000
                aggregate_key_type = "IP"
              }
            }
          ]
        }
      }
    },

    # Rule 2: General web traffic rate limiting
    {
      name        = "GeneralRateLimit"
      priority    = 20
      action      = "block"
      metric_name = "general_rate_limit"
      statement_config = {
        rate_based_statement = {
          limit              = 10000
          aggregate_key_type = "IP"
        }
      }
    }
  ]

  tags = {
    Environment = var.environment
    Project     = var.project_name
    Purpose     = "Rate limiting protection"
    Module      = "waf-rule-group"
    Source      = "GitLab Remote"
  }
}

# ============================================================================
# USE CASE 4: MAIN WAF MODULE - Comprehensive Web Application Firewall
# ============================================================================

module "enterprise_waf" {
  source = "git::ssh://git@gitlab.com/yourgroup/infrastructure/terraform-waf.git//modules/waf?ref=v1.0.0"

  name           = "${var.project_name}-main-waf"
  scope          = "REGIONAL"
  default_action = "allow"

  # Integrate custom rule groups
  rule_group_arn_list = [
    {
      arn      = module.security_rule_group.waf_rule_group_arn
      name     = "security-rules"
      priority = 100
    },
    {
      arn      = module.rate_limiting_rule_group.waf_rule_group_arn
      name     = "rate-limiting-rules"
      priority = 200
    }
  ]

  # AWS managed rule groups
  aws_managed_rule_groups = [
    {
      name            = "AWSManagedRulesCommonRuleSet"
      vendor_name     = "AWS"
      priority        = 300
      override_action = "none"
    },
    {
      name            = "AWSManagedRulesKnownBadInputsRuleSet"
      vendor_name     = "AWS"
      priority        = 400
      override_action = "none"
    },
    {
      name            = "AWSManagedRulesSQLiRuleSet"
      vendor_name     = "AWS"
      priority        = 500
      override_action = "none"
    },
    {
      name            = "AWSManagedRulesLinuxRuleSet"
      vendor_name     = "AWS"
      priority        = 600
      override_action = "none"
    }
  ]

  # Custom inline rules for specific use cases
  custom_inline_rules = [
    {
      name        = "AllowHealthChecks"
      priority    = 700
      action      = "allow"
      metric_name = "allow_health_checks"
      statement_config = {
        byte_match_statement = {
          search_string         = "/health"
          positional_constraint = "EXACTLY"
          field_to_match = {
            uri_path = {}
          }
          text_transformation = {
            priority = 0
            type     = "LOWERCASE"
          }
        }
      }
    },
    {
      name        = "BlockAdminFromUntrustedIPs"
      priority    = 800
      action      = "block"
      metric_name = "block_admin_untrusted"
      statement_config = {
        and_statement = {
          statements = [
            {
              byte_match_statement = {
                search_string         = "/admin"
                positional_constraint = "STARTS_WITH"
                field_to_match = {
                  uri_path = {}
                }
                text_transformation = {
                  priority = 0
                  type     = "LOWERCASE"
                }
              }
            },
            {
              not_statement = {
                statement = {
                  ip_set_reference_statement = {
                    arn = module.trusted_ip_set.arn
                  }
                }
              }
            }
          ]
        }
      }
    }
  ]

  # ALB associations (example)
  alb_arn_list = []

  # Logging configuration
  create_log_group            = true
  log_group_retention_in_days = 90
  enable_kms_encryption       = true

  tags = {
    Environment = var.environment
    Project     = var.project_name
    Purpose     = "Main enterprise WAF"
    Module      = "waf"
    Source      = "GitLab Remote"
  }
}

# ============================================================================
# USE CASE 5: S3 CROSS-ACCOUNT REPLICATION MODULE - Log Management
# ============================================================================

module "waf_log_replication" {
  source = "git::ssh://git@gitlab.com/yourgroup/infrastructure/terraform-waf.git//modules/s3-cross-account-replication?ref=v1.0.0"

  # Source bucket configuration
  source_bucket_name = "${var.project_name}-waf-logs-${var.aws_region}"
  source_region      = var.aws_region

  # Destination bucket configuration
  destination_bucket_name    = "${var.project_name}-waf-logs-backup-us-west-2"
  destination_region         = "us-west-2"
  destination_account_id     = "123456789012" # Replace with actual account ID
  destination_storage_class  = "STANDARD_IA"

  # Replication configuration
  replication_rule_id     = "waf-logs-replication"
  replication_rule_status = "Enabled"
  delete_marker_replication_status = "Enabled"

  # Filtering
  filter_prefix = "waf-logs/"

  # Encryption
  enable_kms_encryption = true
  replica_kms_key_id   = "arn:aws:kms:us-west-2:123456789012:key/12345678-1234-1234-1234-123456789012"

  tags = {
    Environment = var.environment
    Project     = var.project_name
    Purpose     = "WAF log backup and replication"
    Module      = "s3-cross-account-replication"
    Source      = "GitLab Remote"
  }
}

# ============================================================================
# USE CASE 6: RULE GROUP MODULE - Additional Specialized Rules
# ============================================================================

module "application_specific_rules" {
  source = "git::ssh://git@gitlab.com/yourgroup/infrastructure/terraform-waf.git//modules/rule-group?ref=v1.0.0"

  rule_group_name = "${var.project_name}-app-specific"
  name            = "${var.project_name}-app-specific"
  scope           = "REGIONAL"
  capacity        = 150
  metric_name     = "AppSpecificRuleGroup"

  custom_rules = [
    # Rule for specific application endpoints
    {
      name        = "ProtectAPIEndpoints"
      priority    = 10
      action      = "block"
      metric_name = "protect_api_endpoints"
      statement_config = {
        and_statement = {
          statements = [
            {
              byte_match_statement = {
                search_string         = "/api/v1/sensitive"
                positional_constraint = "STARTS_WITH"
                field_to_match = {
                  uri_path = {}
                }
                text_transformation = {
                  priority = 0
                  type     = "LOWERCASE"
                }
              }
            },
            {
              not_statement = {
                statement = {
                  byte_match_statement = {
                    search_string         = "Bearer "
                    positional_constraint = "STARTS_WITH"
                    field_to_match = {
                      single_header = {
                        name = "authorization"
                      }
                    }
                    text_transformation = {
                      priority = 0
                      type     = "NONE"
                    }
                  }
                }
              }
            }
          ]
        }
      }
    }
  ]

  tags = {
    Environment = var.environment
    Project     = var.project_name
    Purpose     = "Application-specific protection"
    Module      = "rule-group"
    Source      = "GitLab Remote"
  }
}
# ============================================================================
# OUTPUTS - Comprehensive Resource Information
# ============================================================================

# IP Set Outputs
output "malicious_ip_set_arn" {
  description = "ARN of the malicious IP set"
  value       = module.malicious_ip_set.arn
}

output "trusted_ip_set_arn" {
  description = "ARN of the trusted IP set"
  value       = module.trusted_ip_set.arn
}

# Regex Pattern Set Outputs
output "sql_injection_patterns_arn" {
  description = "ARN of the SQL injection patterns set"
  value       = module.sql_injection_patterns.arn
}

output "bot_detection_patterns_arn" {
  description = "ARN of the bot detection patterns set"
  value       = module.bot_detection_patterns.arn
}

# Rule Group Outputs
output "security_rule_group_arn" {
  description = "ARN of the security rule group"
  value       = module.security_rule_group.waf_rule_group_arn
}

output "rate_limiting_rule_group_arn" {
  description = "ARN of the rate limiting rule group"
  value       = module.rate_limiting_rule_group.waf_rule_group_arn
}

output "application_specific_rules_arn" {
  description = "ARN of the application-specific rule group"
  value       = module.application_specific_rules.waf_rule_group_arn
}

# Main WAF Outputs
output "enterprise_waf_arn" {
  description = "ARN of the main enterprise WAF"
  value       = module.enterprise_waf.web_acl_arn
}

output "enterprise_waf_id" {
  description = "ID of the main enterprise WAF"
  value       = module.enterprise_waf.web_acl_id
}

# S3 Replication Outputs
output "waf_log_replication_source_bucket" {
  description = "Source bucket for WAF log replication"
  value       = module.waf_log_replication.source_bucket_id
}

output "waf_log_replication_destination_bucket" {
  description = "Destination bucket for WAF log replication"
  value       = module.waf_log_replication.destination_bucket_id
}

# Comprehensive Configuration Summary
output "enterprise_waf_configuration" {
  description = "Complete enterprise WAF configuration summary"
  value = {
    project_name = var.project_name
    environment  = var.environment
    region       = var.aws_region
    
    security_components = {
      ip_sets = {
        malicious_ips = {
          arn           = module.malicious_ip_set.arn
          address_count = length(module.malicious_ip_set.addresses)
        }
        trusted_ips = {
          arn           = module.trusted_ip_set.arn
          address_count = length(module.trusted_ip_set.addresses)
        }
      }
      
      regex_patterns = {
        sql_injection = {
          arn           = module.sql_injection_patterns.arn
          pattern_count = length(module.sql_injection_patterns.regex_strings)
        }
        bot_detection = {
          arn           = module.bot_detection_patterns.arn
          pattern_count = length(module.bot_detection_patterns.regex_strings)
        }
      }
      
      rule_groups = {
        security_rules = {
          arn      = module.security_rule_group.waf_rule_group_arn
          capacity = 300
          rules    = 5
        }
        rate_limiting = {
          arn      = module.rate_limiting_rule_group.waf_rule_group_arn
          capacity = 200
          rules    = 2
        }
        app_specific = {
          arn      = module.application_specific_rules.waf_rule_group_arn
          capacity = 150
          rules    = 1
        }
      }
      
      main_waf = {
        arn                     = module.enterprise_waf.web_acl_arn
        id                      = module.enterprise_waf.web_acl_id
        custom_rule_groups      = 3
        aws_managed_rule_groups = 4
        inline_rules           = 2
      }
      
      log_management = {
        source_bucket      = module.waf_log_replication.source_bucket_id
        destination_bucket = module.waf_log_replication.destination_bucket_id
        replication_status = "Enabled"
      }
    }
    
    protection_coverage = [
      "Malicious IP blocking",
      "Trusted IP allowlisting",
      "SQL injection detection",
      "Bot and automated traffic blocking",
      "Geographic restrictions",
      "Rate limiting (API and general)",
      "Application-specific endpoint protection",
      "AWS managed rule sets (OWASP Top 10, Known Bad Inputs, SQLi, Linux)",
      "Health check allowlisting",
      "Admin panel protection",
      "Cross-account log replication"
    ]
    
    gitlab_integration = {
      repository_url = var.gitlab_repo_url
      module_version = var.module_version
      modules_used = [
        "ip-set",
        "regex-pattern-set", 
        "waf-rule-group",
        "waf",
        "s3-cross-account-replication",
        "rule-group"
      ]
    }
  }
}