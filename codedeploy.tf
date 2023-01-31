resource "aws_codedeploy_app" "kf-deployment" {
  compute_platform = "Server"
  name             = "${var.service_name}-service-deploy"
}

resource "aws_codedeploy_deployment_group" "kf-deployment" {
  app_name              = aws_codedeploy_app.kf-deployment.name
  deployment_group_name = "${var.service_name}-service-deploy-group"
  service_role_arn      = aws_iam_role.codedeploy.arn

  ec2_tag_filter {
    key   = "Name"
    type  = "KEY_AND_VALUE"
    value = "EC2-Instance-${var.service_name}-service"
  }
}

data "aws_iam_policy_document" "assume_by_codedeploy" {
  statement {
    sid     = ""
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["codedeploy.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "codedeploy" {
  name               = "${var.service_name}-codedeploy"
  assume_role_policy = data.aws_iam_policy_document.assume_by_codedeploy.json
}

data "aws_iam_policy_document" "codedeploy" {
  statement {
    sid    = "AllowLoadBalancingAndECSModifications"
    effect = "Allow"

    actions = [
      "elasticloadbalancing:DescribeListeners",
      "elasticloadbalancing:DescribeRules",
      "elasticloadbalancing:DescribeTargetGroups",
      "elasticloadbalancing:ModifyListener",
      "elasticloadbalancing:ModifyRule",
      "cloudwatch:DescribeAlarms",
      "s3:*",
      "ec2:*"
    ]

    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "codedeploy" {
  role   = aws_iam_role.codedeploy.name
  policy = data.aws_iam_policy_document.codedeploy.json
}
