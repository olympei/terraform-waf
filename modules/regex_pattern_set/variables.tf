variable "name" {}
variable "scope" {}
variable "regex_strings" {
  type = list(string)
}
variable "tags" {
  type    = map(string)
  default = {}
}