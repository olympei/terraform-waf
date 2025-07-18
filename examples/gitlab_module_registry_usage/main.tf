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
  region = "us-east-1"
}

# Variables for demonstration
variable "blocked_countries" {
  description = "List of country codes to block"
  type        = list(string)
  default     = ["CN", "RU", "KP"]
}

variable "allowed_user_agents" {
  description = "List of allowed user agent patterns"
  type        = list(string)
  default     = ["Mozilla", "Chrome", "Safari", "Edge", "Firefox"]
}

# Example using GitLab module registry (hypothetical)
# In a real scenario, these would be published to a GitLab module registry

# WAF Module
module "waf" {
  # In real usage, this would be from GitLab module registry:
  # source = "git::https://gitlab.com/your-namespace/terraform-waf-modules.git//modules/waf?ref=v1.0.0"

  # For this example, using local modules
  source = "../../modules/waf"

  name                    = "gitlab-registry-waf"
  scope                   = "REGIONAL"
  default_action          = "allow"
  aws_managed_rule_groups = []
  rule_group_arn_list = [
    {
      arn      = module.waf_rule_group.waf_rule_group_arn
      name     = "custom-rule-group"
      priority = 100
    }
  ]
  custom_inline_rules = []
  alb_arn_list        = []

  tags = {
    Environment = "dev"
    Source      = "GitLab Module Registry"
  }
}

# WAF Rule Group Module - Using Regex Pattern Set and IP Set
module "waf_rule_group" {
  # In real usage, this would be from GitLab module registry:
  # source = "git::https://gitlab.com/your-namespace/terraform-waf-modules.git//modules/waf-rule-group?ref=v1.0.0"

  # For this example, using local modules
  source = "../../modules/waf-rule-group"

  rule_group_name = "gitlab-registry-rule-group"
  name            = "gitlab-registry-rule-group"
  scope           = "REGIONAL"
  capacity        = 200
  metric_name     = "GitLabRuleGroup"

  # Advanced rules using statement_config with regex patterns and IP sets
  custom_rules = [
    # Rule 1: Block SQL Injection using Regex Pattern Set
    {
      name        = "BlockSQLiWithRegex"
      priority    = 10
      action      = "block"
      metric_name = "block_sqli_regex"
      statement_config = {
        regex_pattern_set_reference_statement = {
          arn = module.regex_pattern_set.arn
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

    # Rule 2: Block malicious IPs using IP Set
    {
      name        = "BlockMaliciousIPs"
      priority    = 20
      action      = "block"
      metric_name = "block_malicious_ips"
      statement_config = {
        ip_set_reference_statement = {
          arn = module.ip_set.arn
        }
      }
    },

    # Rule 3: Block specific countries
    {
      name        = "BlockRestrictedCountries"
      priority    = 30
      action      = "block"
      metric_name = "block_restricted_countries"
      statement_config = {
        geo_match_statement = {
          country_codes = var.blocked_countries
        }
      }
    },

    # Rule 4: Allow legitimate user agents (combined with other conditions)
    {
      name        = "AllowLegitimateTraffic"
      priority    = 40
      action      = "allow"
      metric_name = "allow_legitimate_traffic"
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
                  }
                ]
              }
            },
            {
              not_statement = {
                statement = {
                  ip_set_reference_statement = {
                    arn = module.ip_set.arn
                  }
                }
              }
            }
          ]
        }
      }
    },

    # Rule 5: Advanced SQL injection detection with multiple transformations
    {
      name        = "AdvancedSQLiDetection"
      priority    = 50
      action      = "block"
      metric_name = "advanced_sqli_detection"
      statement_config = {
        or_statement = {
          statements = [
            {
              regex_pattern_set_reference_statement = {
                arn = module.regex_pattern_set.arn
                field_to_match = {
                  query_string = {}
                }
                text_transformation = {
                  priority = 1
                  type     = "URL_DECODE"
                }
              }
            },
            {
              regex_pattern_set_reference_statement = {
                arn = module.regex_pattern_set.arn
                field_to_match = {
                  uri_path = {}
                }
                text_transformation = {
                  priority = 1
                  type     = "HTML_ENTITY_DECODE"
                }
              }
            }
          ]
        }
      }
    }
  ]

  tags = {
    Environment = "dev"
    Source      = "GitLab Module Registry"
    Integration = "regex-pattern-set-ip-set"
  }
}

# Regex Pattern Set Module
module "regex_pattern_set" {
  # In real usage, this would be from GitLab module registry:
  # source = "git::https://gitlab.com/your-namespace/terraform-waf-modules.git//modules/regex-pattern-set?ref=v1.0.0"

  # For this example, using local modules
  source = "../../modules/regex-pattern-set"

  name          = "gitlab-regex-patterns"
  scope         = "REGIONAL"
  regex_strings = ["(?i)select.*from", "(?i)union.*select", "(?i)drop.*table"]

  tags = {
    Environment = "dev"
    Source      = "GitLab Module Registry"
  }
}

# IP Set Module
module "ip_set" {
  # In real usage, this would be from GitLab module registry:
  # source = "git::https://gitlab.com/your-namespace/terraform-waf-modules.git//modules/ip-set?ref=v1.0.0"

  # For this example, using local modules
  source = "../../modules/ip-set"

  name               = "gitlab-blocked-ips"
  scope              = "REGIONAL"
  ip_address_version = "IPV4"
  addresses          = ["192.0.2.0/24", "198.51.100.0/24", "203.0.113.0/24"]

  tags = {
    Environment = "dev"
    Source      = "GitLab Module Registry"
  }
}

# Outputs
output "waf_arn" {
  description = "ARN of the WAF Web ACL"
  value       = module.waf.web_acl_arn
}

output "waf_rule_group_arn" {
  description = "ARN of the WAF Rule Group"
  value       = module.waf_rule_group.waf_rule_group_arn
}

output "regex_pattern_set_arn" {
  description = "ARN of the Regex Pattern Set"
  value       = module.regex_pattern_set.arn
}

output "ip_set_arn" {
  description = "ARN of the IP Set"
  value       = module.ip_set.arn
}