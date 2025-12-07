#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LOCK="$ROOT/.backend.lock"
SIG="$ROOT/.backend.lock.asc"
TEMPLATE="$ROOT/backend_templates/local.tf"
TARGET="$ROOT/infra/bootstrap/backend.tf"

mkdir -p "$ROOT/infra/bootstrap"

fatal() {
  echo "FATAL: $1"
  exit 1
}

[[ -f "$LOCK" ]] && fatal "backend already locked"

echo "=================================================="
echo " Backend selection (TESTING ONLY)"
echo "=================================================="
echo "Selected backend: LOCAL"
echo "This backend is NOT suitable for production."
echo

read -rp "Type LOCAL to confirm: " CONFIRM
[[ "$CONFIRM" == "LOCAL" ]] || fatal "aborted"

echo
read -rp "Enter region (e.g. local): " REGION
[[ -z "$REGION" ]] && fatal "Region is required"

read -rp "Enter system name (governed naming): " SYSTEM_NAME
[[ -z "$SYSTEM_NAME" ]] && fatal "System name is required"

SHA="$(sha256sum "$TEMPLATE" | awk '{print $1}')"
DATE="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

cat > "$LOCK" <<EOF
backend=local
template=backend_templates/local.tf
sha256=$SHA
timestamp=$DATE
region=$REGION
system_name=$SYSTEM_NAME
EOF

cp "$TEMPLATE" "$TARGET"

echo
echo "Signing backend intent..."
gpg --armor --detach-sign "$LOCK"

echo
echo "Backend locked and signed."
echo "  backend      : local"
echo "  region       : $REGION"
echo "  system_name  : $SYSTEM_NAME"
