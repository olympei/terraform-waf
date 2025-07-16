output "source_bucket_id" {
  description = "ID of the source S3 bucket"
  value       = module.s3_replication.source_bucket_id
}

output "source_bucket_arn" {
  description = "ARN of the source S3 bucket"
  value       = module.s3_replication.source_bucket_arn
}

output "destination_bucket_id" {
  description = "ID of the destination S3 bucket"
  value       = module.s3_replication.destination_bucket_id
}

output "destination_bucket_arn" {
  description = "ARN of the destination S3 bucket"
  value       = module.s3_replication.destination_bucket_arn
}

output "replication_role_arn" {
  description = "ARN of the replication IAM role"
  value       = module.s3_replication.replication_role_arn
}

output "source_kms_key_id" {
  description = "ID of the source KMS key"
  value       = module.s3_replication.source_kms_key_id
}

output "destination_kms_key_id" {
  description = "ID of the destination KMS key"
  value       = module.s3_replication.destination_kms_key_id
}