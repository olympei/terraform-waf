variable "source_bucket_name" {
  description = "Name of the source S3 bucket"
  type        = string
}

variable "source_kms_key_id" {
  description = "KMS key ID for source bucket encryption"
  type        = string
}

variable "source_kms_key_arn" {
  description = "KMS key ARN for source bucket encryption"
  type        = string
}

variable "destination_bucket_arn" {
  description = "ARN of the destination S3 bucket in the target account"
  type        = string
}

variable "destination_kms_key_arn" {
  description = "KMS key ARN for destination bucket encryption"
  type        = string
}

variable "destination_account_id" {
  description = "AWS account ID of the destination account"
  type        = string
}

variable "destination_storage_class" {
  description = "Storage class for replicated objects"
  type        = string
  default     = "STANDARD"
  
  validation {
    condition = contains([
      "STANDARD", "REDUCED_REDUNDANCY", "STANDARD_IA", 
      "ONEZONE_IA", "INTELLIGENT_TIERING", "GLACIER", 
      "DEEP_ARCHIVE", "GLACIER_IR"
    ], var.destination_storage_class)
    error_message = "Invalid storage class specified."
  }
}

variable "replication_prefix" {
  description = "Object prefix to replicate (empty string for all objects)"
  type        = string
  default     = ""
}

variable "create_destination_bucket" {
  description = "Whether to create the destination bucket (set to false if bucket exists in another account)"
  type        = bool
  default     = false
}

variable "destination_bucket_name" {
  description = "Name of the destination S3 bucket"
  type        = string
  default     = ""
}

variable "destination_kms_key_id" {
  description = "KMS key ID for destination bucket encryption"
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

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}