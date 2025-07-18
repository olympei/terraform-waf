variable "name" {
  description = "Name of the regex pattern set"
  type        = string
}

variable "scope" {
  description = "Scope of the regex pattern set (REGIONAL or CLOUDFRONT)"
  type        = string
  validation {
    condition     = contains(["REGIONAL", "CLOUDFRONT"], var.scope)
    error_message = "Scope must be either REGIONAL or CLOUDFRONT."
  }
}

variable "regex_strings" {
  description = "List of regular expression patterns"
  type        = list(string)
}

variable "tags" {
  description = "Tags to apply to the regex pattern set"
  type        = map(string)
  default     = {}
}