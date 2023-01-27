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
