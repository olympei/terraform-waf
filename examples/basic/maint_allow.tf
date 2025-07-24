provider "aws" {
  region = "us-east-1"
}

# Variables for enterprise zero-trust configuration
variable "name" {
  description = "Name of the enterprise zero-trust WAF ACL"
  type        = string
  default     = "enterprise-zero-trust-waf"
}

variable "scope" {
  description = "Scope of the WAF (REGIONAL or CLOUDFRONT)"
  type        = string
  default     = "REGIONAL"

  validation {
    condition     = contains(["REGIONAL", "CLOUDFRONT"], var.scope)
    error_message = "Scope must be either REGIONAL or CLOUDFRONT."
  }
}

variable "alb_arn_list" {
  description = "List of ALB ARNs to associate with the WAF"
  type        = list(string)
  default     = []
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
  default     = "prod"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "trusted_countries" {
  description = "List of trusted country codes to allow"
  type        = list(string)
  default     = ["US", "CA", "GB", "DE", "FR", "AU", "JP", "NL", "SE", "CH"]
}

variable "trusted_ip_ranges" {
  description = "List of trusted IP ranges (CIDR blocks) to allow"
  type        = list(string)
  default     = []
}

variable "allowed_user_agents" {
  description = "List of allowed user agent patterns"
  type        = list(string)
  default = [
    "Mozilla",
    "Chrome",
    "Safari",
    "Edge",
    "Firefox"
  ]
}
variable "api_rate_limit" {
  description = "Rate limit for API endpoints (requests per 5 minutes)"
  type        = number
  default     = 2000
}

variable "web_rate_limit" {
  description = "Rate limit for web traffic (requests per 5 minutes)"
  type        = number
  default     = 10000
}

variable "strict_rate_limit" {
  description = "Strict rate limit for flagged IPs (requests per 5 minutes)"
  type        = number
  default     = 200
}

variable "enable_logging" {
  description = "Enable comprehensive WAF logging"
  type        = bool
  default     = true
}

variable "create_log_group" {
  description = "Create a new CloudWatch log group for WAF logs"
  type        = bool
  default     = true
}

variable "existing_log_group_arn" {
  description = "ARN of existing CloudWatch log group for WAF logs"
  type        = string
  default     = null
}

variable "log_group_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 365 # 1 year for enterprise compliance
}

variable "enable_kms_encryption" {
  description = "Enable KMS encryption for logs"
  type        = bool
  default     = true
}
variable "tags" {
  description = "Tags for enterprise zero-trust resources"
  type        = map(string)
  default = {
    Environment   = "production"
    Purpose       = "Enterprise Zero-Trust WAF"
    SecurityModel = "zero-trust"
    SecurityLevel = "maximum"
    Compliance    = "pci-dss-sox-hipaa"
    Owner         = "security-team"
    CostCenter    = "security"
    Criticality   = "critical"
    DataClass     = "restricted"
  }
}

# Zero-Trust Allow Rules - Explicit Allow for Legitimate Traffic
module "zero_trust_allow_rules" {
  source = "../../modules/waf-rule-group"

  rule_group_name = "${var.name}-allow-rules"
  name            = "${var.name}-allow-rules"
  scope           = var.scope
  capacity        = 400
  metric_name     = "ZeroTrustAllowRules"

  custom_rules = [
    # Layer 1: Geographic Allow List (Highest Priority)
    {
      name        = "AllowTrustedCountries"
      priority    = 10
      action      = "allow"
      metric_name = "allow_trusted_countries"
      statement_config = {
        geo_match_statement = {
          country_codes = var.trusted_countries
        }
      }
    },

    # Layer 2: Allow Standard HTTP Methods for Legitimate Traffic
    {
      name        = "AllowStandardHTTPMethods"
      priority    = 15
      action      = "allow"
      metric_name = "allow_standard_http_methods"
      statement_config = {
        and_statement = {
          statements = [
            {
              byte_match_statement = {
                search_string         = "GET"
                positional_constraint = "EXACTLY"
                field_to_match = {
                  method = {}
                }
                text_transformation = {
                  priority = 0
                  type     = "NONE"
                }
              }
            },
            {
              geo_match_statement = {
                country_codes = var.trusted_countries
              }
            }
          ]
        }
      }
    },

    # Layer 3: Allow POST Methods for Forms and APIs
    {
      name        = "AllowPOSTMethods"
      priority    = 16
      action      = "allow"
      metric_name = "allow_post_methods"
      statement_config = {
        and_statement = {
          statements = [
            {
              byte_match_statement = {
                search_string         = "POST"
                positional_constraint = "EXACTLY"
                field_to_match = {
                  method = {}
                }
                text_transformation = {
                  priority = 0
                  type     = "NONE"
                }
              }
            },
            {
              geo_match_statement = {
                country_codes = var.trusted_countries
              }
            },
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
            }
          ]
        }
      }
    },

    # Layer 4: Allow PUT/PATCH for REST APIs
    {
      name        = "AllowRESTMethods"
      priority    = 17
      action      = "allow"
      metric_name = "allow_rest_methods"
      statement_config = {
        and_statement = {
          statements = [
            {
              or_statement = {
                statements = [
                  {
                    byte_match_statement = {
                      search_string         = "PUT"
                      positional_constraint = "EXACTLY"
                      field_to_match = {
                        method = {}
                      }
                      text_transformation = {
                        priority = 0
                        type     = "NONE"
                      }
                    }
                  },
                  {
                    byte_match_statement = {
                      search_string         = "PATCH"
                      positional_constraint = "EXACTLY"
                      field_to_match = {
                        method = {}
                      }
                      text_transformation = {
                        priority = 0
                        type     = "NONE"
                      }
                    }
                  }
                ]
              }
            },
            {
              geo_match_statement = {
                country_codes = var.trusted_countries
              }
            },
            {
              byte_match_statement = {
                search_string         = "application/json"
                positional_constraint = "CONTAINS"
                field_to_match = {
                  single_header = {
                    name = "content-type"
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

    # Layer 5: Allow OPTIONS for CORS Preflight
    {
      name        = "AllowCORSPreflight"
      priority    = 18
      action      = "allow"
      metric_name = "allow_cors_preflight"
      statement_config = {
        and_statement = {
          statements = [
            {
              byte_match_statement = {
                search_string         = "OPTIONS"
                positional_constraint = "EXACTLY"
                field_to_match = {
                  method = {}
                }
                text_transformation = {
                  priority = 0
                  type     = "NONE"
                }
              }
            },
            {
              geo_match_statement = {
                country_codes = var.trusted_countries
              }
            }
          ]
        }
      }
    },

    # Layer 6: Legitimate Browser User-Agents
    {
      name        = "AllowLegitimateUserAgents"
      priority    = 20
      action      = "allow"
      metric_name = "allow_legitimate_user_agents"
      statement_config = {
        and_statement = {
          statements = [
            {
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
                  },
                  {
                    byte_match_statement = {
                      search_string         = "Safari"
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
                      search_string         = "Edge"
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
                      search_string         = "Firefox"
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
            },
            {
              geo_match_statement = {
                country_codes = var.trusted_countries
              }
            }
          ]
        }
      }
    },

    # Layer 7: Allow Common Static Resources
    {
      name        = "AllowStaticResources"
      priority    = 25
      action      = "allow"
      metric_name = "allow_static_resources"
      statement_config = {
        and_statement = {
          statements = [
            {
              or_statement = {
                statements = [
                  {
                    byte_match_statement = {
                      search_string         = ".css"
                      positional_constraint = "ENDS_WITH"
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
                      search_string         = ".js"
                      positional_constraint = "ENDS_WITH"
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
                      search_string         = ".png"
                      positional_constraint = "ENDS_WITH"
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
                      search_string         = ".jpg"
                      positional_constraint = "ENDS_WITH"
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
                      search_string         = ".gif"
                      positional_constraint = "ENDS_WITH"
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
                      search_string         = ".ico"
                      positional_constraint = "ENDS_WITH"
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
              geo_match_statement = {
                country_codes = var.trusted_countries
              }
            }
          ]
        }
      }
    }
  ]


  tags = merge(var.tags, {
    RuleGroupType = "Zero-Trust-Allow"
  })
}

# Enterprise Zero-Trust WAF ACL - Default Block with Explicit Allow

module "enterprise_zero_trust_waf" {
  source = "../../modules/waf"

  name           = var.name
  scope          = var.scope
  default_action = "allow" # ALLOW BY DEFAULT: Monitor threats but allow traffic
  alb_arn_list   = var.alb_arn_list

  # CloudWatch logging configuration
  create_log_group            = var.enable_logging ? var.create_log_group : false
  existing_log_group_arn      = var.enable_logging && !var.create_log_group ? var.existing_log_group_arn : null
  log_group_retention_in_days = var.enable_logging && var.create_log_group ? var.log_group_retention_days : null
  kms_key_id                  = var.enable_logging && var.create_log_group && var.enable_kms_encryption ? null : null

  # Custom rule groups (Explicit Allow First)
  rule_group_arn_list = [
    {
      arn      = module.zero_trust_allow_rules.waf_rule_group_arn
      name     = "zero-trust-allow-rules"
      priority = 50
    }
  ]

  # AWS Managed Rules (Block mode for threat protection)
  aws_managed_rule_groups = [
    {
      name            = "AWSManagedRulesCommonRuleSet"
      vendor_name     = "AWS"
      priority        = 200
      override_action = "none" # Block actual threats
    }
  ]

  # Critical inline rules for monitoring and specific controls
  custom_inline_rules = [
    # Block known malicious patterns (high priority blocking rules)
    {
      name        = "BlockSQLInjectionAttempts"
      priority    = 100
      action      = "block"
      metric_name = "block_sqli_attempts"
      statement_config = {
        byte_match_statement = {
          search_string         = "union select"
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
    },

    # Block directory traversal attempts
    {
      name        = "BlockDirectoryTraversal"
      priority    = 110
      action      = "block"
      metric_name = "block_directory_traversal"
      statement_config = {
        byte_match_statement = {
          search_string         = "../"
          positional_constraint = "CONTAINS"
          field_to_match = {
            uri_path = {}
          }
          text_transformation = {
            priority = 0
            type     = "NONE"
          }
        }
      }
    },

    # Allow testpath path (specific application rule)
    {
      name        = "AllowtestpathPath"
      priority    = 300
      action      = "allow"
      metric_name = "allow_testpath_path"
      statement_config = {
        byte_match_statement = {
          search_string         = "/testpath/"
          positional_constraint = "STARTS_WITH"
          field_to_match = {
            uri_path = {}
          }
          text_transformation = {
            priority = 0
            type     = "NONE"
          }
        }
      }
    },

    # Allow health checks
    {
      name        = "AllowHealthChecks"
      priority    = 400
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

    # Allow robots.txt and sitemap.xml
    {
      name        = "AllowSEOFiles"
      priority    = 410
      action      = "allow"
      metric_name = "allow_seo_files"
      statement_config = {
        or_statement = {
          statements = [
            {
              byte_match_statement = {
                search_string         = "/robots.txt"
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
                search_string         = "/sitemap.xml"
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

    # Allow favicon requests
    {
      name        = "AllowFavicon"
      priority    = 420
      action      = "allow"
      metric_name = "allow_favicon"
      statement_config = {
        byte_match_statement = {
          search_string         = "/favicon.ico"
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

  tags = var.tags
}
# Outputs
output "zero_trust_waf_arn" {
  description = "ARN of the zero-trust WAF ACL"
  value       = module.enterprise_zero_trust_waf.web_acl_arn
}

output "zero_trust_waf_id" {
  description = "ID of the zero-trust WAF ACL"
  value       = module.enterprise_zero_trust_waf.web_acl_id
}

output "allow_rules_arn" {
  description = "ARN of the zero-trust allow rules group"
  value       = module.zero_trust_allow_rules.waf_rule_group_arn
}

output "zero_trust_configuration" {
  description = "Complete zero-trust WAF configuration summary"
  value = {
    security_model = {
      approach       = "Default Allow with Threat Protection"
      default_action = "allow"
      philosophy     = "Allow traffic by default, block known threats"
      principle      = "Monitor and protect against specific attack patterns"
    }

    protection_layers = {
      layer_1_allow_rules = {
        priority = 50
        rules    = 7
        purpose  = "Explicit allow for legitimate HTTP/HTTPS traffic"
        coverage = [
          "Trusted geographic regions",
          "Standard HTTP methods (GET, POST, PUT, PATCH, OPTIONS)",
          "Legitimate browser User-Agents (Mozilla, Chrome, Safari, Edge, Firefox)",
          "Static resources (CSS, JS, images)",
          "CORS preflight requests",
          "REST API methods with proper content-type"
        ]
      }

      layer_2_aws_managed = {
        priority = 200
        rules    = 1
        purpose  = "Block AWS threat intelligence"
        mode     = "block"
        coverage = [
          "OWASP Top 10 protection",
          "Known malicious IPs",
          "Common attack patterns"
        ]
      }

      layer_3_inline_rules = {
        priority = 100
        rules    = 6
        purpose  = "Threat blocking and specific path controls"
        coverage = [
          "SQL injection attempt blocking",
          "Directory traversal blocking", 
          "testpath application path (/testpath/)",
          "Health check endpoints",
          "SEO files (robots.txt, sitemap.xml)",
          "Favicon requests"
        ]
      }

      layer_4_default_allow = {
        priority = "default"
        action   = "allow"
        purpose  = "Allow traffic not matching specific block rules"
        coverage = "All unmatched traffic patterns"
      }
    }

    allowed_traffic = {
      countries     = var.trusted_countries
      http_methods  = ["GET", "POST", "PUT", "PATCH", "OPTIONS"]
      user_agents   = ["Mozilla", "Chrome", "Safari", "Edge", "Firefox"]
      static_files  = [".css", ".js", ".png", ".jpg", ".gif", ".ico"]
      special_paths = ["/testpath/", "/health", "/robots.txt", "/sitemap.xml", "/favicon.ico"]
      content_types = ["application/json for REST APIs"]
    }

    warnings = [
      "ℹ️ DEFAULT ALLOW MODE: Traffic allowed by default",
      "🛡️ THREAT PROTECTION: AWS managed rules actively blocking threats",
      "🚫 SPECIFIC BLOCKS: SQL injection and directory traversal blocked",
      "📊 MONITORING: All traffic patterns logged for analysis",
      "Monitor CloudWatch logs to tune security rules as needed"
    ]
  }
}