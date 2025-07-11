variable "name" {}
variable "scope" {}
variable "addresses" {
  type = list(string)
}
variable "ip_address_version" {
  type    = string
  default = "IPV4"
}
variable "tags" {
  type    = map(string)
  default = {}
}