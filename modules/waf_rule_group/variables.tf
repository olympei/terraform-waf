
variable "rule_group_name" { type = string }
variable "scope" { type = string }
variable "capacity" { type = number }
variable "metric_name" { type = string }
variable "custom_rules" { type = list(map(any)) default = [] }
variable "use_rendered_rules" { type = bool default = false }
variable "tags" { type = map(string) default = {} }
