
##output "id" { value = aws_wafv2_rule_group.this[*].id }
##output "arn" { value = aws_wafv2_rule_group.this[*].arn }

output "waf_rule_group_arn" {
  description = "ARN of the WAF rule group"
  value = var.use_templatefile_rendering ? aws_wafv2_rule_group.templated[0].arn : aws_wafv2_rule_group.this[0].arn
}

output "waf_rule_group_name" {
  description = "Name of the WAF rule group"
  value = var.use_templatefile_rendering ? aws_wafv2_rule_group.templated[0].name : aws_wafv2_rule_group.this[0].name
}

output "waf_rule_group_id" {
  description = "ID of the WAF rule group"
  value = var.use_templatefile_rendering ? aws_wafv2_rule_group.templated[0].id : aws_wafv2_rule_group.this[0].id
}

output "waf_rule_group_capacity" {
  description = "Capacity of the WAF rule group"
  value = var.use_templatefile_rendering ? aws_wafv2_rule_group.templated[0].capacity : aws_wafv2_rule_group.this[0].capacity
}
