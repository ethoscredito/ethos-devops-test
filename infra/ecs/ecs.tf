resource "aws_ecs_task_definition" "this" {
  family                   = "${local.app_name}-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]

  cpu    = "256"
  memory = "512"

  execution_role_arn = data.aws_iam_role.ecs_execution.arn

  container_definitions = jsonencode([
    {
      name      = "ethos-mock"
      image     = "816583873447.dkr.ecr.us-east-1.amazonaws.com/${local.app_name}:latest"
      essential = true

      portMappings = [
        {
          containerPort = 8081
          hostPort      = 8081
          protocol      = "tcp"
        }
      ]

      healthCheck = {
        command     = ["CMD-SHELL", "wget -qO- http://127.0.0.1:8081/health || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 10
      }

      logConfiguration = {
        logDriver = "awslogs"

        options = {
          awslogs-group         = aws_cloudwatch_log_group.ecs.name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])

  tags = local.tags
}

resource "aws_ecs_service" "this" {

  name = "${local.app_name}-service"

  cluster = aws_ecs_cluster.this.id

  task_definition = aws_ecs_task_definition.this.arn

  desired_count = 1

  launch_type = "FARGATE"

  network_configuration {

    subnets = data.aws_subnets.default.ids

    security_groups = [
      aws_security_group.ecs.id
    ]

    assign_public_ip = true
  }

  load_balancer {

    target_group_arn = aws_lb_target_group.this.arn

    container_name = "ethos-mock"

    container_port = 8081
  }

  depends_on = [
    aws_lb_listener.http
  ]

  tags = local.tags
}

resource "aws_ecs_cluster" "this" {
  name = "${local.app_name}-ecs-cluster"

  tags = local.tags
}
