# ============================================================================
# ENTERPRISE WAF ACL MODULE - COMPREHENSIVE USE CASES
# This example demonstrates advanced enterprise WAF configurations with
# multiple security layers, compliance requirements, and threat protection
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

# ============================================================================
# VARIABLES - Enterprise Configuration
# ============================================================================

variable "aws_region" {
  description = "AWS region for deployment"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
  default     = "production"
  
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "organization" {
  description = "Organization name"
  type        = string
  default     = "enterprise-corp"
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "enterprise-waf"
}

variable "compliance_requirements" {
  description = "List of compliance requirements"
  type        = list(string)
  default     = ["PCI-DSS", "SOX", "HIPAA", "GDPR"]
}

variable "threat_intelligence_feeds" {
  description = "Enable threat intelligence integration"
  type        = bool
  default     = true
}

variable "zero_trust_mode" {
  description = "Enable zero-trust security model"
  type        = bool
  default     = true
}

variable "alb_arn_list" {
  description = "List of ALB ARNs for enterprise applications"
  type        = list(string)
  default     = []
}

variable "trusted_ip_ranges" {
  description = "Corporate trusted IP ranges"
  type        = list(string)
  default = [
    "203.0.113.0/24",  # Corporate HQ
    "198.51.100.0/24", # Branch offices
    "192.0.2.0/24"     # VPN gateway
  ]
}

variable "blocked_countries" {
  description = "Countries to block for compliance"
  type        = list(string)
  default     = ["CN", "RU", "KP", "IR", "SY"]
}

variable "api_rate_limits" {
  description = "API rate limiting configuration"
  type = object({
    general_api = number
    auth_api    = number
    admin_api   = number
  })
  default = {
    general_api = 10000
    auth_api    = 1000
    admin_api   = 100
  }
}

variable "tags" {
  description = "Enterprise tags for all resources"
  type        = map(string)
  default = {
    Environment   = "production"
    Project       = "enterprise-waf"
    Owner         = "security-team"
    CostCenter    = "security"
    Compliance    = "pci-dss-sox-hipaa-gdpr"
    Criticality   = "high"
    DataClass     = "confidential"
    BackupPolicy  = "daily"
    MonitoringTier = "premium"
  }
}

# ============================================================================
# ENTERPRISE USE CASE 1: ZERO-TRUST SECURITY MODEL
# Default block with explicit allow rules for trusted sources
# ============================================================================

module "zero_trust_rule_group" {
  source = "../../../modules/waf-rule-group"

  rule_group_name = "${var.project_name}-zero-trust-rules"
  name            = "${var.project_name}-zero-trust-rules"
  scope           = "REGIONAL"
  capacity        = 500
  metric_name     = "ZeroTrustRuleGroup"

  custom_rules = [
    # Allow trusted corporate IP ranges
    {
      name        = "AllowCorporateIPs"
      priority    = 10
      action      = "allow"
      metric_name = "allow_corporate_ips"
      statement_config = {
        or_statement = {
          statements = [
            for ip_range in var.trusted_ip_ranges : {
              ip_set_reference_statement = {
                arn = "arn:aws:wafv2:${var.aws_region}:123456789012:regional/ipset/corporate-ips/${substr(md5(ip_range), 0, 8)}"
              }
            }
          ]
        }
      }
    },

    # Allow legitimate user agents
    {
      name        = "AllowLegitimateUserAgents"
      priority    = 20
      action      = "allow"
      metric_name = "allow_legitimate_user_agents"
      statement_config = {
        or_statement = {
          statements = [
            {
              byte_match_statement = {
                search_string         = "Mozilla"
                positional_constraint = "CONTAINS"
                field_to_match = {
                  single_header = {
                    name = "user-agent"
                  }
                }
                text_transformation = {
                  priority = 0
                  type     = "NONE"
                }
              }
            },
            {
              byte_match_statement = {
                search_string         = "Chrome"
                positional_constraint = "CONTAINS"
                field_to_match = {
                  single_header = {
                    name = "user-agent"
                  }
                }
                text_transformation = {
                  priority = 0
                  type     = "NONE"
                }
              }
            }
          ]
        }
      }
    },

    # Block suspicious patterns
    {
      name        = "BlockSuspiciousPatterns"
      priority    = 30
      action      = "block"
      metric_name = "block_suspicious_patterns"
      statement_config = {
        or_statement = {
          statements = [
            {
              byte_match_statement = {
                search_string         = "../"
                positional_constraint = "CONTAINS"
                field_to_match = {
                  uri_path = {}
                }
                text_transformation = {
                  priority = 0
                  type     = "URL_DECODE"
                }
              }
            },
            {
              byte_match_statement = {
                search_string         = "eval("
                positional_constraint = "CONTAINS"
                field_to_match = {
                  body = {}
                }
                text_transformation = {
                  priority = 0
                  type     = "HTML_ENTITY_DECODE"
                }
              }
            }
          ]
        }
      }
    }
  ]

  tags = merge(var.tags, {
    UseCase     = "zero-trust-security"
    SecurityTier = "maximum"
  })
}

module "enterprise_zero_trust_waf" {
  source = "../../../modules/waf"

  name           = "${var.project_name}-zero-trust"
  scope          = "REGIONAL"
  default_action = var.zero_trust_mode ? "block" : "allow"
  alb_arn_list   = var.alb_arn_list

  rule_group_arn_list = [
    {
      arn      = module.zero_trust_rule_group.waf_rule_group_arn
      name     = "zero-trust-rules"
      priority = 100
    }
  ]

  aws_managed_rule_groups = [
    {
      name            = "AWSManagedRulesCommonRuleSet"
      vendor_name     = "AWS"
      priority        = 200
      override_action = "count"  # Monitor in zero-trust mode
    }
  ]

  custom_inline_rules = [
    {
      name        = "AllowHealthChecks"
      priority    = 300
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
    }
  ]

  # Enterprise logging
  create_log_group            = true
  log_group_retention_in_days = 365  # 1 year for compliance
  kms_key_id                  = null  # Auto-create KMS key

  tags = merge(var.tags, {
    SecurityModel = "zero-trust"
    DefaultAction = var.zero_trust_mode ? "block" : "allow"
  })
}

# ============================================================================
# ENTERPRISE USE CASE 2: MULTI-TIER RATE LIMITING
# Different rate limits for different application tiers
# ============================================================================

module "rate_limiting_rule_group" {
  source = "../../../modules/waf-rule-group"

  rule_group_name = "${var.project_name}-rate-limiting"
  name            = "${var.project_name}-rate-limiting"
  scope           = "REGIONAL"
  capacity        = 300
  metric_name     = "RateLimitingRuleGroup"

  custom_rules = [
    # Admin API - Strict rate limiting
    {
      name        = "AdminAPIRateLimit"
      priority    = 10
      action      = "block"
      metric_name = "admin_api_rate_limit"
      statement_config = {
        and_statement = {
          statements = [
            {
              byte_match_statement = {
                search_string         = "/admin/api/"
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
                limit              = var.api_rate_limits.admin_api
                aggregate_key_type = "IP"
              }
            }
          ]
        }
      }
    },

    # Authentication API - Medium rate limiting
    {
      name        = "AuthAPIRateLimit"
      priority    = 20
      action      = "block"
      metric_name = "auth_api_rate_limit"
      statement_config = {
        and_statement = {
          statements = [
            {
              or_statement = {
                statements = [
                  {
                    byte_match_statement = {
                      search_string         = "/auth/"
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
                    byte_match_statement = {
                      search_string         = "/login"
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
                ]
              }
            },
            {
              rate_based_statement = {
                limit              = var.api_rate_limits.auth_api
                aggregate_key_type = "IP"
              }
            }
          ]
        }
      }
    },

    # General API - Standard rate limiting
    {
      name        = "GeneralAPIRateLimit"
      priority    = 30
      action      = "block"
      metric_name = "general_api_rate_limit"
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
                limit              = var.api_rate_limits.general_api
                aggregate_key_type = "IP"
              }
            }
          ]
        }
      }
    }
  ]

  tags = merge(var.tags, {
    UseCase = "multi-tier-rate-limiting"
  })
}

module "enterprise_rate_limited_waf" {
  source = "../../../modules/waf"

  name           = "${var.project_name}-rate-limited"
  scope          = "REGIONAL"
  default_action = "allow"
  alb_arn_list   = var.alb_arn_list

  rule_group_arn_list = [
    {
      arn      = module.rate_limiting_rule_group.waf_rule_group_arn
      name     = "rate-limiting-rules"
      priority = 100
    }
  ]

  aws_managed_rule_groups = [
    {
      name            = "AWSManagedRulesCommonRuleSet"
      vendor_name     = "AWS"
      priority        = 200
      override_action = "none"
    }
  ]

  tags = merge(var.tags, {
    UseCase = "multi-tier-rate-limiting"
  })
}

# ============================================================================
# ENTERPRISE USE CASE 3: COMPLIANCE-DRIVEN WAF
# PCI-DSS, SOX, HIPAA, GDPR compliance requirements
# ============================================================================

module "compliance_rule_group" {
  source = "../../../modules/waf-rule-group"

  rule_group_name = "${var.project_name}-compliance-rules"
  name            = "${var.project_name}-compliance-rules"
  scope           = "REGIONAL"
  capacity        = 400
  metric_name     = "ComplianceRuleGroup"

  custom_rules = [
    # PCI-DSS: Block countries with high fraud risk
    {
      name        = "PCIDSSGeoBlocking"
      priority    = 10
      action      = "block"
      metric_name = "pci_dss_geo_blocking"
      statement_config = {
        geo_match_statement = {
          country_codes = var.blocked_countries
        }
      }
    },

    # GDPR: Block requests without proper consent headers
    {
      name        = "GDPRConsentValidation"
      priority    = 20
      action      = "block"
      metric_name = "gdpr_consent_validation"
      statement_config = {
        and_statement = {
          statements = [
            {
              byte_match_statement = {
                search_string         = "/api/personal-data"
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
                    search_string         = "gdpr-consent=true"
                    positional_constraint = "CONTAINS"
                    field_to_match = {
                      single_header = {
                        name = "cookie"
                      }
                    }
                    text_transformation = {
                      priority = 0
                      type     = "LOWERCASE"
                    }
                  }
                }
              }
            }
          ]
        }
      }
    },

    # HIPAA: Protect PHI endpoints
    {
      name        = "HIPAAPHIProtection"
      priority    = 30
      action      = "block"
      metric_name = "hipaa_phi_protection"
      statement_config = {
        and_statement = {
          statements = [
            {
              or_statement = {
                statements = [
                  {
                    byte_match_statement = {
                      search_string         = "/api/patient"
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
                    byte_match_statement = {
                      search_string         = "/api/medical"
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
                ]
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
    },

    # SOX: Financial data protection
    {
      name        = "SOXFinancialDataProtection"
      priority    = 40
      action      = "block"
      metric_name = "sox_financial_protection"
      statement_config = {
        and_statement = {
          statements = [
            {
              byte_match_statement = {
                search_string         = "/api/financial"
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
              size_constraint_statement = {
                comparison_operator = "GT"
                size                = 1048576  # 1MB limit for financial data
                field_to_match = {
                  body = {}
                }
                text_transformation = {
                  priority = 0
                  type     = "NONE"
                }
              }
            }
          ]
        }
      }
    }
  ]

  tags = merge(var.tags, {
    UseCase    = "compliance-driven"
    Compliance = join("-", var.compliance_requirements)
  })
}

module "enterprise_compliance_waf" {
  source = "../../../modules/waf"

  name           = "${var.project_name}-compliance"
  scope          = "REGIONAL"
  default_action = "allow"
  alb_arn_list   = var.alb_arn_list

  rule_group_arn_list = [
    {
      arn      = module.compliance_rule_group.waf_rule_group_arn
      name     = "compliance-rules"
      priority = 100
    }
  ]

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
      priority        = 300
      override_action = "none"
    },
    {
      name            = "AWSManagedRulesKnownBadInputsRuleSet"
      vendor_name     = "AWS"
      priority        = 400
      override_action = "none"
    }
  ]

  # Compliance-specific inline rules
  custom_inline_rules = [
    {
      name        = "AuditLogAccess"
      priority    = 500
      action      = "allow"
      metric_name = "audit_log_access"
      statement_config = {
        and_statement = {
          statements = [
            {
              byte_match_statement = {
                search_string         = "/api/audit"
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
              byte_match_statement = {
                search_string         = "audit-role"
                positional_constraint = "CONTAINS"
                field_to_match = {
                  single_header = {
                    name = "x-user-role"
                  }
                }
                text_transformation = {
                  priority = 0
                  type     = "LOWERCASE"
                }
              }
            }
          ]
        }
      }
    }
  ]

  # Enhanced logging for compliance
  create_log_group            = true
  log_group_retention_in_days = 2555  # 7 years for SOX compliance
  kms_key_id                  = null   # Auto-create KMS key

  tags = merge(var.tags, {
    UseCase    = "compliance-driven"
    Compliance = join("-", var.compliance_requirements)
    Retention  = "7-years"
  })
}

# ============================================================================
# ENTERPRISE USE CASE 4: ADVANCED THREAT INTELLIGENCE
# Integration with threat feeds and behavioral analysis
# ============================================================================

module "threat_intelligence_rule_group" {
  source = "../../../modules/waf-rule-group"

  rule_group_name = "${var.project_name}-threat-intel"
  name            = "${var.project_name}-threat-intel"
  scope           = "REGIONAL"
  capacity        = 600
  metric_name     = "ThreatIntelRuleGroup"

  custom_rules = [
    # Known malicious IP patterns
    {
      name        = "BlockKnownMaliciousIPs"
      priority    = 10
      action      = "block"
      metric_name = "block_malicious_ips"
      statement_config = {
        ip_set_reference_statement = {
          arn = "arn:aws:wafv2:${var.aws_region}:123456789012:regional/ipset/threat-intel-ips/malicious"
        }
      }
    },

    # Suspicious user agent patterns
    {
      name        = "BlockSuspiciousUserAgents"
      priority    = 20
      action      = "block"
      metric_name = "block_suspicious_user_agents"
      statement_config = {
        or_statement = {
          statements = [
            {
              byte_match_statement = {
                search_string         = "sqlmap"
                positional_constraint = "CONTAINS"
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
            },
            {
              byte_match_statement = {
                search_string         = "nikto"
                positional_constraint = "CONTAINS"
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
            },
            {
              byte_match_statement = {
                search_string         = "nessus"
                positional_constraint = "CONTAINS"
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
          ]
        }
      }
    },

    # Advanced persistent threat patterns
    {
      name        = "DetectAPTPatterns"
      priority    = 30
      action      = "block"
      metric_name = "detect_apt_patterns"
      statement_config = {
        and_statement = {
          statements = [
            {
              byte_match_statement = {
                search_string         = "cmd.exe"
                positional_constraint = "CONTAINS"
                field_to_match = {
                  body = {}
                }
                text_transformation = {
                  priority = 0
                  type     = "URL_DECODE"
                }
              }
            },
            {
              byte_match_statement = {
                search_string         = "powershell"
                positional_constraint = "CONTAINS"
                field_to_match = {
                  body = {}
                }
                text_transformation = {
                  priority = 0
                  type     = "URL_DECODE"
                }
              }
            }
          ]
        }
      }
    },

    # Behavioral anomaly detection
    {
      name        = "BehavioralAnomalyDetection"
      priority    = 40
      action      = "block"
      metric_name = "behavioral_anomaly"
      statement_config = {
        and_statement = {
          statements = [
            {
              rate_based_statement = {
                limit              = 100
                aggregate_key_type = "IP"
              }
            },
            {
              size_constraint_statement = {
                comparison_operator = "GT"
                size                = 65536  # 64KB
                field_to_match = {
                  body = {}
                }
                text_transformation = {
                  priority = 0
                  type     = "NONE"
                }
              }
            }
          ]
        }
      }
    }
  ]

  tags = merge(var.tags, {
    UseCase           = "threat-intelligence"
    ThreatIntelFeeds  = var.threat_intelligence_feeds
    SecurityTier      = "advanced"
  })
}

module "enterprise_threat_intel_waf" {
  source = "../../../modules/waf"

  name           = "${var.project_name}-threat-intel"
  scope          = "REGIONAL"
  default_action = "allow"
  alb_arn_list   = var.alb_arn_list

  rule_group_arn_list = [
    {
      arn      = module.threat_intelligence_rule_group.waf_rule_group_arn
      name     = "threat-intel-rules"
      priority = 100
    }
  ]

  aws_managed_rule_groups = [
    {
      name            = "AWSManagedRulesCommonRuleSet"
      vendor_name     = "AWS"
      priority        = 200
      override_action = "none"
    },
    {
      name            = "AWSManagedRulesAmazonIpReputationList"
      vendor_name     = "AWS"
      priority        = 300
      override_action = "none"
    },
    {
      name            = "AWSManagedRulesAnonymousIpList"
      vendor_name     = "AWS"
      priority        = 400
      override_action = "none"
    }
  ]

  tags = merge(var.tags, {
    UseCase          = "threat-intelligence"
    ThreatIntelFeeds = var.threat_intelligence_feeds
  })
}

# ============================================================================
# ENTERPRISE USE CASE 5: COMPREHENSIVE ENTERPRISE WAF
# All-in-one enterprise solution with multiple protection layers
# ============================================================================

module "enterprise_comprehensive_waf" {
  source = "../../../modules/waf"

  name           = "${var.project_name}-comprehensive"
  scope          = "REGIONAL"
  default_action = "allow"
  alb_arn_list   = var.alb_arn_list

  # Multiple custom rule groups for layered security
  rule_group_arn_list = [
    {
      arn      = module.zero_trust_rule_group.waf_rule_group_arn
      name     = "zero-trust-layer"
      priority = 100
    },
    {
      arn      = module.rate_limiting_rule_group.waf_rule_group_arn
      name     = "rate-limiting-layer"
      priority = 200
    },
    {
      arn      = module.compliance_rule_group.waf_rule_group_arn
      name     = "compliance-layer"
      priority = 300
    },
    {
      arn      = module.threat_intelligence_rule_group.waf_rule_group_arn
      name     = "threat-intel-layer"
      priority = 400
    }
  ]

  # Comprehensive AWS managed rules
  aws_managed_rule_groups = [
    {
      name            = "AWSManagedRulesCommonRuleSet"
      vendor_name     = "AWS"
      priority        = 500
      override_action = "none"
    },
    {
      name            = "AWSManagedRulesSQLiRuleSet"
      vendor_name     = "AWS"
      priority        = 600
      override_action = "none"
    },
    {
      name            = "AWSManagedRulesKnownBadInputsRuleSet"
      vendor_name     = "AWS"
      priority        = 700
      override_action = "none"
    },
    {
      name            = "AWSManagedRulesAmazonIpReputationList"
      vendor_name     = "AWS"
      priority        = 800
      override_action = "none"
    },
    {
      name            = "AWSManagedRulesAnonymousIpList"
      vendor_name     = "AWS"
      priority        = 900
      override_action = "none"
    },
    {
      name            = "AWSManagedRulesLinuxRuleSet"
      vendor_name     = "AWS"
      priority        = 1000
      override_action = "none"
    }
  ]

  # Enterprise-specific inline rules
  custom_inline_rules = [
    {
      name        = "EnterpriseHealthChecks"
      priority    = 1100
      action      = "allow"
      metric_name = "enterprise_health_checks"
      statement_config = {
        or_statement = {
          statements = [
            {
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
            },
            {
              byte_match_statement = {
                search_string         = "/status"
                positional_constraint = "EXACTLY"
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
              byte_match_statement = {
                search_string         = "/ping"
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
          ]
        }
      }
    },

    {
      name        = "EnterpriseAPIKeyValidation"
      priority    = 1200
      action      = "block"
      metric_name = "enterprise_api_key_validation"
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
              not_statement = {
                statement = {
                  or_statement = {
                    statements = [
                      {
                        byte_match_statement = {
                          search_string         = "x-api-key"
                          positional_constraint = "EXACTLY"
                          field_to_match = {
                            single_header = {
                              name = "x-api-key"
                            }
                          }
                          text_transformation = {
                            priority = 0
                            type     = "NONE"
                          }
                        }
                      },
                      {
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
                    ]
                  }
                }
              }
            }
          ]
        }
      }
    }
  ]

  # Enterprise logging and monitoring
  create_log_group            = true
  log_group_retention_in_days = 365
  kms_key_id                  = null

  tags = merge(var.tags, {
    UseCase       = "comprehensive-enterprise"
    SecurityTiers = "zero-trust-rate-limiting-compliance-threat-intel"
    Protection    = "maximum"
  })
}# =========
===================================================================
# OUTPUTS - Enterprise WAF Configuration Summary
# ============================================================================

# Individual WAF ARNs
output "zero_trust_waf_arn" {
  description = "ARN of the zero-trust WAF"
  value       = module.enterprise_zero_trust_waf.web_acl_arn
}

output "rate_limited_waf_arn" {
  description = "ARN of the rate-limited WAF"
  value       = module.enterprise_rate_limited_waf.web_acl_arn
}

output "compliance_waf_arn" {
  description = "ARN of the compliance-driven WAF"
  value       = module.enterprise_compliance_waf.web_acl_arn
}

output "threat_intel_waf_arn" {
  description = "ARN of the threat intelligence WAF"
  value       = module.enterprise_threat_intel_waf.web_acl_arn
}

output "comprehensive_waf_arn" {
  description = "ARN of the comprehensive enterprise WAF"
  value       = module.enterprise_comprehensive_waf.web_acl_arn
}

# Rule Group ARNs
output "zero_trust_rule_group_arn" {
  description = "ARN of the zero-trust rule group"
  value       = module.zero_trust_rule_group.waf_rule_group_arn
}

output "rate_limiting_rule_group_arn" {
  description = "ARN of the rate limiting rule group"
  value       = module.rate_limiting_rule_group.waf_rule_group_arn
}

output "compliance_rule_group_arn" {
  description = "ARN of the compliance rule group"
  value       = module.compliance_rule_group.waf_rule_group_arn
}

output "threat_intelligence_rule_group_arn" {
  description = "ARN of the threat intelligence rule group"
  value       = module.threat_intelligence_rule_group.waf_rule_group_arn
}

# Comprehensive Enterprise Configuration Summary
output "enterprise_waf_configuration" {
  description = "Complete enterprise WAF configuration summary"
  value = {
    project_info = {
      name         = var.project_name
      organization = var.organization
      environment  = var.environment
      region       = var.aws_region
    }

    security_models = {
      zero_trust = {
        enabled        = var.zero_trust_mode
        default_action = var.zero_trust_mode ? "block" : "allow"
        waf_arn        = module.enterprise_zero_trust_waf.web_acl_arn
        description    = "Default block with explicit allow rules"
      }

      rate_limiting = {
        enabled     = true
        waf_arn     = module.enterprise_rate_limited_waf.web_acl_arn
        api_limits  = var.api_rate_limits
        description = "Multi-tier rate limiting for different API endpoints"
      }

      compliance = {
        enabled      = true
        waf_arn      = module.enterprise_compliance_waf.web_acl_arn
        requirements = var.compliance_requirements
        retention    = "7-years"
        description  = "PCI-DSS, SOX, HIPAA, GDPR compliance controls"
      }

      threat_intelligence = {
        enabled     = var.threat_intelligence_feeds
        waf_arn     = module.enterprise_threat_intel_waf.web_acl_arn
        description = "Advanced threat detection and behavioral analysis"
      }

      comprehensive = {
        enabled     = true
        waf_arn     = module.enterprise_comprehensive_waf.web_acl_arn
        layers      = 4
        description = "All-in-one enterprise solution with multiple protection layers"
      }
    }

    protection_layers = {
      custom_rule_groups = {
        zero_trust = {
          arn      = module.zero_trust_rule_group.waf_rule_group_arn
          capacity = 500
          rules    = 3
          purpose  = "Zero-trust security model with explicit allow rules"
        }

        rate_limiting = {
          arn      = module.rate_limiting_rule_group.waf_rule_group_arn
          capacity = 300
          rules    = 3
          purpose  = "Multi-tier rate limiting for API protection"
        }

        compliance = {
          arn      = module.compliance_rule_group.waf_rule_group_arn
          capacity = 400
          rules    = 4
          purpose  = "Regulatory compliance controls"
        }

        threat_intelligence = {
          arn      = module.threat_intelligence_rule_group.waf_rule_group_arn
          capacity = 600
          rules    = 4
          purpose  = "Advanced threat detection and prevention"
        }
      }

      aws_managed_rules = {
        common_rule_set = "OWASP Top 10 protection"
        sqli_rule_set   = "SQL injection protection"
        known_bad_inputs = "Known malicious input patterns"
        ip_reputation   = "AWS IP reputation intelligence"
        anonymous_ips   = "Anonymous IP detection"
        linux_rule_set  = "Linux-specific attack patterns"
      }

      inline_rules = {
        health_checks      = "Application health check allowlisting"
        api_key_validation = "API authentication enforcement"
        audit_log_access   = "Compliance audit trail access"
      }
    }

    enterprise_features = {
      logging = {
        enabled             = true
        retention_days      = 365
        kms_encryption      = true
        compliance_retention = "7-years for SOX"
      }

      monitoring = {
        cloudwatch_metrics = true
        custom_metrics     = true
        alerting_enabled   = true
      }

      compliance = {
        requirements = var.compliance_requirements
        geo_blocking = var.blocked_countries
        data_protection = [
          "PCI-DSS payment data protection",
          "HIPAA PHI endpoint protection", 
          "GDPR consent validation",
          "SOX financial data controls"
        ]
      }

      threat_protection = {
        ip_reputation     = true
        behavioral_analysis = true
        apt_detection     = true
        malicious_ua_blocking = true
      }
    }

    deployment_summary = {
      total_wafs         = 5
      total_rule_groups  = 4
      total_custom_rules = 14
      total_aws_rules    = 6
      total_inline_rules = 3
      protection_coverage = [
        "Zero-trust security model",
        "Multi-tier rate limiting",
        "Regulatory compliance (PCI-DSS, SOX, HIPAA, GDPR)",
        "Advanced threat intelligence",
        "Behavioral anomaly detection",
        "Geographic access controls",
        "API authentication enforcement",
        "Comprehensive logging and monitoring"
      ]
    }

    recommendations = {
      monitoring = [
        "Set up CloudWatch alarms for blocked requests",
        "Monitor rate limiting triggers",
        "Review compliance audit logs regularly",
        "Analyze threat intelligence patterns"
      ]

      maintenance = [
        "Update threat intelligence feeds regularly",
        "Review and adjust rate limits based on traffic patterns",
        "Validate compliance controls quarterly",
        "Test zero-trust rules in staging environment"
      ]

      optimization = [
        "Fine-tune rule priorities for performance",
        "Optimize rule group capacities based on usage",
        "Consider regional deployment for global applications",
        "Implement automated rule updates for threat feeds"
      ]
    }
  }
}
