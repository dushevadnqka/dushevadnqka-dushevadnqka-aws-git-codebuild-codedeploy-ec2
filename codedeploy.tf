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
