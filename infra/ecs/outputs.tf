output "alb_dns_name" {
  description = "DNS público del ALB (*.elb.amazonaws.com). Es la URL de entrega."
  value       = aws_lb.app.dns_name
}

output "app_url" {
  description = "URL HTTP pública de la aplicación."
  value       = "http://${aws_lb.app.dns_name}"
}

output "health_url" {
  description = "Endpoint de health check."
  value       = "http://${aws_lb.app.dns_name}${var.health_check_path}"
}

output "ready_url" {
  description = "Endpoint de readiness."
  value       = "http://${aws_lb.app.dns_name}${var.ready_check_path}"
}

output "ecr_repository_url" {
  description = "URL del repositorio ECR para build/push."
  value       = aws_ecr_repository.app.repository_url
}

output "ecr_repository_name" {
  description = "Nombre del repositorio ECR."
  value       = aws_ecr_repository.app.name
}

output "ecs_cluster_name" {
  description = "Nombre del cluster ECS (guardarlo: ecs:ListClusters está denegado)."
  value       = aws_ecs_cluster.main.name
}

output "ecs_service_name" {
  description = "Nombre del servicio ECS."
  value       = aws_ecs_service.app.name
}

output "task_definition_family" {
  description = "Familia de la task definition que actualiza el pipeline."
  value       = aws_ecs_task_definition.app.family
}

output "container_name" {
  description = "Nombre del contenedor al que el pipeline le inyecta la imagen."
  value       = var.container_name
}

output "log_group_name" {
  description = "Log group de CloudWatch con los logs de la aplicación."
  value       = aws_cloudwatch_log_group.app.name
}

output "subnets_usadas" {
  description = "Subnets públicas seleccionadas para ALB y tasks."
  value       = local.subnet_ids
}

output "vpc_id" {
  description = "VPC en uso."
  value       = local.vpc_id
}

output "github_oidc_role_arn" {
  description = "ARN del rol OIDC para GitHub Actions (vacío si el flag está apagado)."
  value       = try(aws_iam_role.github_deploy[0].arn, "")
}

# Resumen listo para pegar en el correo de entrega.
output "resumen_entrega" {
  description = "Datos clave de la entrega."
  value = {
    candidato      = var.candidate_id
    camino         = "A — ECS Fargate + ALB"
    region         = var.aws_region
    url_publica    = "http://${aws_lb.app.dns_name}"
    health         = "http://${aws_lb.app.dns_name}${var.health_check_path}"
    ready          = "http://${aws_lb.app.dns_name}${var.ready_check_path}"
    ecr            = aws_ecr_repository.app.repository_url
    cluster        = aws_ecs_cluster.main.name
    servicio       = aws_ecs_service.app.name
    tags_aplicados = "ethos:candidate=${var.candidate_id}, ethos:project=${var.project_tag}"
  }
}
