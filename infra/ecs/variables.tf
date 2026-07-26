# ---------------------------------------------------------------------------
# Identidad de la prueba
# ---------------------------------------------------------------------------
variable "candidate_id" {
  description = "Identificador del candidato. Se usa en nombres y en el tag ethos:candidate."
  type        = string
  default     = "lucio-o-dev"
}

variable "project_tag" {
  description = "Valor del tag ethos:project exigido por el permissions boundary."
  type        = string
  default     = "devops-test"
}

variable "permissions_boundary_arn" {
  description = "Permissions boundary obligatorio para cualquier rol IAM que cree el candidato."
  type        = string
  default     = "arn:aws:iam::816583873447:policy/EthosDevOpsCandidateBoundary"
}

# ---------------------------------------------------------------------------
# AWS
# ---------------------------------------------------------------------------
variable "aws_region" {
  description = "Región AWS de la prueba."
  type        = string
  default     = "us-east-1"
}

variable "aws_profile" {
  description = "Perfil del AWS CLI a usar. Vacío = credenciales del entorno (lo que usa CI)."
  type        = string
  default     = ""
}

# ---------------------------------------------------------------------------
# Red
# ---------------------------------------------------------------------------
variable "vpc_id" {
  description = "VPC donde desplegar. Vacío = VPC default de la cuenta."
  type        = string
  default     = ""
}

variable "subnet_ids" {
  description = "Subnets públicas para el ALB y las tasks. Vacío = se descubren las públicas de la VPC en allowed_azs."
  type        = list(string)
  default     = []
}

variable "allowed_azs" {
  description = "AZs a usar cuando las subnets se descubren solas. us-east-1e se excluye porque no soporta todas las familias de Fargate."
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

variable "ingress_cidrs" {
  description = "CIDRs con acceso HTTP al ALB. La prueba pide URL pública, por eso 0.0.0.0/0."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

# ---------------------------------------------------------------------------
# Aplicación
# ---------------------------------------------------------------------------
variable "container_name" {
  description = "Nombre del contenedor en la task definition. El pipeline lo usa para inyectar la nueva imagen."
  type        = string
  default     = "app-ethos-mock"
}

variable "container_port" {
  description = "Puerto en el que escucha app-ethos-mock DENTRO del contenedor. Debe coincidir con el EXPOSE del Dockerfile."
  type        = number
  default     = 8080
}

variable "container_environment" {
  description = "Variables de entorno no sensibles para el contenedor. Los secretos van por SSM/Secrets Manager, nunca aquí."
  type        = map(string)
  default     = {}
}

variable "image_tag" {
  description = "Tag de la imagen en ECR a desplegar. En CI es el SHA corto del commit."
  type        = string
  default     = "bootstrap"
}

variable "health_check_path" {
  description = "Path del health check que consulta el target group del ALB."
  type        = string
  default     = "/health"
}

variable "ready_check_path" {
  description = "Path de readiness. Se expone y se valida en el smoke test del pipeline."
  type        = string
  default     = "/ready"
}

# ---------------------------------------------------------------------------
# Dimensionamiento
# ---------------------------------------------------------------------------
variable "task_cpu" {
  description = "CPU de la task Fargate (unidades: 256 = 0.25 vCPU)."
  type        = number
  default     = 256
}

variable "task_memory" {
  description = "Memoria de la task Fargate en MiB."
  type        = number
  default     = 512
}

variable "desired_count" {
  description = "Número de tasks del servicio. 2 para tener el servicio repartido en más de una AZ."
  type        = number
  default     = 2
}

variable "log_retention_days" {
  description = "Retención de logs en CloudWatch. Acotada para no dejar costo abierto."
  type        = number
  default     = 14
}

# ---------------------------------------------------------------------------
# Flags — cosas que el boundary del candidato puede no permitir.
# Si un apply falla por AccessDenied en estos recursos, se apagan sin tocar
# el resto del stack.
# ---------------------------------------------------------------------------
variable "enable_ecr_lifecycle_policy" {
  description = "Aplica lifecycle policy al repo ECR (requiere ecr:PutLifecyclePolicy)."
  type        = bool
  default     = true
}

variable "enable_container_insights" {
  description = "Habilita Container Insights en el cluster ECS."
  type        = bool
  default     = true
}

variable "enable_execute_command" {
  description = "Habilita ECS Exec en el servicio (requiere permisos ssmmessages en el task role)."
  type        = bool
  default     = false
}

# ---------------------------------------------------------------------------
# OIDC para GitHub Actions (preferido sobre access keys estáticas).
# Off por default: crear el OIDC provider es una operación a nivel cuenta que
# el usuario del candidato normalmente no puede hacer. Ver docs/IAM-Y-SECRETOS.md.
# ---------------------------------------------------------------------------
variable "enable_github_oidc" {
  description = "Crea el rol asumible por GitHub Actions vía OIDC."
  type        = bool
  default     = false
}

variable "github_oidc_provider_arn" {
  description = "ARN del OIDC provider de GitHub ya existente en la cuenta. Vacío = Terraform intenta crearlo."
  type        = string
  default     = ""
}

variable "github_repo" {
  description = "Repositorio owner/name autorizado a asumir el rol OIDC."
  type        = string
  default     = "ethoscredito/ethos-devops-test"
}

variable "github_branch" {
  description = "Rama autorizada a asumir el rol OIDC. Solo la rama del candidato puede desplegar."
  type        = string
  default     = "candidato/lucio-o-dev"
}

# ---------------------------------------------------------------------------
# Security groups existentes.
# El usuario del candidato no tiene ec2:CreateSecurityGroup en esta cuenta, de
# modo que se reutiliza un security group ya creado. En blanco, Terraform los
# crea, que es el camino correcto en una cuenta con permisos completos.
# ---------------------------------------------------------------------------
variable "alb_security_group_id" {
  description = "ID de un security group existente para el ALB. En blanco, Terraform crea uno."
  type        = string
  default     = ""
}

variable "service_security_group_id" {
  description = "ID de un security group existente para las tasks Fargate. En blanco, Terraform crea uno."
  type        = string
  default     = ""
}
