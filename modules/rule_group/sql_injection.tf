variable "scope" {
  default = "REGIONAL"
}

resource "aws_wafv2_rule_group" "sql_injection" {
  name     = "sql-injection-rules"
  scope    = var.scope
  capacity = 50

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "SQLI"
    sampled_requests_enabled   = true
  }

  rule {
    name     = "BlockSQLi"
    priority = 1

    action {
      block {}
    }

    statement {
      sqli_match_statement {
        field_to_match {
          all_query_arguments {}
        }
        text_transformations {
          priority = 0
          type     = "URL_DECODE"
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "SQLiBlock"
      sampled_requests_enabled   = true
    }
  }
}