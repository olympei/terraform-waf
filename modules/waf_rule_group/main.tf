
resource "aws_wafv2_rule_group" "this" {
  count    = var.use_rendered_rules ? 0 : 1
  name     = var.rule_group_name
  scope    = var.scope
  capacity = var.capacity

  dynamic "rule" {
    for_each = var.custom_rules
    content {
      name     = rule.value.name
      priority = rule.value.priority
      action {
        ${rule.value.action} {}
      }
      statement {
        ${rule.value.statement}
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
}
