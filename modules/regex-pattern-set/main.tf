resource "aws_wafv2_regex_pattern_set" "this" {
  name  = var.name
  scope = var.scope

  dynamic "regular_expression" {
    for_each = var.regex_strings
    content {
      regex_string = regular_expression.value
    }
  }

  description = "Managed regex pattern set"
  tags        = var.tags
}