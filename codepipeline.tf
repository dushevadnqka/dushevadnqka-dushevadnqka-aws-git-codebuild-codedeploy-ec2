resource "aws_codepipeline" "kf-codepipeline" {
  name     = "${var.service_name}-codepipeline"
  role_arn = aws_iam_role.kf-cdppln-role.arn

  artifact_store {
    location = aws_s3_bucket.kf-cdppln-bucket.bucket
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "ThirdParty"
      provider         = "GitHub"
      version          = "1"
      output_artifacts = ["source"]

      configuration = {
        Owner      = var.git_owner
        Repo       = var.git_repo
        Branch     = var.git_branch
        OAuthToken = var.github_token
      }
    }
  }

  stage {
    name = "Build"

    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source"]
      output_artifacts = ["build"]
      version          = "1"

      configuration = {
        ProjectName = aws_codebuild_project.kf-codebuild.name
      }
    }
  }

  stage {
    name = "Deploy"

    action {
      name            = "ExternalDeploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "CodeDeploy"
      input_artifacts = ["build"]
      version         = "1"

      configuration = {
        ApplicationName     = "${var.service_name}-service-deploy"
        DeploymentGroupName = "${var.service_name}-service-deploy-group"
      }
    }
  }
}

data "aws_iam_policy_document" "assume_by_codepipeline" {
  statement {
    sid     = "AssumebyCodepipeline"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["codepipeline.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "kf-cdppln-role" {
  name               = "kf-cdppln-role"
  assume_role_policy = data.aws_iam_policy_document.assume_by_codepipeline.json
}

data "aws_iam_policy_document" "kf-cdppln-role-policy-s3" {
  statement {
    sid    = "AllowS3"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:GetBucketVersioning",
      "s3:PutObjectAcl",
      "s3:PutObject"
    ]

    resources = [
      aws_s3_bucket.kf-cbld-bucket.arn,
      "${aws_s3_bucket.kf-cbld-bucket.arn}/*",
      aws_s3_bucket.kf-cdppln-bucket.arn,
      "${aws_s3_bucket.kf-cdppln-bucket.arn}/*"
    ]
  }
}

resource "aws_iam_role_policy" "kf-cdppln-role-policy-s3" {
  role   = aws_iam_role.kf-cdppln-role.name
  policy = data.aws_iam_policy_document.kf-cdppln-role-policy-s3.json
}

data "aws_iam_policy_document" "kf-cdppln-role-policy-codebuild" {
  statement {
    sid    = "AllowCodebuild"
    effect = "Allow"
    actions = [
      "codebuild:BatchGetBuilds",
      "codebuild:StartBuild"
    ]

    resources = [
      aws_codebuild_project.kf-codebuild.arn
    ]
  }
}

resource "aws_iam_role_policy" "kf-cdppln-role-policy-codebuild" {
  role   = aws_iam_role.kf-cdppln-role.name
  policy = data.aws_iam_policy_document.kf-cdppln-role-policy-codebuild.json
}

data "aws_iam_policy_document" "kf-cdppln-role-policy-codedeploy" {
  statement {
    sid    = "AllowCodedeploy"
    effect = "Allow"
    actions = [
      "codedeploy:CreateDeployment",
      "codedeploy:GetApplication",
      "codedeploy:GetApplicationRevision",
      "codedeploy:GetDeployment",
      "codedeploy:GetDeploymentConfig",
      "codedeploy:RegisterApplicationRevision"
    ]

    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "kf-cdppln-role-policy-codedeploy" {
  role   = aws_iam_role.kf-cdppln-role.name
  policy = data.aws_iam_policy_document.kf-cdppln-role-policy-codedeploy.json
}

// Far from the best practices. TODO: split them by actions
data "aws_iam_policy_document" "kf-cdppln-role-policy-mixed" {
  statement {
    sid    = "AllowCodedeploy"
    effect = "Allow"
    actions = [
      "ec2:*",
      "elasticloadbalancing:*",
      "autoscaling:*",
      "cloudwatch:*",
      "ecr:DescribeImages",
      "iam:PassRole"
    ]

    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "kf-cdppln-role-policy-mixed" {
  role   = aws_iam_role.kf-cdppln-role.name
  policy = data.aws_iam_policy_document.kf-cdppln-role-policy-mixed.json
}
