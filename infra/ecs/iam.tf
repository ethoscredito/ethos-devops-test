# ---------------------------------------------------------------------------
# Roles de ECS.
# Los dos llevan el permissions boundary obligatorio del candidato y los tags
# ethos:*, si no CreateRole falla con AccessDenied.
#
# Separación deliberada:
#   - exec role : lo usa el AGENTE de ECS (pull de ECR, escribir logs).
#   - task role : lo usa la APLICACIÓN. Arranca sin permisos: least privilege.
# ---------------------------------------------------------------------------
data "aws_iam_policy_document" "ecs_tasks_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }

    # Confused deputy: el rol solo puede ser asumido en nombre de esta cuenta.
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }
}

resource "aws_iam_role" "ecs_execution" {
  name                 = local.exec_role
  description          = "Rol de ejecución de tasks ECS para ${local.name_prefix}"
  assume_role_policy   = data.aws_iam_policy_document.ecs_tasks_assume.json
  permissions_boundary = var.permissions_boundary_arn

  tags = {
    Name = local.exec_role
  }
}

resource "aws_iam_role_policy_attachment" "ecs_execution_managed" {
  role       = aws_iam_role.ecs_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "ecs_task" {
  name                 = local.task_role
  description          = "Rol de aplicación (task role) para ${local.name_prefix}"
  assume_role_policy   = data.aws_iam_policy_document.ecs_tasks_assume.json
  permissions_boundary = var.permissions_boundary_arn

  tags = {
    Name = local.task_role
  }
}

# Solo se concede lo mínimo para ECS Exec, y únicamente si se activa el flag.
data "aws_iam_policy_document" "ecs_exec_channel" {
  statement {
    effect = "Allow"
    actions = [
      "ssmmessages:CreateControlChannel",
      "ssmmessages:CreateDataChannel",
      "ssmmessages:OpenControlChannel",
      "ssmmessages:OpenDataChannel",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "ecs_task_exec_channel" {
  count  = var.enable_execute_command ? 1 : 0
  name   = "${local.task_role}-exec-channel"
  role   = aws_iam_role.ecs_task.id
  policy = data.aws_iam_policy_document.ecs_exec_channel.json
}
