
variable "name" { type = string }
variable "scope" { type = string } # REGIONAL or CLOUDFRONT
variable "default_action" { type = string } # allow or block
variable "rule_group_arn_list" { type = list(string) default = [] }
variable "aws_managed_rule_groups" {
  type = list(object({
    name            = string
    vendor          = string
    priority        = number
    override_action = optional(string, "none")
  }))
  default = []
}
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
}
