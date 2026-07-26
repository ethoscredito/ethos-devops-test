# ---------------------------------------------------------------------------
# GitHub Actions vía OIDC (sin access keys de larga vida).
#
# Apagado por default: crear el OIDC provider es una operación a nivel de
# cuenta que el usuario del candidato normalmente no tiene permitida. Se deja
# como IaC listo para aplicar:
#
#   enable_github_oidc       = true
#   github_oidc_provider_arn = "arn:aws:iam::816583873447:oidc-provider/token.actions.githubusercontent.com"
#
# El pipeline usa este rol automáticamente si existe la variable de repo
# AWS_OIDC_ROLE_ARN; si no, cae a secrets. Ver docs/IAM-Y-SECRETOS.md.
# ---------------------------------------------------------------------------
resource "aws_iam_openid_connect_provider" "github" {
  count = var.enable_github_oidc && var.github_oidc_provider_arn == "" ? 1 : 0

  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]

  tags = {
    Name = "github-actions-oidc"
  }
}

locals {
  github_oidc_arn = var.github_oidc_provider_arn != "" ? var.github_oidc_provider_arn : try(aws_iam_openid_connect_provider.github[0].arn, "")
}

data "aws_iam_policy_document" "github_assume" {
  count = var.enable_github_oidc ? 1 : 0

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [local.github_oidc_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    # Solo la rama del candidato puede desplegar. main queda fuera.
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${var.github_repo}:ref:refs/heads/${var.github_branch}"]
    }
  }
}

data "aws_iam_policy_document" "github_deploy" {
  count = var.enable_github_oidc ? 1 : 0

  # Push de imágenes solo al repo ECR del candidato.
  statement {
    sid       = "EcrAuth"
    effect    = "Allow"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }

  statement {
    sid    = "EcrPush"
    effect = "Allow"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:BatchGetImage",
      "ecr:CompleteLayerUpload",
      "ecr:DescribeImages",
      "ecr:DescribeRepositories",
      "ecr:GetDownloadUrlForLayer",
      "ecr:InitiateLayerUpload",
      "ecr:PutImage",
      "ecr:UploadLayerPart",
      "ecr:TagResource",
    ]
    resources = [aws_ecr_repository.app.arn]
  }

  # Rollout: registrar revisión y actualizar únicamente este servicio.
  statement {
    sid    = "EcsDeploy"
    effect = "Allow"
    actions = [
      "ecs:DescribeServices",
      "ecs:DescribeTaskDefinition",
      "ecs:DescribeTasks",
      "ecs:ListTasks",
      "ecs:UpdateService",
      "ecs:TagResource",
    ]
    resources = [
      aws_ecs_service.app.id,
      "arn:aws:ecs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:task-definition/${local.task_family}:*",
      "arn:aws:ecs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:task/${local.cluster_name}/*",
    ]
  }

  statement {
    sid       = "EcsRegisterTaskDefinition"
    effect    = "Allow"
    actions   = ["ecs:RegisterTaskDefinition"]
    resources = ["*"] # RegisterTaskDefinition no soporta resource-level ARN
  }

  # Solo puede pasar los dos roles de esta prueba, no cualquiera.
  statement {
    sid       = "PassExecutionRoles"
    effect    = "Allow"
    actions   = ["iam:PassRole"]
    resources = [aws_iam_role.ecs_execution.arn, aws_iam_role.ecs_task.arn]

    condition {
      test     = "StringEquals"
      variable = "iam:PassedToService"
      values   = ["ecs-tasks.amazonaws.com"]
    }
  }

  # Lectura para el smoke test contra el ALB.
  statement {
    sid       = "ReadAlb"
    effect    = "Allow"
    actions   = ["elasticloadbalancing:DescribeLoadBalancers", "elasticloadbalancing:DescribeTargetHealth"]
    resources = ["*"]
  }
}

resource "aws_iam_role" "github_deploy" {
  count = var.enable_github_oidc ? 1 : 0

  name                 = local.oidc_role
  description          = "Rol de despliegue para GitHub Actions (rama ${var.github_branch})"
  assume_role_policy   = data.aws_iam_policy_document.github_assume[0].json
  permissions_boundary = var.permissions_boundary_arn
  max_session_duration = 3600

  tags = {
    Name = local.oidc_role
  }
}

resource "aws_iam_role_policy" "github_deploy" {
  count = var.enable_github_oidc ? 1 : 0

  name   = "${local.oidc_role}-policy"
  role   = aws_iam_role.github_deploy[0].id
  policy = data.aws_iam_policy_document.github_deploy[0].json
}
