locals {
  selected_rules = var.custom_rules
  selected_rules_template = var.use_templatefile_rendering ? var.custom_rules : []
  
  # Separate rules into type-based and custom statement rules
  type_based_rules = [
    for rule in local.selected_rules : rule
    if lookup(rule, "type", null) != null && lookup(rule, "statement_config", null) == null
  ]
  
  custom_statement_rules = [
    for rule in local.selected_rules : rule
    if lookup(rule, "statement_config", null) != null
  ]
  
  # Legacy statement rules (deprecated but still supported)
  legacy_statement_rules = [
    for rule in local.selected_rules : rule
    if lookup(rule, "statement", null) != null && lookup(rule, "statement_config", null) == null && lookup(rule, "type", null) == null
  ]
}

resource "aws_wafv2_rule_group" "this" {
  count    = var.use_templatefile_rendering ? 0 : 1
  name     = var.rule_group_name
  scope    = var.scope
  capacity = var.capacity

  lifecycle {
    create_before_destroy = true
    prevent_destroy       = false
  }

  # Type-based rules (generated from type field)
  dynamic "rule" {
    for_each = local.type_based_rules
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

      statement {
        # SQLi Match Statement
        dynamic "sqli_match_statement" {
          for_each = rule.value.type == "sqli" ? [1] : []
          content {
            field_to_match {
              dynamic "body" {
                for_each = lookup(rule.value, "field_to_match", "body") == "body" ? [1] : []
                content {}
              }
              dynamic "uri_path" {
                for_each = lookup(rule.value, "field_to_match", "body") == "uri_path" ? [1] : []
                content {}
              }
              dynamic "query_string" {
                for_each = lookup(rule.value, "field_to_match", "body") == "query_string" ? [1] : []
                content {}
              }
              dynamic "all_query_arguments" {
                for_each = lookup(rule.value, "field_to_match", "body") == "all_query_arguments" ? [1] : []
                content {}
              }
            }
            text_transformation {
              priority = 0
              type     = "NONE"
            }
          }
        }

        # XSS Match Statement
        dynamic "xss_match_statement" {
          for_each = rule.value.type == "xss" ? [1] : []
          content {
            field_to_match {
              dynamic "body" {
                for_each = lookup(rule.value, "field_to_match", "body") == "body" ? [1] : []
                content {}
              }
              dynamic "uri_path" {
                for_each = lookup(rule.value, "field_to_match", "body") == "uri_path" ? [1] : []
                content {}
              }
              dynamic "query_string" {
                for_each = lookup(rule.value, "field_to_match", "body") == "query_string" ? [1] : []
                content {}
              }
              dynamic "all_query_arguments" {
                for_each = lookup(rule.value, "field_to_match", "body") == "all_query_arguments" ? [1] : []
                content {}
              }
            }
            text_transformation {
              priority = 0
              type     = "NONE"
            }
          }
        }

        # IP Set Reference Statement
        dynamic "ip_set_reference_statement" {
          for_each = rule.value.type == "ip_block" ? [1] : []
          content {
            arn = lookup(rule.value, "ip_set_arn", "")
          }
        }

        # Regex Pattern Set Reference Statement
        dynamic "regex_pattern_set_reference_statement" {
          for_each = rule.value.type == "regex" ? [1] : []
          content {
            arn = lookup(rule.value, "regex_pattern_set", "")
            field_to_match {
              dynamic "body" {
                for_each = lookup(rule.value, "field_to_match", "body") == "body" ? [1] : []
                content {}
              }
              dynamic "uri_path" {
                for_each = lookup(rule.value, "field_to_match", "body") == "uri_path" ? [1] : []
                content {}
              }
              dynamic "query_string" {
                for_each = lookup(rule.value, "field_to_match", "body") == "query_string" ? [1] : []
                content {}
              }
              dynamic "all_query_arguments" {
                for_each = lookup(rule.value, "field_to_match", "body") == "all_query_arguments" ? [1] : []
                content {}
              }
            }
            text_transformation {
              priority = 0
              type     = "NONE"
            }
          }
        }

        # Byte Match Statement
        dynamic "byte_match_statement" {
          for_each = rule.value.type == "byte_match" ? [1] : []
          content {
            search_string = lookup(rule.value, "search_string", "")
            field_to_match {
              dynamic "body" {
                for_each = lookup(rule.value, "field_to_match", "body") == "body" ? [1] : []
                content {}
              }
              dynamic "uri_path" {
                for_each = lookup(rule.value, "field_to_match", "body") == "uri_path" ? [1] : []
                content {}
              }
              dynamic "query_string" {
                for_each = lookup(rule.value, "field_to_match", "body") == "query_string" ? [1] : []
                content {}
              }
              dynamic "all_query_arguments" {
                for_each = lookup(rule.value, "field_to_match", "body") == "all_query_arguments" ? [1] : []
                content {}
              }
            }
            positional_constraint = "CONTAINS"
            text_transformation {
              priority = 0
              type     = "NONE"
            }
          }
        }

        # Rate Based Statement (NEW)
        dynamic "rate_based_statement" {
          for_each = rule.value.type == "rate_based" ? [1] : []
          content {
            limit              = lookup(rule.value, "rate_limit", 2000)
            aggregate_key_type = lookup(rule.value, "aggregate_key_type", "IP")
          }
        }

        # Geo Match Statement (NEW)
        dynamic "geo_match_statement" {
          for_each = rule.value.type == "geo_match" ? [1] : []
          content {
            country_codes = lookup(rule.value, "country_codes", [])
          }
        }

        # Size Constraint Statement (NEW)
        dynamic "size_constraint_statement" {
          for_each = rule.value.type == "size_constraint" ? [1] : []
          content {
            comparison_operator = lookup(rule.value, "comparison_operator", "GT")
            size               = lookup(rule.value, "size", 8192)
            field_to_match {
              dynamic "body" {
                for_each = lookup(rule.value, "field_to_match", "body") == "body" ? [1] : []
                content {}
              }
              dynamic "uri_path" {
                for_each = lookup(rule.value, "field_to_match", "body") == "uri_path" ? [1] : []
                content {}
              }
              dynamic "query_string" {
                for_each = lookup(rule.value, "field_to_match", "body") == "query_string" ? [1] : []
                content {}
              }
              dynamic "all_query_arguments" {
                for_each = lookup(rule.value, "field_to_match", "body") == "all_query_arguments" ? [1] : []
                content {}
              }
            }
            text_transformation {
              priority = 0
              type     = "NONE"
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

  # Object-based statement rules (using statement_config object)
  dynamic "rule" {
    for_each = local.custom_statement_rules
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

      # Handle object-based statement configurations
      statement {
        # SQL Injection Match Statement
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

        # XSS Match Statement
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

        # IP Set Reference Statement
        dynamic "ip_set_reference_statement" {
          for_each = rule.value.statement_config != null && rule.value.statement_config.ip_set_reference_statement != null ? [rule.value.statement_config.ip_set_reference_statement] : []
          content {
            arn = ip_set_reference_statement.value.arn
          }
        }

        # Regex Pattern Set Reference Statement
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

        # Byte Match Statement
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

        # Rate Based Statement
        dynamic "rate_based_statement" {
          for_each = rule.value.statement_config != null && rule.value.statement_config.rate_based_statement != null ? [rule.value.statement_config.rate_based_statement] : []
          content {
            limit              = rate_based_statement.value.limit
            aggregate_key_type = rate_based_statement.value.aggregate_key_type
          }
        }

        # Geo Match Statement
        dynamic "geo_match_statement" {
          for_each = rule.value.statement_config != null && rule.value.statement_config.geo_match_statement != null ? [rule.value.statement_config.geo_match_statement] : []
          content {
            country_codes = geo_match_statement.value.country_codes
          }
        }

        # Size Constraint Statement
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

                # Nested OR Statement
                dynamic "or_statement" {
                  for_each = statement.value.or_statement != null ? [statement.value.or_statement] : []
                  content {
                    dynamic "statement" {
                      for_each = or_statement.value.statements
                      content {
                        # Nested Byte Match Statement within OR
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

      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = rule.value.metric_name
        sampled_requests_enabled   = true
      }
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = var.metric_name
    sampled_requests_enabled   = true
  }

  tags = var.tags
}

resource "aws_wafv2_rule_group" "templated" {
  count = var.use_templatefile_rendering ? 1 : 0

  name        = "${var.name}-templated"
  scope       = var.scope
  capacity    = 50
  description = "WAF Rule Group using template rendering"
  tags        = var.tags

  lifecycle {
    create_before_destroy = true
    prevent_destroy       = false
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.name}_templated"
    sampled_requests_enabled   = true
  }

  dynamic "rule" {
    for_each = local.selected_rules_template
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

      statement {
        # Use templatefile for statement generation
        dynamic "sqli_match_statement" {
          for_each = rule.value.statement == null && rule.value.type == "sqli" ? [1] : []
          content {
            field_to_match {
              dynamic "body" {
                for_each = lookup(rule.value, "field_to_match", "body") == "body" ? [1] : []
                content {}
              }
              dynamic "uri_path" {
                for_each = lookup(rule.value, "field_to_match", "body") == "uri_path" ? [1] : []
                content {}
              }
              dynamic "query_string" {
                for_each = lookup(rule.value, "field_to_match", "body") == "query_string" ? [1] : []
                content {}
              }
              dynamic "all_query_arguments" {
                for_each = lookup(rule.value, "field_to_match", "body") == "all_query_arguments" ? [1] : []
                content {}
              }
            }
            text_transformation {
              priority = 0
              type     = "NONE"
            }
          }
        }

        # Other statement types for templated rules...
        dynamic "xss_match_statement" {
          for_each = rule.value.statement == null && rule.value.type == "xss" ? [1] : []
          content {
            field_to_match {
              dynamic "body" {
                for_each = lookup(rule.value, "field_to_match", "body") == "body" ? [1] : []
                content {}
              }
              dynamic "uri_path" {
                for_each = lookup(rule.value, "field_to_match", "body") == "uri_path" ? [1] : []
                content {}
              }
              dynamic "query_string" {
                for_each = lookup(rule.value, "field_to_match", "body") == "query_string" ? [1] : []
                content {}
              }
              dynamic "all_query_arguments" {
                for_each = lookup(rule.value, "field_to_match", "body") == "all_query_arguments" ? [1] : []
                content {}
              }
            }
            text_transformation {
              priority = 0
              type     = "NONE"
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
}