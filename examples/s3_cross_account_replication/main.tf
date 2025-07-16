# S3 Cross-Account Replication Example
# This example shows how to set up S3 replication between two AWS accounts with KMS encryption

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
      configuration_aliases = [aws.destination]
    }
  }
}

# Provider for source account (Account A)
provider "aws" {
  alias  = "source"
  region = var.source_region
  # Configure credentials for Account A
  # profile = "account-a"
}

# Provider for destination account (Account B)
provider "aws" {
  alias  = "destination"
  region = var.destination_region
  # Configure credentials for Account B
  # profile = "account-b"
}

# S3 Cross-Account Replication Module
module "s3_replication" {
  source = "../../modules/s3_cross_account_replication"
  
  providers = {
    aws             = aws.source
    aws.destination = aws.destination
  }

  # Source bucket configuration
  source_bucket_name = var.source_bucket_name
  
  # KMS configuration
  create_source_kms_key      = true
  create_destination_kms_key = true
  source_kms_key_id         = var.create_source_kms_key ? module.s3_replication.source_kms_key_id : var.existing_source_kms_key_id
  source_kms_key_arn        = var.create_source_kms_key ? module.s3_replication.source_kms_key_arn : var.existing_source_kms_key_arn
  destination_kms_key_arn   = var.create_destination_kms_key ? module.s3_replication.destination_kms_key_arn : var.existing_destination_kms_key_arn
  
  # Destination configuration
  create_destination_bucket = true
  destination_bucket_name   = var.destination_bucket_name
  destination_bucket_arn    = "arn:aws:s3:::${var.destination_bucket_name}"
  destination_account_id    = var.destination_account_id
  destination_storage_class = var.destination_storage_class
  destination_kms_key_id    = var.create_destination_kms_key ? module.s3_replication.destination_kms_key_id : var.existing_destination_kms_key_id
  
  # Replication settings
  replication_prefix = var.replication_prefix
  
  tags = var.tags
}