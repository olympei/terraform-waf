# Example: WAF with Existing Log Group
# This example demonstrates how to properly use an existing CloudWatch Log Group with the WAF module

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.3.0"
}

provider "aws" {
  region = var.aws_region
}

# Variables
variable "aws_region" {
  description = "AWS region for deployment"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "alb_arn" {
  description = "ALB ARN to associate with WAF"
  type        = string
  default     = ""
}

# Data sources for current AWS context
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# Method 1: Create log group separately and reference it
# IMPORTANT: Log group name MUST start with 'aws-waf-logs-' prefix
resource "aws_cloudwatch_log_group" "waf_logs" {
  name              = "aws-waf-logs-my-waf-${var.environment}"
  retention_in_days = 30
  
  tags = {
    Environment = var.environment
    Purpose     = "WAF logging"
    ManagedBy   = "terraform"
  }
}

module "waf_with_existing_log_group" {
  source = "../../modules/waf"
  
  name                    = "my-waf-${var.environment}"
  scope                   = "REGIONAL"
  default_action          = "allow"
  
  # Use existing log group
  create_log_group        = false
  existing_log_group_arn  = aws_cloudwatch_log_group.waf_logs.arn
  
  # ALB association
  alb_arn_list = var.alb_arn != "" ? [var.alb_arn] : []
  
  # Custom rules
  custom_inline_rules = [
    {
      name        = "AllowHealthChecks"
      priority    = 100
      action      = "allow"
      metric_name = "allow_health_checks"
      statement_config = {
        byte_match_statement = {
          search_string         = "/health"
          positional_constraint = "EXACTLY"
          field_to_match = {
            uri_path = {}
          }
          text_transformation = {
            priority = 0
            type     = "LOWERCASE"
          }
        }
      }
    }
  ]
  
  tags = {
    Environment = var.environment
    Project     = "waf-example"
    ManagedBy   = "terraform"
  }
}

# Method 2: Use data source to reference existing log group
# IMPORTANT: Log group name MUST start with 'aws-waf-logs-' prefix
data "aws_cloudwatch_log_group" "existing_logs" {
  name = "aws-waf-logs-pre-existing-log-group"
  
  # This will fail if the log group doesn't exist
  # Comment out this data source if you don't have a pre-existing log group
  count = 0  # Set to 1 if you have a pre-existing log group
}

module "waf_with_data_source_log_group" {
  source = "../../modules/waf"
  count  = 0  # Set to 1 if you want to use this example
  
  name                    = "my-waf-data-source-${var.environment}"
  scope                   = "REGIONAL"
  default_action          = "allow"
  
  # Use log group from data source
  create_log_group        = false
  existing_log_group_arn  = data.aws_cloudwatch_log_group.existing_logs[0].arn
  
  alb_arn_list = var.alb_arn != "" ? [var.alb_arn] : []
  
  tags = {
    Environment = var.environment
    Project     = "waf-example"
    ManagedBy   = "terraform"
  }
}

# Method 3: Construct ARN manually (advanced users)
# IMPORTANT: Log group name MUST start with 'aws-waf-logs-' prefix
locals {
  # Construct log group ARN manually with required prefix
  manual_log_group_arn = "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:aws-waf-logs-manual-log-group"
}

# Create the log group with the manual ARN and required prefix
resource "aws_cloudwatch_log_group" "manual_logs" {
  name              = "aws-waf-logs-manual-log-group"
  retention_in_days = 7
  
  tags = {
    Environment = var.environment
    Purpose     = "Manual WAF logging"
    ManagedBy   = "terraform"
  }
}

module "waf_with_manual_arn" {
  source = "../../modules/waf"
  
  name                    = "my-waf-manual-${var.environment}"
  scope                   = "REGIONAL"
  default_action          = "allow"
  
  # Use manually constructed ARN
  create_log_group        = false
  existing_log_group_arn  = local.manual_log_group_arn
  
  alb_arn_list = var.alb_arn != "" ? [var.alb_arn] : []
  
  # Ensure log group is created before WAF
  depends_on = [aws_cloudwatch_log_group.manual_logs]
  
  tags = {
    Environment = var.environment
    Project     = "waf-example"
    ManagedBy   = "terraform"
  }
}

# Outputs
output "waf_arn" {
  description = "ARN of the WAF Web ACL"
  value       = module.waf_with_existing_log_group.waf_arn
}

output "waf_id" {
  description = "ID of the WAF Web ACL"
  value       = module.waf_with_existing_log_group.waf_id
}

output "log_group_arn" {
  description = "ARN of the CloudWatch Log Group"
  value       = aws_cloudwatch_log_group.waf_logs.arn
}

output "log_group_name" {
  description = "Name of the CloudWatch Log Group"
  value       = aws_cloudwatch_log_group.waf_logs.name
}

# Example of valid log group ARN format with required aws-waf-logs- prefix
output "example_valid_arn_format" {
  description = "Example of a valid CloudWatch Log Group ARN format for WAF"
  value       = "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:aws-waf-logs-example-log-group"
}

# Current AWS context for reference
output "current_aws_context" {
  description = "Current AWS account and region context"
  value = {
    account_id = data.aws_caller_identity.current.account_id
    region     = data.aws_region.current.name
  }
}