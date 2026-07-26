#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# Despliegue completo del Camino A (ECS Fargate + ALB) desde cero.
# Equivalente a scripts/bootstrap.ps1 para Linux/macOS y para el runner de CI.
#
#   uso: scripts/bootstrap.sh --repo-root /ruta/a/ethos-devops-test [opciones]
#
# Fases:
#   1. Crea SOLO el repositorio ECR (ECS no arranca sin imagen).
#   2. Build + push de app-ethos-mock con tag trazable (SHA del commit).
#   3. Aplica el resto de la infraestructura apuntando a esa imagen.
# ---------------------------------------------------------------------------
set -euo pipefail

REPO_ROOT=""
AWS_PROFILE_NAME="ethos-cand"
REGION="us-east-1"
CANDIDATE_ID="lucio-o-dev"
CONTAINER_PORT=0
SKIP_BUILD=0

while [ $# -gt 0 ]; do
  case "$1" in
    --repo-root)      REPO_ROOT="$2"; shift 2 ;;
    --profile)        AWS_PROFILE_NAME="$2"; shift 2 ;;
    --region)         REGION="$2"; shift 2 ;;
    --candidate-id)   CANDIDATE_ID="$2"; shift 2 ;;
    --container-port) CONTAINER_PORT="$2"; shift 2 ;;
    --skip-build)     SKIP_BUILD=1; shift ;;
    -h|--help)        sed -n '2,20p' "$0"; exit 0 ;;
    *) echo "Opcion desconocida: $1"; exit 1 ;;
  esac
done

say()  { printf '\n==> %s\n' "$1"; }
warn() { printf '  ! %s\n' "$1"; }
die()  { printf '  x %s\n' "$1" >&2; exit 1; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INFRA_DIR="$SCRIPT_DIR/../infra/ecs"

[ -n "$REPO_ROOT" ] || die "Falta --repo-root (ruta al clon de ethos-devops-test)."
APP_DIR="$REPO_ROOT/app-ethos-mock"
[ -d "$APP_DIR" ] || die "No existe $APP_DIR."

# En CI ya vienen credenciales por env/OIDC: no se fuerza el perfil.
if [ -z "${AWS_ACCESS_KEY_ID:-}" ] && [ -z "${AWS_ROLE_ARN:-}" ]; then
  export AWS_PROFILE="$AWS_PROFILE_NAME"
else
  AWS_PROFILE_NAME=""
fi
export AWS_REGION="$REGION"

say "Verificando herramientas y credenciales"
for t in aws terraform docker git; do
  command -v "$t" >/dev/null 2>&1 || die "Falta '$t' en el PATH."
done
aws sts get-caller-identity --query Arn --output text | sed 's/^/  Identidad: /'
docker info >/dev/null 2>&1 || die "Docker no esta corriendo."

# --- Puerto del contenedor ---------------------------------------------------
DETECTED=0
if [ -f "$APP_DIR/Dockerfile" ]; then
  DETECTED="$(grep -iEm1 '^[[:space:]]*EXPOSE[[:space:]]+[0-9]+' "$APP_DIR/Dockerfile" | grep -oE '[0-9]+' | head -n1 || true)"
  DETECTED="${DETECTED:-0}"
fi
if [ "$CONTAINER_PORT" -eq 0 ]; then
  if [ "$DETECTED" -gt 0 ] 2>/dev/null; then
    CONTAINER_PORT="$DETECTED"
    echo "  Puerto detectado en el Dockerfile (EXPOSE): $CONTAINER_PORT"
  else
    CONTAINER_PORT=8080
    warn "El Dockerfile no declara EXPOSE. Usando $CONTAINER_PORT (ajusta con --container-port si /health no responde)."
  fi
elif [ "$DETECTED" -gt 0 ] 2>/dev/null && [ "$DETECTED" -ne "$CONTAINER_PORT" ]; then
  warn "El Dockerfile declara EXPOSE $DETECTED pero se forzo --container-port $CONTAINER_PORT."
fi

SHA="$(git -C "$REPO_ROOT" rev-parse --short=12 HEAD 2>/dev/null || echo local)"
IMAGE_TAG="sha-$SHA"
echo "  Tag de imagen: $IMAGE_TAG"

cd "$INFRA_DIR"
TF_ARGS=(
  "-var=candidate_id=$CANDIDATE_ID"
  "-var=aws_region=$REGION"
  "-var=aws_profile=$AWS_PROFILE_NAME"
  "-var=container_port=$CONTAINER_PORT"
)

say "Fase 0/3 - terraform init"
terraform init -input=false

say "Fase 1/3 - creando repositorio ECR"
terraform apply -input=false -auto-approve -target=aws_ecr_repository.app "${TF_ARGS[@]}" \
  || die "No se pudo crear el repositorio ECR (revisa tags/permisos: docs/RUNBOOK.md)."

ECR_URL="$(terraform output -raw ecr_repository_url)"
REGISTRY="${ECR_URL%%/*}"
echo "  ECR: $ECR_URL"

if [ "$SKIP_BUILD" -eq 0 ]; then
  say "Fase 2/3 - build y push de la imagen"
  aws ecr get-login-password --region "$REGION" | docker login --username AWS --password-stdin "$REGISTRY"
  docker build \
    --label "org.opencontainers.image.revision=$SHA" \
    --label "ethos.candidate=$CANDIDATE_ID" \
    --label "ethos.project=devops-test" \
    -t "$ECR_URL:$IMAGE_TAG" \
    -t "$ECR_URL:candidato-$CANDIDATE_ID" \
    "$APP_DIR"
  docker push "$ECR_URL:$IMAGE_TAG"
  docker push "$ECR_URL:candidato-$CANDIDATE_ID"
else
  warn "Build omitido (--skip-build)."
fi

say "Fase 3/3 - aplicando infraestructura (IAM, ALB, ECS)"
terraform apply -input=false -auto-approve "${TF_ARGS[@]}" "-var=image_tag=$IMAGE_TAG" \
  || die "terraform apply fallo. Ver docs/RUNBOOK.md."

APP_URL="$(terraform output -raw app_url)"
say "Resumen"
terraform output resumen_entrega

say "Smoke test (puede tardar 1-2 min mientras el target group pasa a healthy)"
bash "$SCRIPT_DIR/../ci/smoke-test.sh" "$APP_URL"

say "Listo"
echo "  URL publica: $APP_URL"
echo "  Health:      $APP_URL/health"
echo "  Ready:       $APP_URL/ready"
