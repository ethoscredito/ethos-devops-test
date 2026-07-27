resource "aws_lb" "this" {
  name               = substr(local.app_name, 0, 32)
  internal           = false
  load_balancer_type = "application"

  security_groups = [
    aws_security_group.alb.id
  ]

  subnets = data.aws_subnets.default.ids

  tags = local.tags
}

resource "aws_lb_target_group" "this" {
  name        = substr("${local.app_name}-tg", 0, 32)
  port        = 8081
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = data.aws_vpc.default.id

  health_check {
    path = "/health"

    matcher = "200"

    interval = 30
  }

  tags = local.tags
}

resource "aws_lb_listener" "http" {

  load_balancer_arn = aws_lb.this.arn

  port = 80

  protocol = "HTTP"

  default_action {

    type = "forward"

    target_group_arn = aws_lb_target_group.this.arn

  }
}
