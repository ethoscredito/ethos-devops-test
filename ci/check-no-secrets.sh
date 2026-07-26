#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# Guard de secretos.
# Corre en CI antes de construir cualquier cosa y también en local antes de
# hacer push. Falla si encuentra credenciales o state de Terraform versionado.
# ---------------------------------------------------------------------------
set -uo pipefail

SELF="$(basename "$0")"
FAIL=0

EXCLUDES=(
  --binary-files=without-match
  --exclude-dir=.git
  --exclude-dir=.terraform
  --exclude-dir=node_modules
  --exclude-dir=.venv
  --exclude="$SELF"
  --exclude="*.tfstate"
  --exclude="*.tfstate.backup"
)

scan() {
  local label="$1" pattern="$2"
  local hits
  hits="$(grep -rInE "$pattern" . "${EXCLUDES[@]}" 2>/dev/null || true)"
  if [ -n "$hits" ]; then
    echo "::error::Posible secreto detectado ($label):"
    echo "$hits" | sed 's/^/    /'
    FAIL=1
  else
    echo "  ok  - $label"
  fi
}

echo "Escaneando el arbol en busca de credenciales..."

scan "AWS Access Key ID"       'A(KIA|SIA|ROA|IDA)[0-9A-Z]{16}'
scan "AWS Secret Access Key"   '(aws_)?secret_access_key["'"'"' ]*[:=][[:space:]]*["'"'"']?[A-Za-z0-9/+=]{40}'
scan "Llave privada PEM"       '-----BEGIN ([A-Z]+ )?PRIVATE KEY-----'
scan "Bloque de credenciales"  '\[(default|ethos-cand)\][[:space:]]*$.*aws_access_key_id'

# Terraform state nunca debe estar versionado: contiene valores sensibles.
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  TRACKED="$(git ls-files | grep -E '\.tfstate|\.tfvars$|^\.env$|(^|/)credentials$' || true)"
  if [ -n "$TRACKED" ]; then
    echo "::error::Archivos sensibles versionados en git:"
    echo "$TRACKED" | sed 's/^/    /'
    FAIL=1
  else
    echo "  ok  - sin tfstate/tfvars/.env versionados"
  fi
fi

if [ "$FAIL" -ne 0 ]; then
  echo ""
  echo "Guard de secretos FALLIDO. Saca las credenciales del arbol antes de continuar."
  exit 1
fi

echo ""
echo "Guard de secretos OK."
