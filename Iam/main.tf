resource "aws_iam_policy" "wafv2_admin_policy" {
  name        = var.policy_name
  description = "IAM policy to allow full management of AWS WAFv2 resources"
  policy      = data.aws_iam_policy_document.wafv2.json
}

data "aws_iam_policy_document" "wafv2" {
  statement {
    sid    = "AllowWAFv2FullAccess"
    effect = "Allow"

    actions = [
      "wafv2:CreateWebACL",
      "wafv2:UpdateWebACL",
      "wafv2:DeleteWebACL",
      "wafv2:GetWebACL",
      "wafv2:ListWebACLs",
      "wafv2:CreateRuleGroup",
      "wafv2:UpdateRuleGroup",
      "wafv2:DeleteRuleGroup",
      "wafv2:GetRuleGroup",
      "wafv2:ListRuleGroups",
      "wafv2:CreateRegexPatternSet",
      "wafv2:UpdateRegexPatternSet",
      "wafv2:DeleteRegexPatternSet",
      "wafv2:GetRegexPatternSet",
      "wafv2:ListRegexPatternSets",
      "wafv2:CreateIPSet",
      "wafv2:UpdateIPSet",
      "wafv2:DeleteIPSet",
      "wafv2:GetIPSet",
      "wafv2:ListIPSets",
      "wafv2:PutLoggingConfiguration",
      "wafv2:DeleteLoggingConfiguration",
      "wafv2:GetLoggingConfiguration",
      "wafv2:AssociateWebACL",
      "wafv2:DisassociateWebACL",
      "wafv2:ListResourcesForWebACL",
      "wafv2:GetRateBasedStatementManagedKeys",
      "wafv2:GetSampledRequests"
    ]

    resources = ["*"]
  }
}

resource "aws_iam_role_policy_attachment" "attach_to_role" {
  count      = var.attach_to_role_arn != "" ? 1 : 0
  role       = var.attach_to_role_arn
  policy_arn = aws_iam_policy.wafv2_admin_policy.arn
}

resource "aws_iam_user_policy_attachment" "attach_to_user" {
  count      = var.attach_to_user != "" ? 1 : 0
  user       = var.attach_to_user
  policy_arn = aws_iam_policy.wafv2_admin_policy.arn
}

resource "aws_iam_group_policy_attachment" "attach_to_group" {
  count      = var.attach_to_group != "" ? 1 : 0
  group      = var.attach_to_group
  policy_arn = aws_iam_policy.wafv2_admin_policy.arn
}