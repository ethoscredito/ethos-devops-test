#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# Smoke test HTTP contra el ALB.
#   uso: ci/smoke-test.sh http://<alb-dns>  [intentos] [espera_seg]
#
# Valida /health y /ready por separado. Reintenta porque justo después de un
# rollout el target group tarda unos segundos en marcar los targets healthy.
# ---------------------------------------------------------------------------
set -uo pipefail

BASE="${1:?Falta la URL base, ej: http://mi-alb-123.us-east-1.elb.amazonaws.com}"
ATTEMPTS="${2:-30}"
SLEEP="${3:-10}"

BASE="${BASE%/}"
PATHS=("/health" "/ready")
FAIL=0

probe() {
  local url="$1"
  local i code body
  for ((i = 1; i <= ATTEMPTS; i++)); do
    body="$(curl -sS -m 10 -w $'\n%{http_code}' "$url" 2>/dev/null || true)"
    code="$(printf '%s' "$body" | tail -n1)"
    if [ "$code" = "200" ]; then
      echo "  OK   $url  ->  200"
      printf '%s' "$body" | sed '$d' | head -c 400 | sed 's/^/       /'
      echo ""
      return 0
    fi
    echo "  ...  intento $i/$ATTEMPTS  $url  ->  ${code:-sin-respuesta}"
    sleep "$SLEEP"
  done
  echo "  FALLO  $url no devolvio 200 tras $ATTEMPTS intentos"
  return 1
}

echo "Smoke test contra $BASE"
echo ""

for p in "${PATHS[@]}"; do
  probe "${BASE}${p}" || FAIL=1
done

echo ""
if [ "$FAIL" -ne 0 ]; then
  echo "Smoke test FALLIDO."
  exit 1
fi

echo "Smoke test OK: /health y /ready responden 200 desde internet."
