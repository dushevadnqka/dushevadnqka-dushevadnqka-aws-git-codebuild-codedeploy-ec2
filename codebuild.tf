resource "aws_codebuild_project" "kf-codebuild" {
  name          = "${var.service_name}-codebuild"
  description   = "Codebuild for project ${var.service_name}."
  build_timeout = "5"
  service_role  = aws_iam_role.kf-codebuild-role.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  cache {
    type     = "S3"
    location = aws_s3_bucket.kf-cbld-bucket.bucket
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:2.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode             = true

    environment_variable {
      name  = "IMAGE_REPO_NAME"
      value = var.service_name
    }

    environment_variable {
      name  = "AWS_ACCOUNT_ID"
      value = var.aws_account_id
    }

    environment_variable {
      name  = "AWS_DEFAULT_REGION"
      value = var.region
    }

    environment_variable {
      name  = "IMAGE_TAG"
      value = var.docker_image_tag
    }

    environment_variable {
      name  = "SERVICE_PORT"
      value = var.container_port
    }

    environment_variable {
      name  = "MEMORY_RESV"
      value = var.memory_reserv
    }

    environment_variable {
      name  = "DBNAME"
      value = aws_rds_cluster.kf-aurora-cluster-postgre.database_name
    }

    environment_variable {
      name  = "DBHOST"
      value = aws_rds_cluster.kf-aurora-cluster-postgre.endpoint
    }
  }

  source {
    type = "CODEPIPELINE"
  }

  tags = {
    Name        = var.service_name
    Environment = "${var.service_name}-env"
  }

  depends_on = [
    aws_rds_cluster.kf-aurora-cluster-postgre
  ]
}
