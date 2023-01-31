data "aws_ami" "amazon-linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name = "name"
    values = [
      "amzn-ami-hvm-*-x86_64-ebs"
    ]
  }
}

resource "aws_launch_configuration" "kf_lc" {
  name_prefix          = "EC2-Instance-${var.service_name}"
  image_id             = data.aws_ami.amazon-linux.id
  instance_type        = var.ec2_instance_type
  iam_instance_profile = aws_iam_instance_profile.ec2-instance-profile.id

  root_block_device {
    volume_type           = "gp2"
    volume_size           = 100
    delete_on_termination = true
  }

  lifecycle {
    create_before_destroy = true
  }

  security_groups = [
    aws_security_group.ec2.id
  ]

  user_data = data.template_cloudinit_config.kf_lc-user-data.rendered
}

resource "aws_autoscaling_group" "kf_asg" {
  name                 = "${var.service_name}-ec2-autoscaling-group"
  max_size             = 2
  min_size             = 1
  desired_capacity     = var.asg_size
  vpc_zone_identifier  = aws_subnet.private[*].id
  launch_configuration = aws_launch_configuration.kf_lc.name
  health_check_type    = "ELB"
  target_group_arns = [
    aws_lb_target_group.kf-alb-tg.arn
  ]

  tag {
    key                 = "Name"
    value               = "EC2-Instance-${var.service_name}-service"
    propagate_at_launch = true
  }
}

resource "aws_iam_instance_profile" "ec2-instance-profile" {
  name = "${var.service_name}-ec2-instance-profile"
  path = "/"
  role = aws_iam_role.ec2-instance-role.id
}

//TODO: refactor the role and policies in the way they are present in codedeploy / codebuild / codepipeline sections
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
