
variable "rule_group_name" { type = string }
variable "scope" { type = string }
variable "capacity" { type = number }
variable "metric_name" { type = string }
#variable "custom_rules" { type = list(map(any)) default = [] }
```hcl
variable "custom_rules" {
  description = "List of custom rules of various types. Supports both shorthand (type-based) and full statement definitions."
  type = list(object({
    name              = string
    priority          = number
    metric_name       = string
    type              = optional(string)                     # "sqli", "xss", "ip_block", "regex", "byte_match"
    statement         = optional(string)                     # Raw statement override
    field_to_match    = optional(string, "body")             # e.g., "uri_path", "query_string", "body"
    search_string     = optional(string)                     # For regex or byte match
    regex_pattern_set = optional(string)                     # ARN of regex pattern set
    ip_set_arn        = optional(string)                     # For ip_block
    action            = optional(string, "block")            # block, allow, count
  }))
  default = []
}

variable "use_templatefile_rendering" {
  description = "Enable templatefile rendering for rule statements"
  type        = bool
  default     = true
}
```
variable "use_rendered_rules" { type = bool default = false }
variable "tags" { type = map(string) default = {} }
