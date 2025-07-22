# Local values for WAF module
locals {
  # Current AWS account and region data
  current_account_id = data.aws_caller_identity.current.account_id
  current_region     = data.aws_region.current.name
  
  # Construct log group ARN if log group name is provided without full ARN
  log_group_arn = var.existing_log_group_arn != null ? var.existing_log_group_arn : (
    var.create_log_group ? aws_cloudwatch_log_group.this[0].arn : null
  )
  
  # Validate log group ARN format with more comprehensive checks including naming requirement
  is_valid_log_group_arn = var.existing_log_group_arn == null ? true : (
    can(regex("^arn:aws:logs:[a-z0-9-]+:[0-9]{12}:log-group:", var.existing_log_group_arn)) &&
    length(split(":", var.existing_log_group_arn)) >= 6 &&
    split(":", var.existing_log_group_arn)[2] == "logs" &&
    split(":", var.existing_log_group_arn)[5] == "log-group" &&
    local.log_group_name_valid
  )
  
  # Extract components from ARN for validation
  arn_components = var.existing_log_group_arn != null ? split(":", var.existing_log_group_arn) : []
  arn_region = length(local.arn_components) >= 4 ? local.arn_components[3] : ""
  arn_account_id = length(local.arn_components) >= 5 ? local.arn_components[4] : ""
  
  # Validate region and account match current context
  is_correct_region = var.existing_log_group_arn == null ? true : (local.arn_region == local.current_region)
  is_correct_account = var.existing_log_group_arn == null ? true : (local.arn_account_id == local.current_account_id)
  
  # Extract log group name from ARN for validation
  log_group_name_from_arn = var.existing_log_group_arn != null ? split(":", var.existing_log_group_arn)[6] : null
  
  # Validate log group name has required aws-waf-logs- prefix
  log_group_name_valid = var.existing_log_group_arn == null ? true : (
    local.log_group_name_from_arn != null && 
    startswith(local.log_group_name_from_arn, "aws-waf-logs-")
  )
  
  # Generate WAF-compliant log group name with required prefix
  waf_compliant_log_group_name = var.log_group_name != null ? (
    startswith(var.log_group_name, "aws-waf-logs-") ? var.log_group_name : "aws-waf-logs-${replace(var.log_group_name, "/", "-")}"
  ) : "aws-waf-logs-${var.name}"
  
  # Default log group name with required aws-waf-logs- prefix
  default_log_group_name = local.waf_compliant_log_group_name
  
  # Common tags for all resources
  common_tags = merge(
    var.tags,
    {
      ManagedBy = "terraform"
      Module    = "waf"
      WAFName   = var.name
    }
  )
}

# Data sources for current AWS context
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}