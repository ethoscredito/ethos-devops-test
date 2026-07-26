data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

# ---------------------------------------------------------------------------
# Descubrimiento de red.
# El usuario del candidato no puede crear VPCs, pero sí tiene ec2:Describe*,
# así que se reutiliza la VPC default y sus subnets públicas.
# ---------------------------------------------------------------------------
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "in_vpc" {
  filter {
    name   = "vpc-id"
    values = [local.vpc_id]
  }
}

# Se consulta cada subnet para poder filtrar por AZ y por asignación de IP
# pública, en vez de asumir que todas sirven.
data "aws_subnet" "candidate" {
  for_each = toset(data.aws_subnets.in_vpc.ids)
  id       = each.value
}

# ---------------------------------------------------------------------------
# Validación temprana: sin al menos 2 subnets públicas el ALB no se puede crear.
# ---------------------------------------------------------------------------
check "subnets_disponibles" {
  assert {
    condition     = length(local.subnet_ids) >= 2
    error_message = "Se necesitan >= 2 subnets públicas en AZs distintas para el ALB. Pasa subnet_ids explícitamente o ajusta allowed_azs."
  }
}
