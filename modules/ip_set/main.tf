resource "aws_wafv2_ip_set" "this" {
  name               = var.name
  scope              = var.scope
  ip_address_version = var.ip_address_version
  addresses          = var.addresses

  description = "Managed IP block set"
  tags        = var.tags
}