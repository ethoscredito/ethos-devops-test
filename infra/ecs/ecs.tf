resource "aws_cloudwatch_log_group" "app" {
  name              = local.log_group
  retention_in_days = var.log_retention_days

  tags = {
    Name = local.log_group
  }
}

resource "aws_ecs_cluster" "main" {
  name = local.cluster_name

  setting {
    name  = "containerInsights"
    value = var.enable_container_insights ? "enabled" : "disabled"
  }

  tags = {
    Name = local.cluster_name
  }
}

resource "aws_ecs_cluster_capacity_providers" "main" {
  cluster_name       = aws_ecs_cluster.main.name
  capacity_providers = ["FARGATE", "FARGATE_SPOT"]

  default_capacity_provider_strategy {
    capacity_provider = "FARGATE"
    weight            = 1
    base              = 1
  }
}

# La task definition no la gestiona Terraform. El usuario del candidato no
# tiene permiso de ecs:DescribeTaskDefinition (esa API no admite permisos a
# nivel de recurso, de modo que una regla condicionada por tags nunca la
# habilita) y el provider hace read-after-create. El JSON vive versionado en
# task-definition.json y se registra con la CLI desde el pipeline, igual que
# hace la action amazon-ecs-render-task-definition.
resource "aws_ecs_service" "app" {
  name            = local.service_name
  cluster         = aws_ecs_cluster.main.id
  task_definition = local.task_family
  desired_count   = var.desired_count

  launch_type            = "FARGATE"
  platform_version       = "LATEST"
  propagate_tags         = "SERVICE"
  enable_execute_command = var.enable_execute_command

  # Sin NAT gateway, la task necesita IP pública para hacer pull de ECR.
  network_configuration {
    subnets          = local.subnet_ids
    security_groups  = [local.service_sg_id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.app.arn
    container_name   = var.container_name
    container_port   = var.container_port
  }

  # Margen para que la app arranque antes de que el ALB la declare unhealthy.
  health_check_grace_period_seconds = 60

  deployment_minimum_healthy_percent = 100
  deployment_maximum_percent         = 200

  # Un deploy roto se revierte solo en vez de dejar el servicio caído.
  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  # El pipeline es el dueño del rollout de imagen: registra una revisión nueva
  # y hace update-service. Terraform mantiene la topología, no la versión
  # desplegada — si no se ignora, cada plan querría regresar al tag anterior.
  lifecycle {
    ignore_changes = [task_definition, desired_count]
  }

  depends_on = [aws_lb_listener.http]

  tags = {
    Name = local.service_name
  }
}
