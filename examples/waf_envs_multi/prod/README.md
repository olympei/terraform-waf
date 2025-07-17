# Prod Environment

This environment deploys a WAFv2 Web ACL for production use. It uses the shared module from `../../modules/waf`.

## Usage

```hcl
module "waf_prod" {
  source                = "../../modules/waf"
  name                  = "prod-waf"
  scope                 = "REGIONAL"
  default_action        = "allow"
  rule_group_arn_list   = []
  alb_arn_list          = []
  aws_managed_rule_groups = []
  tags = {
    Environment = "prod"
  }
}
```

To deploy:

```bash
cd waf_envs_multi/prod
terraform init
terraform plan
terraform apply
```