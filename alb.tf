resource "aws_lb" "kf-alb" {
  name               = "${var.service_name}-service-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups = [
    aws_security_group.alb.id
  ]
  subnets = aws_subnet.public[*].id

  tags = {
    Name = "${var.service_name}-service-alb"
  }
}

resource "aws_lb_target_group" "kf-alb-tg" {
  name = "${var.service_name}-tg"

  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.kf-vpc.id
  target_type = "instance"

  health_check {
    path     = "/healthcheck"
    protocol = "HTTP"
    interval = 40
    timeout  = 30
  }
}

resource "aws_lb_listener" "kf-alb-listener" {
  load_balancer_arn = aws_lb.kf-alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.kf-alb-tg.arn
  }
}
