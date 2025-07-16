# Destination bucket configuration (to be deployed in Account B)
# This file contains the destination bucket resources

# Note: This should be deployed separately in the destination account
# or use a separate provider configuration for cross-account deployment

# Destination bucket
resource "aws_s3_bucket" "destination" {
  count    = var.create_destination_bucket ? 1 : 0
  provider = aws.destination
  bucket   = var.destination_bucket_name
  
  tags = merge(var.tags, {
    Name = var.destination_bucket_name
    Type = "Destination"
  })
}

# Destination bucket versioning
resource "aws_s3_bucket_versioning" "destination" {
  count    = var.create_destination_bucket ? 1 : 0
  provider = aws.destination
  bucket   = aws_s3_bucket.destination[0].id
  
  versioning_configuration {
    status = "Enabled"
  }
}

# Destination bucket KMS encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "destination" {
  count    = var.create_destination_bucket ? 1 : 0
  provider = aws.destination
  bucket   = aws_s3_bucket.destination[0].id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = var.destination_kms_key_id
      sse_algorithm     = "aws:kms"
    }
    bucket_key_enabled = true
  }
}

# Destination bucket public access block
resource "aws_s3_bucket_public_access_block" "destination" {
  count    = var.create_destination_bucket ? 1 : 0
  provider = aws.destination
  bucket   = aws_s3_bucket.destination[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Destination bucket policy to allow replication from source account
resource "aws_s3_bucket_policy" "destination" {
  count    = var.create_destination_bucket ? 1 : 0
  provider = aws.destination
  bucket   = aws_s3_bucket.destination[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowReplicationFromSourceAccount"
        Effect = "Allow"
        Principal = {
          AWS = aws_iam_role.replication.arn
        }
        Action = [
          "s3:ReplicateObject",
          "s3:ReplicateDelete",
          "s3:ReplicateTags"
        ]
        Resource = "${aws_s3_bucket.destination[0].arn}/*"
      }
    ]
  })
}