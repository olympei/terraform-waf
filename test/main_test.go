package test

import (
    "path/filepath"
    "testing"

    "github.com/gruntwork-io/terratest/modules/terraform"
    "github.com/stretchr/testify/assert"
)

func TestInvalidPriorityFails(t *testing.T) {
    t.Parallel()

    terraformOptions := &terraform.Options{
        TerraformDir: "../examples/invalid_priority",
    }

    _, err := terraform.InitAndPlanE(t, terraformOptions)
    assert.Error(t, err, "Expected an error due to duplicate priorities in WAF rules")
}