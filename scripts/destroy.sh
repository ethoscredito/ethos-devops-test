#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# Destruye toda la infraestructura de la prueba (evita costo residual).
#   uso: scripts/destroy.sh [--force]
# ---------------------------------------------------------------------------
set -euo pipefail

AWS_PROFILE_NAME="ethos-cand"
REGION="us-east-1"
CANDIDATE_ID="lucio-o-dev"
FORCE=0

while [ $# -gt 0 ]; do
  case "$1" in
    --profile)      AWS_PROFILE_NAME="$2"; shift 2 ;;
    --region)       REGION="$2"; shift 2 ;;
    --candidate-id) CANDIDATE_ID="$2"; shift 2 ;;
    --force)        FORCE=1; shift ;;
    *) echo "Opcion desconocida: $1"; exit 1 ;;
  esac
done

if [ -z "${AWS_ACCESS_KEY_ID:-}" ] && [ -z "${AWS_ROLE_ARN:-}" ]; then
  export AWS_PROFILE="$AWS_PROFILE_NAME"
else
  AWS_PROFILE_NAME=""
fi
export AWS_REGION="$REGION"

if [ "$FORCE" -eq 0 ]; then
  echo "Se va a DESTRUIR toda la infraestructura de ethos-cand-$CANDIDATE_ID:"
  echo "  ALB, target group, security groups, cluster y servicio ECS, roles IAM, log group y el repo ECR con sus imagenes."
  read -r -p "Escribe 'destruir' para confirmar: " answer
  [ "$answer" = "destruir" ] || { echo "Cancelado."; exit 0; }
fi

cd "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../infra/ecs"
terraform destroy -input=false -auto-approve \
  "-var=candidate_id=$CANDIDATE_ID" \
  "-var=aws_region=$REGION" \
  "-var=aws_profile=$AWS_PROFILE_NAME"

echo "Infraestructura destruida."
