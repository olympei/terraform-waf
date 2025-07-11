
resource "aws_wafv2_rule_group" "rendered" {
  name        = "${name}"
  scope       = "${scope}"
  capacity    = ${capacity}

  %{ for rule in rules }
  rule {
    name     = "${rule.name}"
    priority = ${rule.priority}
    action {
      ${rule.action} {}
    }
    statement {
      ${rule.statement}
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${rule.metric_name}"
      sampled_requests_enabled   = true
    }
  }
  %{ endfor %}

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${metric_name}"
    sampled_requests_enabled   = true
  }

  tags = ${tags}
}
