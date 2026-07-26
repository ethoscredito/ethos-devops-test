# ---------------------------------------------------------------------------
# Security groups.
# El ALB es la única puerta pública; las tasks solo aceptan tráfico del ALB.
# ---------------------------------------------------------------------------
resource "aws_security_group" "alb" {
  name        = "${local.name_prefix}-alb-sg"
  description = "HTTP publico hacia el ALB de ${local.name_prefix}"
  vpc_id      = local.vpc_id

  tags = {
    Name = "${local.name_prefix}-alb-sg"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "alb_http" {
  for_each = toset(var.ingress_cidrs)

  security_group_id = aws_security_group.alb.id
  description       = "HTTP entrante desde ${each.value}"
  cidr_ipv4         = each.value
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"

  tags = {
    Name = "${local.name_prefix}-alb-http-in"
  }
}

resource "aws_vpc_security_group_egress_rule" "alb_to_tasks" {
  security_group_id            = aws_security_group.alb.id
  description                  = "Solo hacia las tasks, al puerto de la app"
  referenced_security_group_id = aws_security_group.service.id
  from_port                    = var.container_port
  to_port                      = var.container_port
  ip_protocol                  = "tcp"

  tags = {
    Name = "${local.name_prefix}-alb-egress-tasks"
  }
}

resource "aws_security_group" "service" {
  name        = "${local.name_prefix}-svc-sg"
  description = "Tasks Fargate de ${local.name_prefix}: solo tráfico del ALB"
  vpc_id      = local.vpc_id

  tags = {
    Name = "${local.name_prefix}-svc-sg"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "service_from_alb" {
  security_group_id            = aws_security_group.service.id
  description                  = "Tráfico de la app únicamente desde el ALB"
  referenced_security_group_id = aws_security_group.alb.id
  from_port                    = var.container_port
  to_port                      = var.container_port
  ip_protocol                  = "tcp"

  tags = {
    Name = "${local.name_prefix}-svc-http-in"
  }
}

# Salida abierta: la task necesita alcanzar ECR y CloudWatch Logs por internet
# (subnets públicas, sin NAT gateway para no inflar el costo de la prueba).
resource "aws_vpc_security_group_egress_rule" "service_egress" {
  security_group_id = aws_security_group.service.id
  description       = "Salida a ECR / CloudWatch Logs"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"

  tags = {
    Name = "${local.name_prefix}-svc-egress"
  }
}

# ---------------------------------------------------------------------------
# Application Load Balancer — listener HTTP:80, sin HTTPS ni dominio propio
# (explícitamente permitido por el enunciado).
# ---------------------------------------------------------------------------
resource "aws_lb" "app" {
  name               = local.alb_name
  internal           = false
  load_balancer_type = "application"
  ip_address_type    = "ipv4"
  security_groups    = [aws_security_group.alb.id]
  subnets            = local.subnet_ids

  idle_timeout               = 60
  enable_deletion_protection = false
  drop_invalid_header_fields = true

  tags = {
    Name = local.alb_name
  }
}

resource "aws_lb_target_group" "app" {
  name        = local.tg_name
  port        = var.container_port
  protocol    = "HTTP"
  vpc_id      = local.vpc_id
  target_type = "ip" # obligatorio con awsvpc / Fargate

  deregistration_delay = 30

  health_check {
    enabled             = true
    path                = var.health_check_path
    protocol            = "HTTP"
    port                = "traffic-port"
    matcher             = "200"
    interval            = 15
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }

  tags = {
    Name = local.tg_name
  }

  # El TG se referencia desde el listener y el servicio: primero el nuevo.
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.app.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }

  tags = {
    Name = "${local.name_prefix}-http-80"
  }
}
