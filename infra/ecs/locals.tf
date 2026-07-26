locals {
  # Convención de nombres exigida por la prueba: ethos-cand-<candidato-id>-...
  name_prefix = "ethos-cand-${var.candidate_id}"

  # El repositorio ECR va sin sufijo, tal cual pide el enunciado.
  ecr_repository_name = local.name_prefix

  cluster_name = "${local.name_prefix}-ecs-cluster"
  service_name = "${local.name_prefix}-svc"
  task_family  = "${local.name_prefix}-task"
  alb_name     = "${local.name_prefix}-alb" # límite AWS: 32 caracteres
  tg_name      = "${local.name_prefix}-tg"  # límite AWS: 32 caracteres
  log_group    = "/ecs/${local.name_prefix}"
  exec_role    = "${local.name_prefix}-ecs-exec"
  task_role    = "${local.name_prefix}-ecs-task"
  oidc_role    = "${local.name_prefix}-gha-deploy"

  # VPC y subnets: se aceptan explícitas o se descubren.
  vpc_id = var.vpc_id != "" ? var.vpc_id : data.aws_vpc.default.id

  discovered_subnet_ids = sort([
    for s in data.aws_subnet.candidate : s.id
    if s.map_public_ip_on_launch && contains(var.allowed_azs, s.availability_zone)
  ])

  subnet_ids = length(var.subnet_ids) > 0 ? var.subnet_ids : local.discovered_subnet_ids

  # Reutilizacion de security groups: ver variables.tf.
  create_alb_sg     = var.alb_security_group_id == ""
  create_service_sg = var.service_security_group_id == ""

  alb_sg_id     = local.create_alb_sg ? one(aws_security_group.alb[*].id) : var.alb_security_group_id
  service_sg_id = local.create_service_sg ? one(aws_security_group.service[*].id) : var.service_security_group_id

  image_uri = "${aws_ecr_repository.app.repository_url}:${var.image_tag}"

  container_env = [
    for k, v in var.container_environment : { name = k, value = v }
  ]
}
