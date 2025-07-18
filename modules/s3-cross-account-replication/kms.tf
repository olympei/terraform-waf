# KMS key for source bucket (Account A)
resource "aws_kms_key" "source" {
  count       = var.create_source_kms_key ? 1 : 0
  description = "KMS key for S3 source bucket encryption"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow S3 Service"
        Effect = "Allow"
        Principal = {
          Service = "s3.amazonaws.com"
        }
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ]
        Resource = "*"
      },
      {
        Sid    = "Allow replication role"
        Effect = "Allow"
        Principal = {
          AWS = aws_iam_role.replication.arn
        }
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ]
        Resource = "*"
      }
    ]
  })

  tags = merge(var.tags, {
    Name = "${var.source_bucket_name}-kms-key"
  })
}

resource "aws_kms_alias" "source" {
  count         = var.create_source_kms_key ? 1 : 0
  name          = "alias/${var.source_bucket_name}-key"
  target_key_id = aws_kms_key.source[0].key_id
}

# KMS key for destination bucket (Account B)
resource "aws_kms_key" "destination" {
  count    = var.create_destination_kms_key ? 1 : 0
  provider = aws.destination
  description = "KMS key for S3 destination bucket encryption"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${var.destination_account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow S3 Service"
        Effect = "Allow"
        Principal = {
          Service = "s3.amazonaws.com"
        }
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ]
        Resource = "*"
      },
      {
        Sid    = "Allow cross-account replication"
        Effect = "Allow"
        Principal = {
          AWS = aws_iam_role.replication.arn
        }
        Action = [
          "kms:Encrypt",
          "kms:GenerateDataKey"
        ]
        Resource = "*"
      }
    ]
  })

  tags = merge(var.tags, {
    Name = "${var.destination_bucket_name}-kms-key"
  })
}

resource "aws_kms_alias" "destination" {
  count         = var.create_destination_kms_key ? 1 : 0
  provider      = aws.destination
  name          = "alias/${var.destination_bucket_name}-key"
  target_key_id = aws_kms_key.destination[0].key_id
}

# Data source for current AWS account
data "aws_caller_identity" "current" {}