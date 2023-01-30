# AWS Codebuild Resources:
resource "aws_iam_role" "kf-codebuild-role" {
  name = "kf-codebuild-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codebuild.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

// TODO: alocate the statements by service and specify the resource to restrict the permissions
resource "aws_iam_role_policy" "kf-codebuild-role-policy" {
  role = aws_iam_role.kf-codebuild-role.name

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Resource": "*",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ]
    },
    {
      "Effect":"Allow",
      "Action":[
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetAuthorizationToken",
        "ecr:PutImage",
        "ecr:InitiateLayerUpload",
        "ecr:CompleteLayerUpload",
        "ecr:UploadLayerPart"
      ],
      "Resource": "*"
    },
    {
      "Effect":"Allow",
      "Action":[
        "ecs:DescribeTaskDefinition"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:*"
      ],
      "Resource": [
        "${aws_s3_bucket.kf-cbld-bucket.arn}",
        "${aws_s3_bucket.kf-cbld-bucket.arn}/*",
        "${aws_s3_bucket.kf-cdppln-bucket.arn}",
        "${aws_s3_bucket.kf-cdppln-bucket.arn}/*"
      ]
    }
  ]
}
POLICY
}

# AWS CodePipeline:
resource "aws_iam_role" "kf-cdppln-role" {
  name = "kf-cdppln-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codepipeline.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

// TODO: alocate the statements by service and specify the resource to restrict the permissions
resource "aws_iam_role_policy" "kf-cdppln-role-policy" {
  name = "kf-cdppln-role-policy"
  role = aws_iam_role.kf-cdppln-role.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect":"Allow",
      "Action": [
        "s3:GetObject",
        "s3:GetObjectVersion",
        "s3:GetBucketVersioning",
        "s3:PutObjectAcl",
        "s3:PutObject"
      ],
      "Resource": [
        "${aws_s3_bucket.kf-cdppln-bucket.arn}",
        "${aws_s3_bucket.kf-cdppln-bucket.arn}/*",
        "${aws_s3_bucket.kf-cbld-bucket.arn}",
        "${aws_s3_bucket.kf-cbld-bucket.arn}/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "codebuild:BatchGetBuilds",
        "codebuild:StartBuild"
      ],
      "Resource": "*"
    },
    {
      "Effect":"Allow",
      "Action":[
        "ecr:DescribeImages"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "codedeploy:CreateDeployment",
        "codedeploy:GetApplication",
        "codedeploy:GetApplicationRevision",
        "codedeploy:GetDeployment",
        "codedeploy:GetDeploymentConfig",
        "codedeploy:RegisterApplicationRevision"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:*",
        "elasticloadbalancing:*",
        "autoscaling:*",
        "cloudwatch:*",
        "iam:PassRole"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

# AWS CodeDeploy
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

# AWS EC2 (TODO: the other IAM sections should follow this style of declaring)
resource "aws_iam_role" "ec2-instance-role" {
  name               = "${var.service_name}-ec2-instance-role"
  path               = "/"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_policy" "s3-perm-policy" {
  name        = "s3-perm-policy"
  description = "The ec2 instance need basic permission to cp artifact object (s3:PutObject) from the latest build in case of auto remediation."

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:GetObject",
        "s3:GetObjectVersion",
        "s3:GetBucketVersioning",
        "s3:PutObject",
        "s3:ListBucket",
        "s3:ListObjectVersions"
      ],
      "Effect": "Allow",
      "Resource": [
        "${aws_s3_bucket.kf-cdppln-bucket.arn}",
        "${aws_s3_bucket.kf-cdppln-bucket.arn}/*"
      ]
    }
  ]
}
EOF
}

resource "aws_iam_policy" "get-pipeline-state" {
  name        = "get-pipeline-state"
  description = "In case of auto-remediation the script need to know the state of the pipeline."

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "codepipeline:GetPipelineState"
      ],
      "Effect": "Allow",
      "Resource": [
        "${aws_codepipeline.kf-codepipeline.arn}"
      ]
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "ec2-instance-role-attachment_main" {
  role       = aws_iam_role.ec2-instance-role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

# For the sake of debugging the container or some of the services
resource "aws_iam_role_policy_attachment" "ec2-instance-role-attachment_allow_ssm_session" {
  role       = aws_iam_role.ec2-instance-role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "ec2-instance-role-attachment_ecr_ro" {
  role       = aws_iam_role.ec2-instance-role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "ec2-instance-role-attachment_s3" {
  role       = aws_iam_role.ec2-instance-role.name
  policy_arn = aws_iam_policy.s3-perm-policy.arn
}

resource "aws_iam_role_policy_attachment" "ec2-instance-role-attachment_codepipeline" {
  role       = aws_iam_role.ec2-instance-role.name
  policy_arn = aws_iam_policy.get-pipeline-state.arn
}
