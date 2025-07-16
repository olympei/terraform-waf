
locals {
  selected_rules = var.custom_rules
  selected_rules_template = var.use_templatefile_rendering ? var.custom_rules : []
}

resource "aws_wafv2_rule_group" "this" {
  #count    = var.use_rendered_rules ? 0 : 1
  count = var.use_templatefile_rendering ? 0 : 1
  name     = var.rule_group_name
  scope    = var.scope
  capacity = var.capacity

    dynamic "rule" {
    for_each = local.selected_rules
    content {
      name     = rule.value.name
      priority = rule.value.priority
      action {
        ${rule.value.action == "allow" ? "allow {}" : rule.value.action == "count" ? "count {}" : "block {}"}
      }
      statement {
        ${rule.value.statement != null ? rule.value.statement : join("", [
          rule.value.type == "sqli" ? <<-EOT
          sqli_match_statement {
            field_to_match {
              ${rule.value.field_to_match} {}
            }
            text_transformations {
              priority = 0
              type     = "NONE"
            }
          }
          EOT : "",

          rule.value.type == "xss" ? <<-EOT
          xss_match_statement {
            field_to_match {
              ${rule.value.field_to_match} {}
            }
            text_transformations {
              priority = 0
              type     = "NONE"
            }
          }
          EOT : "",

          rule.value.type == "ip_block" ? <<-EOT
          ip_set_reference_statement {
            arn = rule.value.ip_set_arn
          }
          EOT : "",

          rule.value.type == "regex" ? <<-EOT
          regex_pattern_set_reference_statement {
            arn = rule.value.regex_pattern_set
            field_to_match {
              ${rule.value.field_to_match} {}
            }
            text_transformations {
              priority = 0
              type     = "NONE"
            }
          }
          EOT : "",

          rule.value.type == "byte_match" ? <<-EOT
          byte_match_statement {
            search_string = rule.value.search_string
            field_to_match {
              ${rule.value.field_to_match} {}
            }
            positional_constraint = "CONTAINS"
            text_transformations {
              priority = 0
              type     = "NONE"
            }
          }
          EOT : ""
        ])}
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
        ${rule.value.action == "allow" ? "allow {}" : rule.value.action == "count" ? "count {}" : "block {}"}
      }

      statement = templatefile("${path.module}/templates/rule_statement.tftpl", {
        type              = lookup(rule.value, "type", null)
        field_to_match    = lookup(rule.value, "field_to_match", "body")
        search_string     = lookup(rule.value, "search_string", null)
        regex_pattern_set = lookup(rule.value, "regex_pattern_set", null)
        ip_set_arn        = lookup(rule.value, "ip_set_arn", null)
        statement         = lookup(rule.value, "statement", "")
      })

      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = rule.value.metric_name
        sampled_requests_enabled   = true
      }
    }
  }
}


/*
resource "local_file" "rendered_rule_group" {
  count    = var.use_rendered_rules ? 1 : 0
  content  = templatefile("${path.module}/templates/rules.tpl", {
    name         = var.rule_group_name,
    scope        = var.scope,
    capacity     = var.capacity,
    metric_name  = var.metric_name,
    rules        = var.custom_rules,
    tags         = var.tags
  })
  filename = "${path.module}/rendered_rules.tf"
}*/
