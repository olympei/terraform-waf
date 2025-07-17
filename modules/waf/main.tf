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
      statement = rule.value.statement
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
