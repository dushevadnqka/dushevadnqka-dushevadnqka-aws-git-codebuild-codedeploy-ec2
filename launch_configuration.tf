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
  desired_capacity     = 1
  vpc_zone_identifier  = aws_subnet.private.*.id
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
