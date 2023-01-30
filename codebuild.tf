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

    environment_variable {
      name  = "DOCKERHUB_USER"
      value = var.dockerhub_username
    }

    environment_variable {
      name  = "DOCKERHUB_PASS"
      value = var.dockerhub_pass
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


data "aws_iam_policy_document" "assume_by_codebuild" {
  statement {
    sid     = ""
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["codebuild.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "kf-codebuild-role" {
  name               = "kf-codebuild-role"
  assume_role_policy = data.aws_iam_policy_document.assume_by_codebuild.json
}

data "aws_iam_policy_document" "kf-codebuild-role-policy-cw" {
  statement {
    sid    = "AllowCreateAndPutCWLogs"
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]

    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "kf-codebuild-role-policy-cw" {
  role   = aws_iam_role.kf-codebuild-role.name
  policy = data.aws_iam_policy_document.kf-codebuild-role-policy-cw.json
}

data "aws_iam_policy_document" "kf-codebuild-role-policy-ecr" {
  statement {
    sid    = "AllowECR"
    effect = "Allow"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetAuthorizationToken",
      "ecr:PutImage",
      "ecr:InitiateLayerUpload",
      "ecr:CompleteLayerUpload",
      "ecr:UploadLayerPart"
    ]

    //TODO: point to the specific repo arn only, but need to change "aws ecr get-login" in the appspec scripts to let them work
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "kf-codebuild-role-policy-ecr" {
  role   = aws_iam_role.kf-codebuild-role.name
  policy = data.aws_iam_policy_document.kf-codebuild-role-policy-ecr.json
}

data "aws_iam_policy_document" "kf-codebuild-role-policy-s3" {
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

resource "aws_iam_role_policy" "kf-codebuild-role-policy-s3" {
  role   = aws_iam_role.kf-codebuild-role.name
  policy = data.aws_iam_policy_document.kf-codebuild-role-policy-s3.json
}
