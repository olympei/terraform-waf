module "web_acl" {
  source = "../modules/waf_acl"
  name   = "target-waf"
  scope  = "REGIONAL"
  default_action = "allow"
  rule_group_arn_list = []
  alb_arn_list = []
  aws_managed_rule_groups = []
  tags = {
    Environment = "target"
  }
}