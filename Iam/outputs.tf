output "wafv2_policy_arn" {
  description = "The ARN of the created WAFv2 IAM policy"
  value       = aws_iam_policy.wafv2_admin_policy.arn
}