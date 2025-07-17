module "waf_basic" {
  source                = "../../modules/waf"
  name                  = "basic-waf"
  scope                 = "REGIONAL"
  default_action        = "block"
  rule_group_arn_list   = []
  alb_arn_list          = []
  aws_managed_rule_groups = []
  tags = {
    Environment = "basic"
  }
}