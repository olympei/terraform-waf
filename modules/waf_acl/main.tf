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

resource "aws_wafv2_web_acl" "this" {
  name  = var.name
  scope = var.scope

  default_action {
    ${var.default_action == "allow" ? "allow {}" : "block {}"}
  }

  dynamic "rule" {
    for_each = var.rule_group_arn_list
    content {
      name     = "group-${index(var.rule_group_arn_list, rule.value)}"
      priority = 10 + index(var.rule_group_arn_list, rule.value)
      override_action { none {} }
      statement {
        rule_group_reference_statement { arn = rule.value }
      }
      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = "group-${index(var.rule_group_arn_list, rule.value)}"
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
}

resource "aws_wafv2_web_acl_association" "this" {
  for_each     = toset(var.alb_arn_list)
  resource_arn = each.value
  web_acl_arn  = aws_wafv2_web_acl.this.arn
}
