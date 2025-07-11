```hcl
module "regex" {
  source        = "../../modules/regex_pattern_set"
  name          = "dev-regex"
  scope         = "REGIONAL"
  regex_strings = ["(?i)drop", "(?i)malware"]
  tags = {
    Environment = "dev"
  }
}

module "ipset" {
  source     = "../../modules/ip_set"
  name       = "dev-ipset"
  scope      = "REGIONAL"
  addresses  = ["203.0.113.0/24"]
  tags = {
    Environment = "dev"
  }
}

module "waf_rule_group" {
  source              = "../../modules/waf_rule_group"
  rule_group_name     = "dev-waf-group"
  scope               = "REGIONAL"
  capacity            = 100
  metric_name         = "devMetrics"
  use_rendered_rules  = false
  tags                = {
    Environment = "dev"
  }

  custom_rules = [
    {
      name              = "RegexBlock"
      priority          = 0
      metric_name       = "regexBlock"
      type              = "regex"
      regex_pattern_set = module.regex.arn
      field_to_match    = "body"
    },
    {
      name         = "IPBlock"
      priority     = 1
      metric_name  = "ipBlock"
      type         = "ip_block"
      ip_set_arn   = module.ipset.arn
    }
  ]
}
```

## 📁 `examples/prod/main.tf`
```hcl
module "regex" {
  source        = "../../modules/regex_pattern_set"
  name          = "prod-regex"
  scope         = "REGIONAL"
  regex_strings = ["(?i)sqlinject", "(?i)cmd"]
  tags = {
    Environment = "prod"
  }
}

module "ipset" {
  source     = "../../modules/ip_set"
  name       = "prod-ipset"
  scope      = "REGIONAL"
  addresses  = ["198.51.100.0/24"]
  tags = {
    Environment = "prod"
  }
}

module "waf_rule_group" {
  source              = "../../modules/waf_rule_group"
  rule_group_name     = "prod-waf-group"
  scope               = "REGIONAL"
  capacity            = 100
  metric_name         = "prodMetrics"
  use_rendered_rules  = false
  tags                = {
    Environment = "prod"
  }

  custom_rules = [
    {
      name              = "RegexBlockProd"
      priority          = 10
      metric_name       = "regexBlockProd"
      type              = "regex"
      regex_pattern_set = module.regex.arn
      field_to_match    = "uri_path"
    },
    {
      name         = "BlockMaliciousIPs"
      priority     = 11
      metric_name  = "ipBlockProd"
      type         = "ip_block"
      ip_set_arn   = module.ipset.arn
    }
  ]
}
```

---

# CI/CD and Testing (Optional)

## 📁 `.gitlab-ci.yml`
```yaml
stages:
  - validate
  - deploy

validate:tf:
  stage: validate
  image: hashicorp/terraform:light
  script:
    - terraform init
    - terraform validate
  only:
    - merge_requests
    - branches

deploy:dev:
  stage: deploy
  image: hashicorp/terraform:light
  script:
    - cd examples/dev
    - terraform init
    - terraform apply -auto-approve
  only:
    - main

deploy:prod:
  stage: deploy
  image: hashicorp/terraform:light
  script:
    - cd examples/prod
    - terraform init
    - terraform apply -auto-approve
  when: manual
```

## 📁 `test/test_waf_rule_group.go`
```go
package test

import (
  "testing"
  "github.com/gruntwork-io/terratest/modules/terraform"
  "github.com/stretchr/testify/assert"
)

func TestDevWAFModule(t *testing.T) {
  opts := &terraform.Options{
    TerraformDir: "../examples/dev",
  }

  defer terraform.Destroy(t, opts)
  terraform.InitAndApply(t, opts)

  arn := terraform.Output(t, opts, "waf_rule_group_arn")
  assert.Contains(t, arn, "arn:aws:wafv2")
}
```