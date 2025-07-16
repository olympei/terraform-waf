# S3 Cross-Account Replication with KMS Encryption

This example demonstrates how to set up S3 cross-account replication with KMS encryption between two AWS accounts.

## Architecture

```
Account A (Source)          Account B (Destination)
┌─────────────────┐        ┌─────────────────┐
│ Source Bucket   │   ──>  │ Dest Bucket     │
│ + KMS Key       │        │ + KMS Key       │
│ + IAM Role      │        │ + Bucket Policy │
└─────────────────┘        └─────────────────┘
```

## Features

- **Cross-account replication**: Automatically replicates objects from source to destination account
- **KMS encryption**: Both buckets use KMS encryption with separate keys
- **Versioning**: Required for replication, automatically enabled
- **IAM permissions**: Proper cross-account permissions for replication
- **Storage classes**: Configurable destination storage class for cost optimization
- **Prefix filtering**: Optional prefix-based replication filtering

## Prerequisites

1. Two AWS accounts with appropriate permissions
2. AWS CLI configured with profiles for both accounts
3. Terraform >= 1.0 installed

## Setup Instructions

### Step 1: Configure AWS Profiles

```bash
# Configure AWS profiles for both accounts
aws configure --profile account-a
aws configure --profile account-b
```

### Step 2: Update Configuration

1. Copy the example variables file:
```bash
cp terraform.tfvars.example terraform.tfvars
```

2. Update `terraform.tfvars` with your values:
```hcl
source_bucket_name      = "my-company-source-bucket-12345"
destination_bucket_name = "my-company-dest-bucket-12345"
destination_account_id  = "123456789012"  # Account B ID
```

### Step 3: Update Provider Configuration

Update the provider configuration in `main.tf`:

```hcl
provider "aws" {
  alias   = "source"
  region  = var.source_region
  profile = "account-a"  # Your source account profile
}

provider "aws" {
  alias   = "destination"
  region  = var.destination_region
  profile = "account-b"  # Your destination account profile
}
```

### Step 4: Deploy

```bash
terraform init
terraform plan
terraform apply
```

## Configuration Options

### KMS Key Management

- **Create new keys** (default): Set `create_source_kms_key = true` and `create_destination_kms_key = true`
- **Use existing keys**: Set to `false` and provide existing key ARNs

### Storage Classes

Choose destination storage class for cost optimization:
- `STANDARD` - Standard storage
- `STANDARD_IA` - Infrequent Access (default)
- `ONEZONE_IA` - One Zone Infrequent Access
- `INTELLIGENT_TIERING` - Intelligent Tiering
- `GLACIER` - Glacier
- `DEEP_ARCHIVE` - Glacier Deep Archive

### Replication Filtering

- **All objects**: Leave `replication_prefix = ""`
- **Specific prefix**: Set `replication_prefix = "data/"` to replicate only objects with that prefix

## Security Considerations

1. **KMS Keys**: Each account uses its own KMS key for encryption
2. **IAM Permissions**: Minimal permissions granted for replication
3. **Bucket Policies**: Destination bucket only allows replication from source account
4. **Public Access**: All public access is blocked on both buckets

## Monitoring

After deployment, monitor replication through:

1. **CloudWatch Metrics**: S3 replication metrics
2. **S3 Console**: Replication status in bucket properties
3. **CloudTrail**: API calls for replication activities

## Troubleshooting

### Common Issues

1. **Permission Denied**: Ensure IAM roles have correct permissions
2. **KMS Access Denied**: Verify KMS key policies allow cross-account access
3. **Replication Not Working**: Check bucket versioning is enabled

### Validation Commands

```bash
# Check source bucket replication configuration
aws s3api get-bucket-replication --bucket your-source-bucket --profile account-a

# List objects in destination bucket
aws s3 ls s3://your-destination-bucket --profile account-b

# Check KMS key permissions
aws kms describe-key --key-id your-key-id --profile account-a
```

## Cost Optimization

- Use `STANDARD_IA` or `INTELLIGENT_TIERING` for destination storage
- Set up lifecycle policies for long-term archival
- Monitor replication costs in AWS Cost Explorer

## Cleanup

To destroy the infrastructure:

```bash
terraform destroy
```

Note: Empty the buckets before destroying to avoid errors.