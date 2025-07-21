resource "aws_iam_policy" "wafv2_admin_policy" {
  name        = var.policy_name
  description = "IAM policy to allow full management of AWS WAFv2 resources"
  policy      = data.aws_iam_policy_document.wafv2.json
}

data "aws_iam_policy_document" "wafv2" {
  # WAFv2 Core Permissions
  statement {
    sid    = "AllowWAFv2FullAccess"
    effect = "Allow"

    actions = [
      # Web ACL Management
      "wafv2:CreateWebACL",
      "wafv2:UpdateWebACL",
      "wafv2:DeleteWebACL",
      "wafv2:GetWebACL",
      "wafv2:ListWebACLs",
      "wafv2:TagResource",
      "wafv2:UntagResource",
      "wafv2:ListTagsForResource",
      
      # Rule Group Management
      "wafv2:CreateRuleGroup",
      "wafv2:UpdateRuleGroup",
      "wafv2:DeleteRuleGroup",
      "wafv2:GetRuleGroup",
      "wafv2:ListRuleGroups",
      
      # IP Set Management
      "wafv2:CreateIPSet",
      "wafv2:UpdateIPSet",
      "wafv2:DeleteIPSet",
      "wafv2:GetIPSet",
      "wafv2:ListIPSets",
      
      # Regex Pattern Set Management
      "wafv2:CreateRegexPatternSet",
      "wafv2:UpdateRegexPatternSet",
      "wafv2:DeleteRegexPatternSet",
      "wafv2:GetRegexPatternSet",
      "wafv2:ListRegexPatternSets",
      
      # Logging Configuration
      "wafv2:PutLoggingConfiguration",
      "wafv2:DeleteLoggingConfiguration",
      "wafv2:GetLoggingConfiguration",
      "wafv2:ListLoggingConfigurations",
      
      # Web ACL Association
      "wafv2:AssociateWebACL",
      "wafv2:DisassociateWebACL",
      "wafv2:ListResourcesForWebACL",
      "wafv2:GetWebACLForResource",
      
      # Monitoring and Analytics
      "wafv2:GetRateBasedStatementManagedKeys",
      "wafv2:GetSampledRequests",
      "wafv2:ListAvailableManagedRuleGroups",
      "wafv2:ListAvailableManagedRuleGroupVersions",
      "wafv2:DescribeManagedRuleGroup",
      
      # Managed Rules
      "wafv2:CheckCapacity",
      "wafv2:PutPermissionPolicy",
      "wafv2:DeletePermissionPolicy",
      "wafv2:GetPermissionPolicy"
    ]

    resources = ["*"]
  }

  # CloudWatch Logs Permissions for WAF Logging
  statement {
    sid    = "AllowCloudWatchLogsAccess"
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams",
      "logs:DeleteLogGroup",
      "logs:DeleteLogStream",
      "logs:PutRetentionPolicy",
      "logs:DeleteRetentionPolicy",
      "logs:DescribeDestinations",
      "logs:PutDestination",
      "logs:DeleteDestination",
      "logs:PutDestinationPolicy",
      "logs:TagLogGroup",
      "logs:UntagLogGroup",
      "logs:ListTagsLogGroup"
    ]

    resources = [
      "arn:aws:logs:*:*:log-group:/aws/wafv2/*",
      "arn:aws:logs:*:*:log-group:/aws/wafv2/*:*"
    ]
  }

  # KMS Permissions for Log Encryption
  statement {
    sid    = "AllowKMSAccess"
    effect = "Allow"

    actions = [
      "kms:CreateKey",
      "kms:DescribeKey",
      "kms:GetKeyPolicy",
      "kms:PutKeyPolicy",
      "kms:CreateAlias",
      "kms:DeleteAlias",
      "kms:ListAliases",
      "kms:UpdateAlias",
      "kms:TagResource",
      "kms:UntagResource",
      "kms:ListResourceTags",
      "kms:ScheduleKeyDeletion",
      "kms:CancelKeyDeletion",
      "kms:EnableKey",
      "kms:DisableKey",
      "kms:GetKeyRotationStatus",
      "kms:EnableKeyRotation",
      "kms:DisableKeyRotation",
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]

    resources = ["*"]
  }

  # Application Load Balancer Association Permissions
  statement {
    sid    = "AllowALBAccess"
    effect = "Allow"

    actions = [
      "elasticloadbalancing:DescribeLoadBalancers",
      "elasticloadbalancing:DescribeTargetGroups",
      "elasticloadbalancing:DescribeListeners",
      "elasticloadbalancing:DescribeRules",
      "elasticloadbalancing:ModifyListener",
      "elasticloadbalancing:ModifyRule"
    ]

    resources = ["*"]
  }

  # CloudFront Association Permissions (for CLOUDFRONT scope)
  statement {
    sid    = "AllowCloudFrontAccess"
    effect = "Allow"

    actions = [
      "cloudfront:GetDistribution",
      "cloudfront:GetDistributionConfig",
      "cloudfront:ListDistributions",
      "cloudfront:UpdateDistribution"
    ]

    resources = ["*"]
  }

  # API Gateway Association Permissions
  statement {
    sid    = "AllowAPIGatewayAccess"
    effect = "Allow"

    actions = [
      "apigateway:GET",
      "apigateway:PUT",
      "apigateway:POST",
      "apigateway:DELETE",
      "apigateway:PATCH"
    ]

    resources = [
      "arn:aws:apigateway:*::/restapis/*/stages/*",
      "arn:aws:apigateway:*::/v2/apis/*/stages/*"
    ]
  }

  # S3 Permissions for Cross-Account Replication Module
  statement {
    sid    = "AllowS3Access"
    effect = "Allow"

    actions = [
      "s3:CreateBucket",
      "s3:DeleteBucket",
      "s3:GetBucketLocation",
      "s3:GetBucketVersioning",
      "s3:PutBucketVersioning",
      "s3:GetBucketReplication",
      "s3:PutBucketReplication",
      "s3:DeleteBucketReplication",
      "s3:GetBucketEncryption",
      "s3:PutBucketEncryption",
      "s3:GetBucketPublicAccessBlock",
      "s3:PutBucketPublicAccessBlock",
      "s3:GetBucketPolicy",
      "s3:PutBucketPolicy",
      "s3:DeleteBucketPolicy",
      "s3:GetBucketTagging",
      "s3:PutBucketTagging",
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:GetObjectVersion",
      "s3:DeleteObjectVersion",
      "s3:ListBucket",
      "s3:ListBucketVersions",
      "s3:ReplicateObject",
      "s3:ReplicateDelete",
      "s3:ReplicateTags"
    ]

    resources = [
      "arn:aws:s3:::*",
      "arn:aws:s3:::*/*"
    ]
  }

  # IAM Permissions for S3 Replication Roles
  statement {
    sid    = "AllowIAMAccess"
    effect = "Allow"

    actions = [
      "iam:CreateRole",
      "iam:DeleteRole",
      "iam:GetRole",
      "iam:PassRole",
      "iam:PutRolePolicy",
      "iam:DeleteRolePolicy",
      "iam:GetRolePolicy",
      "iam:ListRolePolicies",
      "iam:AttachRolePolicy",
      "iam:DetachRolePolicy",
      "iam:ListAttachedRolePolicies",
      "iam:TagRole",
      "iam:UntagRole",
      "iam:ListRoleTags"
    ]

    resources = [
      "arn:aws:iam::*:role/*-replication-role",
      "arn:aws:iam::*:role/*waf*",
      "arn:aws:iam::*:role/*WAF*"
    ]
  }

  # CloudWatch Metrics and Monitoring
  statement {
    sid    = "AllowCloudWatchMetrics"
    effect = "Allow"

    actions = [
      "cloudwatch:PutMetricData",
      "cloudwatch:GetMetricStatistics",
      "cloudwatch:ListMetrics",
      "cloudwatch:PutMetricAlarm",
      "cloudwatch:DeleteAlarms",
      "cloudwatch:DescribeAlarms",
      "cloudwatch:DescribeAlarmsForMetric"
    ]

    resources = ["*"]
  }

  # Resource Groups and Tagging
  statement {
    sid    = "AllowResourceGroupsAndTagging"
    effect = "Allow"

    actions = [
      "resource-groups:CreateGroup",
      "resource-groups:DeleteGroup",
      "resource-groups:GetGroup",
      "resource-groups:GetGroupQuery",
      "resource-groups:ListGroups",
      "resource-groups:UpdateGroup",
      "resource-groups:UpdateGroupQuery",
      "tag:GetResources",
      "tag:TagResources",
      "tag:UntagResources",
      "tag:GetTagKeys",
      "tag:GetTagValues"
    ]

    resources = ["*"]
  }

  # Systems Manager Parameter Store (for configuration management)
  statement {
    sid    = "AllowSSMParameterAccess"
    effect = "Allow"

    actions = [
      "ssm:GetParameter",
      "ssm:GetParameters",
      "ssm:GetParametersByPath",
      "ssm:PutParameter",
      "ssm:DeleteParameter",
      "ssm:DescribeParameters"
    ]

    resources = [
      "arn:aws:ssm:*:*:parameter/waf/*",
      "arn:aws:ssm:*:*:parameter/WAF/*"
    ]
  }

  # AWS Config for Compliance Monitoring
  statement {
    sid    = "AllowConfigAccess"
    effect = "Allow"

    actions = [
      "config:PutConfigRule",
      "config:DeleteConfigRule",
      "config:DescribeConfigRules",
      "config:GetComplianceDetailsByConfigRule",
      "config:GetComplianceSummaryByConfigRule"
    ]

    resources = ["*"]
  }

  # EventBridge for Event-Driven Automation
  statement {
    sid    = "AllowEventBridgeAccess"
    effect = "Allow"

    actions = [
      "events:PutRule",
      "events:DeleteRule",
      "events:DescribeRule",
      "events:PutTargets",
      "events:RemoveTargets",
      "events:ListTargetsByRule"
    ]

    resources = [
      "arn:aws:events:*:*:rule/waf-*",
      "arn:aws:events:*:*:rule/WAF-*"
    ]
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