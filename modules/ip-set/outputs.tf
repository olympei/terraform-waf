output "arn" {
  description = "ARN of the IP set"
  value       = aws_wafv2_ip_set.this.arn
}

output "id" {
  description = "ID of the IP set"
  value       = aws_wafv2_ip_set.this.id
}

output "name" {
  description = "Name of the IP set"
  value       = aws_wafv2_ip_set.this.name
}