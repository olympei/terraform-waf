
##output "id" { value = aws_wafv2_rule_group.this[*].id }
##output "arn" { value = aws_wafv2_rule_group.this[*].arn }

output "waf_rule_group_arn" {
  value = var.use_templatefile_rendering ? aws_wafv2_rule_group.templated[0].arn : aws_wafv2_rule_group.this[0].arn
}
