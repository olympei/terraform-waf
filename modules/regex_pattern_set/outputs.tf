output "arn" {
  description = "ARN of the regex pattern set"
  value       = aws_wafv2_regex_pattern_set.this.arn
}

output "id" {
  description = "ID of the regex pattern set"
  value       = aws_wafv2_regex_pattern_set.this.id
}

output "name" {
  description = "Name of the regex pattern set"
  value       = aws_wafv2_regex_pattern_set.this.name
}