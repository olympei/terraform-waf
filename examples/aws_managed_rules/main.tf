provider "aws" {
  region = "us-east-1"
}

variable "aws_managed_rule_groups" {
  description = "List of AWS Managed Rule Groups to include in the WAF ACL"
  type = list(object({
    name            = string
    vendor_name     = string
    priority        = number
    override_action = optional(string, "none")
  }))
  default = []
}

module "waf_with_aws_managed_rules" {
  source = "../../modules/waf"

  name                    = "aws-managed-rules-waf"
  scope                   = "REGIONAL"
  default_action          = "allow"
  aws_managed_rule_groups = var.aws_managed_rule_groups
  rule_group_arn_list     = []
  custom_inline_rules     = []
  alb_arn_list           = []
  
  tags = {
    Environment = "production"
    Purpose     = "AWS Managed Rules Demo"
  }
}