
output "web_acl_id" { value = aws_wafv2_web_acl.this.id }
output "web_acl_arn" { value = aws_wafv2_web_acl.this.arn }

# CloudWatch Log Group outputs
output "cloudwatch_log_group_name" {
  description = "Name of the CloudWatch log group (created or existing)"
  value = var.create_log_group ? aws_cloudwatch_log_group.this[0].name : (
    var.existing_log_group_arn != null ? split(":", var.existing_log_group_arn)[6] : null
  )
}

output "cloudwatch_log_group_arn" {
  description = "ARN of the CloudWatch log group (created or existing)"
  value = var.create_log_group ? aws_cloudwatch_log_group.this[0].arn : var.existing_log_group_arn
}

# KMS Key outputs
output "kms_key_id" {
  description = "ID of the KMS key used for log encryption (provided or created)"
  value = var.kms_key_id != null ? var.kms_key_id : (
    var.create_log_group ? aws_kms_key.this[0].key_id : null
  )
}

output "kms_key_arn" {
  description = "ARN of the KMS key used for log encryption (provided or created)"
  value = var.kms_key_id != null ? var.kms_key_id : (
    var.create_log_group ? aws_kms_key.this[0].arn : null
  )
}
