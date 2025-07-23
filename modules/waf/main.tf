resource "aws_kms_key" "this" {
  count               = var.kms_key_id == null && var.create_log_group ? 1 : 0
  description         = "KMS key for encrypting WAF logs"
  enable_key_rotation = true
  tags                = var.tags
}

resource "aws_cloudwatch_log_group" "this" {
  count             = var.create_log_group ? 1 : 0
  name              = var.log_group_name != null ? var.log_group_name : "/aws/wafv2/${var.name}"
  retention_in_days = var.log_group_retention_in_days
  kms_key_id        = var.kms_key_id != null ? var.kms_key_id : aws_kms_key.this[0].arn
  tags              = var.tags
}

# Local: Combined priorities for validation
locals {
  inline_priorities      = [for r in var.custom_inline_rules : r.priority]
  rulegroup_priorities   = [for i, r in var.rule_group_arn_list : coalesce(r.priority, 100 + i)]
  aws_managed_priorities = [for r in var.aws_managed_rule_groups : r.priority]
  all_waf_priorities     = concat(local.inline_priorities, local.rulegroup_priorities, local.aws_managed_priorities)
  
  # Priority validation
  unique_priorities      = distinct(local.all_waf_priorities)
  has_duplicate_priorities = length(local.all_waf_priorities) != length(local.unique_priorities)
}

# Priority validation check
resource "null_resource" "priority_validation" {
  count = var.validate_priorities ? 1 : 0
  
  lifecycle {
    precondition {
      condition     = !local.has_duplicate_priorities
      error_message = "Duplicate priorities detected across WAF rules. All priorities must be unique. Found priorities: ${join(", ", local.all_waf_priorities)}"
    }
  }
}

resource "aws_wafv2_web_acl" "this" {
  name  = var.name
  scope = var.scope

  default_action {
    dynamic "allow" {
      for_each = var.default_action == "allow" ? [1] : []
      content {}
    }
    dynamic "block" {
      for_each = var.default_action == "block" ? [1] : []
      content {}
    }
  }

 dynamic "rule" {
    for_each = var.rule_group_arn_list
    content {
      name     = lookup(rule.value, "name", "group-${rule.key}")
      priority = lookup(rule.value, "priority", 100 + rule.key)
      override_action {
        none {}
      }
      statement {
        rule_group_reference_statement {
          arn = rule.value.arn
        }
      }
      visibility_config {
        cloudwatch_metrics_enabled = true
        sampled_requests_enabled   = true
        metric_name                = lookup(rule.value, "name", "group-${rule.key}")
      }
    }
  }

   dynamic "rule" {
    for_each = var.custom_inline_rules
    content {
      name     = rule.value.name
      priority = rule.value.priority
      action {
        dynamic "allow" {
          for_each = rule.value.action == "allow" ? [1] : []
          content {}
        }
        dynamic "block" {
          for_each = rule.value.action == "block" ? [1] : []
          content {}
        }
        dynamic "count" {
          for_each = rule.value.action == "count" ? [1] : []
          content {}
        }
      }
      
      # Handle both legacy string statements and new object-based statements
      dynamic "statement" {
        for_each = (
          rule.value.statement != null ||
          (rule.value.statement_config != null && (
            rule.value.statement_config.sqli_match_statement != null ||
            rule.value.statement_config.xss_match_statement != null ||
            rule.value.statement_config.ip_set_reference_statement != null ||
            rule.value.statement_config.regex_pattern_set_reference_statement != null ||
            rule.value.statement_config.byte_match_statement != null ||
            rule.value.statement_config.rate_based_statement != null ||
            rule.value.statement_config.geo_match_statement != null ||
            rule.value.statement_config.size_constraint_statement != null ||
            rule.value.statement_config.and_statement != null ||
            rule.value.statement_config.or_statement != null
          ))
        ) ? [1] : []
        content {
          # Legacy string statement (deprecated but supported)
          dynamic "sqli_match_statement" {
            for_each = try(rule.value.statement != null && contains(rule.value.statement, "sqli_match_statement"), false) ? [1] : []
            content {
              # This is a simplified fallback for legacy string statements
              field_to_match {
                body {}
              }
              text_transformation {
                priority = 0
                type     = "NONE"
              }
            }
          }
          
          # New object-based statements
          dynamic "sqli_match_statement" {
            for_each = rule.value.statement_config != null && rule.value.statement_config.sqli_match_statement != null ? [rule.value.statement_config.sqli_match_statement] : []
            content {
              field_to_match {
                dynamic "body" {
                  for_each = sqli_match_statement.value.field_to_match.body != null ? [1] : []
                  content {}
                }
                dynamic "uri_path" {
                  for_each = sqli_match_statement.value.field_to_match.uri_path != null ? [1] : []
                  content {}
                }
                dynamic "query_string" {
                  for_each = sqli_match_statement.value.field_to_match.query_string != null ? [1] : []
                  content {}
                }
                dynamic "all_query_arguments" {
                  for_each = sqli_match_statement.value.field_to_match.all_query_arguments != null ? [1] : []
                  content {}
                }
                dynamic "single_header" {
                  for_each = sqli_match_statement.value.field_to_match.single_header != null ? [sqli_match_statement.value.field_to_match.single_header] : []
                  content {
                    name = single_header.value.name
                  }
                }
                dynamic "method" {
                  for_each = sqli_match_statement.value.field_to_match.method != null ? [1] : []
                  content {}
                }
              }
              text_transformation {
                priority = sqli_match_statement.value.text_transformation.priority
                type     = sqli_match_statement.value.text_transformation.type
              }
            }
          }
          
          dynamic "xss_match_statement" {
            for_each = rule.value.statement_config != null && rule.value.statement_config.xss_match_statement != null ? [rule.value.statement_config.xss_match_statement] : []
            content {
              field_to_match {
                dynamic "body" {
                  for_each = xss_match_statement.value.field_to_match.body != null ? [1] : []
                  content {}
                }
                dynamic "uri_path" {
                  for_each = xss_match_statement.value.field_to_match.uri_path != null ? [1] : []
                  content {}
                }
                dynamic "query_string" {
                  for_each = xss_match_statement.value.field_to_match.query_string != null ? [1] : []
                  content {}
                }
                dynamic "all_query_arguments" {
                  for_each = xss_match_statement.value.field_to_match.all_query_arguments != null ? [1] : []
                  content {}
                }
                dynamic "single_header" {
                  for_each = xss_match_statement.value.field_to_match.single_header != null ? [xss_match_statement.value.field_to_match.single_header] : []
                  content {
                    name = single_header.value.name
                  }
                }
                dynamic "method" {
                  for_each = xss_match_statement.value.field_to_match.method != null ? [1] : []
                  content {}
                }
              }
              text_transformation {
                priority = xss_match_statement.value.text_transformation.priority
                type     = xss_match_statement.value.text_transformation.type
              }
            }
          }
          
          dynamic "ip_set_reference_statement" {
            for_each = rule.value.statement_config != null && rule.value.statement_config.ip_set_reference_statement != null ? [rule.value.statement_config.ip_set_reference_statement] : []
            content {
              arn = ip_set_reference_statement.value.arn
            }
          }
          
          dynamic "regex_pattern_set_reference_statement" {
            for_each = rule.value.statement_config != null && rule.value.statement_config.regex_pattern_set_reference_statement != null ? [rule.value.statement_config.regex_pattern_set_reference_statement] : []
            content {
              arn = regex_pattern_set_reference_statement.value.arn
              field_to_match {
                dynamic "body" {
                  for_each = regex_pattern_set_reference_statement.value.field_to_match.body != null ? [1] : []
                  content {}
                }
                dynamic "uri_path" {
                  for_each = regex_pattern_set_reference_statement.value.field_to_match.uri_path != null ? [1] : []
                  content {}
                }
                dynamic "query_string" {
                  for_each = regex_pattern_set_reference_statement.value.field_to_match.query_string != null ? [1] : []
                  content {}
                }
                dynamic "all_query_arguments" {
                  for_each = regex_pattern_set_reference_statement.value.field_to_match.all_query_arguments != null ? [1] : []
                  content {}
                }
                dynamic "single_header" {
                  for_each = regex_pattern_set_reference_statement.value.field_to_match.single_header != null ? [regex_pattern_set_reference_statement.value.field_to_match.single_header] : []
                  content {
                    name = single_header.value.name
                  }
                }
                dynamic "method" {
                  for_each = regex_pattern_set_reference_statement.value.field_to_match.method != null ? [1] : []
                  content {}
                }
              }
              text_transformation {
                priority = regex_pattern_set_reference_statement.value.text_transformation.priority
                type     = regex_pattern_set_reference_statement.value.text_transformation.type
              }
            }
          }
          
          dynamic "byte_match_statement" {
            for_each = rule.value.statement_config != null && rule.value.statement_config.byte_match_statement != null ? [rule.value.statement_config.byte_match_statement] : []
            content {
              search_string = byte_match_statement.value.search_string
              positional_constraint = byte_match_statement.value.positional_constraint
              field_to_match {
                dynamic "body" {
                  for_each = byte_match_statement.value.field_to_match.body != null ? [1] : []
                  content {}
                }
                dynamic "uri_path" {
                  for_each = byte_match_statement.value.field_to_match.uri_path != null ? [1] : []
                  content {}
                }
                dynamic "query_string" {
                  for_each = byte_match_statement.value.field_to_match.query_string != null ? [1] : []
                  content {}
                }
                dynamic "all_query_arguments" {
                  for_each = byte_match_statement.value.field_to_match.all_query_arguments != null ? [1] : []
                  content {}
                }
                dynamic "single_header" {
                  for_each = byte_match_statement.value.field_to_match.single_header != null ? [byte_match_statement.value.field_to_match.single_header] : []
                  content {
                    name = single_header.value.name
                  }
                }
                dynamic "method" {
                  for_each = byte_match_statement.value.field_to_match.method != null ? [1] : []
                  content {}
                }
              }
              text_transformation {
                priority = byte_match_statement.value.text_transformation.priority
                type     = byte_match_statement.value.text_transformation.type
              }
            }
          }
          
          dynamic "rate_based_statement" {
            for_each = rule.value.statement_config != null && rule.value.statement_config.rate_based_statement != null ? [rule.value.statement_config.rate_based_statement] : []
            content {
              limit              = rate_based_statement.value.limit
              aggregate_key_type = rate_based_statement.value.aggregate_key_type
            }
          }
          
          dynamic "geo_match_statement" {
            for_each = rule.value.statement_config != null && rule.value.statement_config.geo_match_statement != null ? [rule.value.statement_config.geo_match_statement] : []
            content {
              country_codes = geo_match_statement.value.country_codes
            }
          }
          
          dynamic "size_constraint_statement" {
            for_each = rule.value.statement_config != null && rule.value.statement_config.size_constraint_statement != null ? [rule.value.statement_config.size_constraint_statement] : []
            content {
              comparison_operator = size_constraint_statement.value.comparison_operator
              size               = size_constraint_statement.value.size
              field_to_match {
                dynamic "body" {
                  for_each = size_constraint_statement.value.field_to_match.body != null ? [1] : []
                  content {}
                }
                dynamic "uri_path" {
                  for_each = size_constraint_statement.value.field_to_match.uri_path != null ? [1] : []
                  content {}
                }
                dynamic "query_string" {
                  for_each = size_constraint_statement.value.field_to_match.query_string != null ? [1] : []
                  content {}
                }
                dynamic "all_query_arguments" {
                  for_each = size_constraint_statement.value.field_to_match.all_query_arguments != null ? [1] : []
                  content {}
                }
                dynamic "single_header" {
                  for_each = size_constraint_statement.value.field_to_match.single_header != null ? [size_constraint_statement.value.field_to_match.single_header] : []
                  content {
                    name = single_header.value.name
                  }
                }
                dynamic "method" {
                  for_each = size_constraint_statement.value.field_to_match.method != null ? [1] : []
                  content {}
                }
              }
              text_transformation {
                priority = size_constraint_statement.value.text_transformation.priority
                type     = size_constraint_statement.value.text_transformation.type
              }
            }
          }

          # AND Statement (for combining multiple conditions)
          dynamic "and_statement" {
            for_each = rule.value.statement_config != null && rule.value.statement_config.and_statement != null ? [rule.value.statement_config.and_statement] : []
            content {
              dynamic "statement" {
                for_each = and_statement.value.statements
                content {
                  # Nested Geo Match Statement
                  dynamic "geo_match_statement" {
                    for_each = statement.value.geo_match_statement != null ? [statement.value.geo_match_statement] : []
                    content {
                      country_codes = geo_match_statement.value.country_codes
                    }
                  }

                  # Nested Byte Match Statement
                  dynamic "byte_match_statement" {
                    for_each = statement.value.byte_match_statement != null ? [statement.value.byte_match_statement] : []
                    content {
                      search_string = byte_match_statement.value.search_string
                      positional_constraint = byte_match_statement.value.positional_constraint
                      field_to_match {
                        dynamic "body" {
                          for_each = byte_match_statement.value.field_to_match.body != null ? [1] : []
                          content {}
                        }
                        dynamic "uri_path" {
                          for_each = byte_match_statement.value.field_to_match.uri_path != null ? [1] : []
                          content {}
                        }
                        dynamic "query_string" {
                          for_each = byte_match_statement.value.field_to_match.query_string != null ? [1] : []
                          content {}
                        }
                        dynamic "all_query_arguments" {
                          for_each = byte_match_statement.value.field_to_match.all_query_arguments != null ? [1] : []
                          content {}
                        }
                        dynamic "single_header" {
                          for_each = byte_match_statement.value.field_to_match.single_header != null ? [byte_match_statement.value.field_to_match.single_header] : []
                          content {
                            name = single_header.value.name
                          }
                        }
                        dynamic "method" {
                          for_each = byte_match_statement.value.field_to_match.method != null ? [1] : []
                          content {}
                        }
                      }
                      text_transformation {
                        priority = byte_match_statement.value.text_transformation.priority
                        type     = byte_match_statement.value.text_transformation.type
                      }
                    }
                  }
                }
              }
            }
          }

          # OR Statement (for alternative conditions)
          dynamic "or_statement" {
            for_each = rule.value.statement_config != null && rule.value.statement_config.or_statement != null ? [rule.value.statement_config.or_statement] : []
            content {
              dynamic "statement" {
                for_each = or_statement.value.statements
                content {
                  # Nested Byte Match Statement
                  dynamic "byte_match_statement" {
                    for_each = statement.value.byte_match_statement != null ? [statement.value.byte_match_statement] : []
                    content {
                      search_string = byte_match_statement.value.search_string
                      positional_constraint = byte_match_statement.value.positional_constraint
                      field_to_match {
                        dynamic "body" {
                          for_each = byte_match_statement.value.field_to_match.body != null ? [1] : []
                          content {}
                        }
                        dynamic "uri_path" {
                          for_each = byte_match_statement.value.field_to_match.uri_path != null ? [1] : []
                          content {}
                        }
                        dynamic "query_string" {
                          for_each = byte_match_statement.value.field_to_match.query_string != null ? [1] : []
                          content {}
                        }
                        dynamic "all_query_arguments" {
                          for_each = byte_match_statement.value.field_to_match.all_query_arguments != null ? [1] : []
                          content {}
                        }
                        dynamic "single_header" {
                          for_each = byte_match_statement.value.field_to_match.single_header != null ? [byte_match_statement.value.field_to_match.single_header] : []
                          content {
                            name = single_header.value.name
                          }
                        }
                        dynamic "method" {
                          for_each = byte_match_statement.value.field_to_match.method != null ? [1] : []
                          content {}
                        }
                      }
                      text_transformation {
                        priority = byte_match_statement.value.text_transformation.priority
                        type     = byte_match_statement.value.text_transformation.type
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
      
      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = rule.value.metric_name
        sampled_requests_enabled   = true
      }
    }
  }

   dynamic "rule" {
    for_each = var.aws_managed_rule_groups
    content {
      name     = "AWSManaged-${rule.value.name}"
      priority = rule.value.priority

      override_action {
        dynamic "count" {
          for_each = rule.value.override_action == "count" ? [1] : []
          content {}
        }
        dynamic "none" {
          for_each = rule.value.override_action == "none" ? [1] : []
          content {}
        }
      }

      statement {
        managed_rule_group_statement {
          name        = rule.value.name
          vendor_name = rule.value.vendor_name
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = "AWSManaged-${rule.value.name}"
        sampled_requests_enabled   = true
      }
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = var.name
    sampled_requests_enabled   = true
  }

  tags = var.tags
}

resource "aws_wafv2_web_acl_logging_configuration" "this" {
  count = var.create_log_group || var.existing_log_group_arn != null ? 1 : 0

  resource_arn = aws_wafv2_web_acl.this.arn

  log_destination_configs = var.create_log_group ? [aws_cloudwatch_log_group.this[0].arn] : [var.existing_log_group_arn]

  depends_on = [aws_wafv2_web_acl.this]
}


resource "aws_wafv2_web_acl_association" "this" {
  for_each     = toset(var.alb_arn_list)
  resource_arn = each.value
  web_acl_arn  = aws_wafv2_web_acl.this.arn
}
