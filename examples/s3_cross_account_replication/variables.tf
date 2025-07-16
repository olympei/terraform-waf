variable "source_region" {
  description = "AWS region for source bucket"
  type        = string
  default     = "us-east-1"
}

variable "destination_region" {
  description = "AWS region for destination bucket"
  type        = string
  default     = "us-west-2"
}

variable "source_bucket_name" {
  description = "Name of the source S3 bucket"
  type        = string
}

variable "destination_bucket_name" {
  description = "Name of the destination S3 bucket"
  type        = string
}

variable "destination_account_id" {
  description = "AWS account ID of the destination account"
  type        = string
}

variable "destination_storage_class" {
  description = "Storage class for replicated objects"
  type        = string
  default     = "STANDARD_IA"
}

variable "replication_prefix" {
  description = "Object prefix to replicate (empty for all objects)"
  type        = string
  default     = ""
}

variable "create_source_kms_key" {
  description = "Whether to create a new KMS key for source bucket"
  type        = bool
  default     = true
}

variable "create_destination_kms_key" {
  description = "Whether to create a new KMS key for destination bucket"
  type        = bool
  default     = true
}

variable "existing_source_kms_key_id" {
  description = "Existing KMS key ID for source bucket (if not creating new)"
  type        = string
  default     = ""
}

variable "existing_source_kms_key_arn" {
  description = "Existing KMS key ARN for source bucket (if not creating new)"
  type        = string
  default     = ""
}

variable "existing_destination_kms_key_id" {
  description = "Existing KMS key ID for destination bucket (if not creating new)"
  type        = string
  default     = ""
}

variable "existing_destination_kms_key_arn" {
  description = "Existing KMS key ARN for destination bucket (if not creating new)"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    Environment = "production"
    Project     = "s3-replication"
    ManagedBy   = "terraform"
  }
}