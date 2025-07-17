variable "policy_name" {
  description = "Name of the IAM policy"
  type        = string
  default     = "WAFv2FullAccessPolicy"
}

variable "attach_to_role_arn" {
  description = "IAM role name to attach the policy to (optional)"
  type        = string
  default     = ""
}

variable "attach_to_user" {
  description = "IAM user name to attach the policy to (optional)"
  type        = string
  default     = ""
}

variable "attach_to_group" {
  description = "IAM group name to attach the policy to (optional)"
  type        = string
  default     = ""
}