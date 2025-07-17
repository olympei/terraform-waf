provider "aws" {
  region = "us-east-1"
}

# Variables for log group configuration
variable "name" {
  description = "Name of the WAF Web ACL"
  type        = string
  default     = "log-group-example-waf"
}

variable "scope" {
  description = "Scope of the WAF (REGIONAL or CLOUDFRONT)"
  type        = string
  default     = "REGIONAL"
}

variable "default_action" {
  description = "Default action for the WAF (allow or block)"
  type        = string
  default     = "allow"
}

variable "create_log_group" {
  description = "Whether to create a new CloudWatch log group"
  type        = bool
  default     = true
}

variable "log_group_name" {
  description = "Name of the CloudWatch log group (optional)"
  type        = string
  default     = null
}

variable "existing_log_group_arn" {
  description = "ARN of existing CloudWatch log group (when create_log_group is false)"
  type        = string
  default     = null
}

variable "log_group_retention_in_days" {
  description = "Retention period for log group in days"
  type        = number
  default     = 90
}

variable "kms_key_id" {
  description = "KMS key ID for log group encryption (optional)"
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default = {
    Environment = "dev"
    Purpose     = "WAF Logging Demo"
  }
}

# Example 1: WAF with auto-created log group and KMS key
module "waf_with_auto_log_group" {
  source = "../../modules/waf"

  name                        = "${var.name}-auto"
  scope                       = var.scope
  default_action              = var.default_action
  aws_managed_rule_groups     = []
  rule_group_arn_list         = []
  custom_inline_rules         = []
  alb_arn_list               = []
  
  # Log group configuration - auto-create
  create_log_group           = true
  log_group_name             = null  # Will auto-generate name
  log_group_retention_in_days = var.log_group_retention_in_days
  kms_key_id                 = null  # Will auto-create KMS key
  
  tags = merge(var.tags, {
    LoggingType = "Auto-Created"
  })
}

# Example 2: WAF with custom log group name and provided KMS key
module "waf_with_custom_log_group" {
  source = "../../modules/waf"

  name                        = "${var.name}-custom"
  scope                       = var.scope
  default_action              = var.default_action
  aws_managed_rule_groups     = []
  rule_group_arn_list         = []
  custom_inline_rules         = []
  alb_arn_list               = []
  
  # Log group configuration - custom name
  create_log_group           = true
  log_group_name             = "/aws/wafv2/custom-log-group"
  log_group_retention_in_days = 30
  kms_key_id                 = var.kms_key_id  # Use provided KMS key if available
  
  tags = merge(var.tags, {
    LoggingType = "Custom-Named"
  })
}

# Example 3: WAF with existing log group (no log group creation)
module "waf_with_existing_log_group" {
  source = "../../modules/waf"

  name                        = "${var.name}-existing"
  scope                       = var.scope
  default_action              = var.default_action
  aws_managed_rule_groups     = []
  rule_group_arn_list         = []
  custom_inline_rules         = []
  alb_arn_list               = []
  
  # Log group configuration - use existing
  create_log_group           = false
  existing_log_group_arn     = var.existing_log_group_arn
  
  tags = merge(var.tags, {
    LoggingType = "Existing-LogGroup"
  })
}

# Example 4: WAF without logging (no log group)
module "waf_without_logging" {
  source = "../../modules/waf"

  name                        = "${var.name}-no-logging"
  scope                       = var.scope
  default_action              = var.default_action
  aws_managed_rule_groups     = []
  rule_group_arn_list         = []
  custom_inline_rules         = []
  alb_arn_list               = []
  
  # Log group configuration - no logging
  create_log_group           = false
  existing_log_group_arn     = null
  
  tags = merge(var.tags, {
    LoggingType = "No-Logging"
  })
}

# Outputs
output "waf_auto_log_group_arn" {
  description = "ARN of WAF with auto-created log group"
  value       = module.waf_with_auto_log_group.web_acl_arn
}

output "waf_custom_log_group_arn" {
  description = "ARN of WAF with custom log group"
  value       = module.waf_with_custom_log_group.web_acl_arn
}

output "waf_existing_log_group_arn" {
  description = "ARN of WAF with existing log group"
  value       = module.waf_with_existing_log_group.web_acl_arn
}

output "waf_no_logging_arn" {
  description = "ARN of WAF without logging"
  value       = module.waf_without_logging.web_acl_arn
}