output "source_bucket_id" {
  description = "ID of the source S3 bucket"
  value       = aws_s3_bucket.source.id
}

output "source_bucket_arn" {
  description = "ARN of the source S3 bucket"
  value       = aws_s3_bucket.source.arn
}

output "source_bucket_domain_name" {
  description = "Domain name of the source S3 bucket"
  value       = aws_s3_bucket.source.bucket_domain_name
}

output "replication_role_arn" {
  description = "ARN of the replication IAM role"
  value       = aws_iam_role.replication.arn
}

output "replication_configuration_id" {
  description = "ID of the replication configuration"
  value       = aws_s3_bucket_replication_configuration.replication.id
}

output "destination_bucket_id" {
  description = "ID of the destination S3 bucket"
  value       = var.create_destination_bucket ? aws_s3_bucket.destination[0].id : null
}

output "destination_bucket_arn" {
  description = "ARN of the destination S3 bucket"
  value       = var.create_destination_bucket ? aws_s3_bucket.destination[0].arn : var.destination_bucket_arn
}

output "source_kms_key_id" {
  description = "ID of the source KMS key"
  value       = var.create_source_kms_key ? aws_kms_key.source[0].key_id : null
}

output "source_kms_key_arn" {
  description = "ARN of the source KMS key"
  value       = var.create_source_kms_key ? aws_kms_key.source[0].arn : null
}

output "destination_kms_key_id" {
  description = "ID of the destination KMS key"
  value       = var.create_destination_kms_key ? aws_kms_key.destination[0].key_id : null
}

output "destination_kms_key_arn" {
  description = "ARN of the destination KMS key"
  value       = var.create_destination_kms_key ? aws_kms_key.destination[0].arn : null
}