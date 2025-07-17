# Dev Environment

This environment deploys a WAFv2 Web ACL for development use. It uses the shared module from `../../modules/waf`.

## Usage

```hcl
module "waf_dev" {
  source                = "../../modules/waf"
  name                  = "dev-waf"
  scope                 = "REGIONAL"
  default_action        = "allow"
  rule_group_arn_list   = []
  alb_arn_list          = []
  aws_managed_rule_groups = []
  tags = {
    Environment = "dev"
  }
}
```

To deploy:

```bash
cd waf_envs_multi/dev
terraform init
terraform plan
terraform apply
```