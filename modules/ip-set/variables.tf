variable "name" {
  description = "Name of the IP set"
  type        = string
}

variable "scope" {
  description = "Scope of the IP set (REGIONAL or CLOUDFRONT)"
  type        = string
  validation {
    condition     = contains(["REGIONAL", "CLOUDFRONT"], var.scope)
    error_message = "Scope must be either REGIONAL or CLOUDFRONT."
  }
}

variable "addresses" {
  description = "List of IP addresses or CIDR blocks"
  type        = list(string)
}

variable "ip_address_version" {
  description = "IP address version (IPV4 or IPV6)"
  type        = string
  default     = "IPV4"
  validation {
    condition     = contains(["IPV4", "IPV6"], var.ip_address_version)
    error_message = "IP address version must be either IPV4 or IPV6."
  }
}

variable "tags" {
  description = "Tags to apply to the IP set"
  type        = map(string)
  default     = {}
}