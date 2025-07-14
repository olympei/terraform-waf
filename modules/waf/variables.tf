
variable "name" { type = string }
variable "scope" { type = string } # REGIONAL or CLOUDFRONT
variable "default_action" { type = string } # allow or block
#variable "rule_group_arn_list" { type = list(string) default = [] }
# Variable: rule_group_arn_list (with optional name/priority)
```hcl
variable "rule_group_arn_list" {
  type = list(object({
    arn      = string
    name     = optional(string)
    priority = optional(number)
  }))
  default = []
  description = "List of rule group ARNs to associate with the WAF ACL. Name and priority are optional."
}
```

# Variable: aws_managed_rule_groups
```hcl
variable "aws_managed_rule_groups" {
  description = "List of AWS Managed Rule Groups to include in the WAF ACL. Each object must include vendor_name, name, and priority."
  type = list(object({
    name         = string
    vendor_name  = string
    priority     = number
    override_action = optional(string, "none") # none or count
  }))
  default = []
}
```


variable "alb_arn_list" { type = list(string) default = [] }
variable "tags" { type = map(string) default = {} }



variable "create_log_group" {
  type    = bool
  default = false
}

variable "log_group_name" {
  type    = string
  default = null
}

variable "existing_log_group_arn" {
  type    = string
  default = null
}

variable "log_group_retention_in_days" {
  type    = number
  default = 30
}

variable "kms_key_id" {
  type    = string
  default = null
  description = "KMS Key ID to encrypt the CloudWatch Log Group if created."
}


# Variable: rules (object list for inline rule types)
```hcl
variable "custom_inline_rules" {
  type = list(object({
    name         = string
    priority     = number
    action       = string
    rule_type    = string
    statement    = string
    metric_name  = string
  }))
  default = []
  description = "Inline rule definitions for common WAF rule types like SQLi, IP block, XSS, etc."
  validation {
    condition = length(distinct([for r in var.custom_inline_rules : r.priority])) == length(var.custom_inline_rules)
    error_message = "Duplicate priorities detected in custom_inline_rules. All rule priorities must be unique."
  }
}
```

# Validation Rule
```hcl
variable "validate_priorities" {
  description = "Ensures unique WAF rule priorities across all rule types"
  type        = bool
  default     = true
  validation {
    condition     = length(distinct(local.all_waf_priorities)) == length(local.all_waf_priorities)
    error_message = "Duplicate priorities detected across inline and rule group rules. All WAF rule priorities must be unique."
  }
}
```