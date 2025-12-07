#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LOCK="$ROOT/.backend.lock"
SIG="$ROOT/.backend.lock.asc"
TEMPLATE="$ROOT/backend_templates/local.tf"
TARGET="$ROOT/infra/bootstrap/backend.tf"

mkdir -p "$ROOT/infra/bootstrap"

[[ -f "$LOCK" ]] && { echo "FATAL: backend already locked"; exit 1; }

echo "Backend selection (TESTING ONLY)"
echo "Selected backend: LOCAL"
echo "This backend is NOT suitable for production."
echo

read -rp "Type LOCAL to confirm: " CONFIRM
[[ "$CONFIRM" == "LOCAL" ]] || { echo "Aborted"; exit 1; }

SHA="$(sha256sum "$TEMPLATE" | awk '{print $1}')"
DATE="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

cat > "$LOCK" <<EOF2
backend=local
template=backend_templates/local.tf
sha256=$SHA
timestamp=$DATE
EOF2

cp "$TEMPLATE" "$TARGET"

echo
echo "Signing backend intent..."
gpg --armor --detach-sign "$LOCK"

echo "Backend locked and signed."
