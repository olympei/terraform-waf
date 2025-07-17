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
      }

      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = rule.value.metric_name
        sampled_requests_enabled   = true
      }
    }
  }

  # Custom statement rules (using statement_config object)
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

      # Handle custom statement configurations
      statement {
        # SQLi Match Statement from statement_config
        dynamic "sqli_match_statement" {
          for_each = lookup(rule.value, "statement_config", null) != null && lookup(rule.value.statement_config, "type", "") == "sqli" ? [1] : []
          content {
            field_to_match {
              dynamic "body" {
                for_each = lookup(rule.value.statement_config, "field_to_match", "body") == "body" ? [1] : []
                content {}
              }
              dynamic "uri_path" {
                for_each = lookup(rule.value.statement_config, "field_to_match", "body") == "uri_path" ? [1] : []
                content {}
              }
              dynamic "query_string" {
                for_each = lookup(rule.value.statement_config, "field_to_match", "body") == "query_string" ? [1] : []
                content {}
              }
              dynamic "all_query_arguments" {
                for_each = lookup(rule.value.statement_config, "field_to_match", "body") == "all_query_arguments" ? [1] : []
                content {}
              }
            }
            text_transformation {
              priority = lookup(rule.value.statement_config, "text_transformation_priority", 0)
              type     = lookup(rule.value.statement_config, "text_transformation_type", "NONE")
            }
          }
        }

        # XSS Match Statement from statement_config
        dynamic "xss_match_statement" {
          for_each = lookup(rule.value, "statement_config", null) != null && lookup(rule.value.statement_config, "type", "") == "xss" ? [1] : []
          content {
            field_to_match {
              dynamic "body" {
                for_each = lookup(rule.value.statement_config, "field_to_match", "body") == "body" ? [1] : []
                content {}
              }
              dynamic "uri_path" {
                for_each = lookup(rule.value.statement_config, "field_to_match", "body") == "uri_path" ? [1] : []
                content {}
              }
              dynamic "query_string" {
                for_each = lookup(rule.value.statement_config, "field_to_match", "body") == "query_string" ? [1] : []
                content {}
              }
              dynamic "all_query_arguments" {
                for_each = lookup(rule.value.statement_config, "field_to_match", "body") == "all_query_arguments" ? [1] : []
                content {}
              }
            }
            text_transformation {
              priority = lookup(rule.value.statement_config, "text_transformation_priority", 0)
              type     = lookup(rule.value.statement_config, "text_transformation_type", "NONE")
            }
          }
        }

        # Rate Based Statement from statement_config
        dynamic "rate_based_statement" {
          for_each = lookup(rule.value, "statement_config", null) != null && lookup(rule.value.statement_config, "type", "") == "rate_based" ? [1] : []
          content {
            limit              = lookup(rule.value.statement_config, "rate_limit", 2000)
            aggregate_key_type = lookup(rule.value.statement_config, "aggregate_key_type", "IP")
          }
        }

        # Geo Match Statement from statement_config
        dynamic "geo_match_statement" {
          for_each = lookup(rule.value, "statement_config", null) != null && lookup(rule.value.statement_config, "type", "") == "geo_match" ? [1] : []
          content {
            country_codes = lookup(rule.value.statement_config, "country_codes", [])
          }
        }

        # Size Constraint Statement from statement_config
        dynamic "size_constraint_statement" {
          for_each = lookup(rule.value, "statement_config", null) != null && lookup(rule.value.statement_config, "type", "") == "size_constraint" ? [1] : []
          content {
            comparison_operator = lookup(rule.value.statement_config, "comparison_operator", "GT")
            size                = lookup(rule.value.statement_config, "size", 8192)
            field_to_match {
              dynamic "body" {
                for_each = lookup(rule.value.statement_config, "field_to_match", "body") == "body" ? [1] : []
                content {}
              }
              dynamic "uri_path" {
                for_each = lookup(rule.value.statement_config, "field_to_match", "body") == "uri_path" ? [1] : []
                content {}
              }
              dynamic "query_string" {
                for_each = lookup(rule.value.statement_config, "field_to_match", "body") == "query_string" ? [1] : []
                content {}
              }
            }
            text_transformation {
              priority = lookup(rule.value.statement_config, "text_transformation_priority", 0)
              type     = lookup(rule.value.statement_config, "text_transformation_type", "NONE")
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