#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
VERSION_FILE="$ROOT/VERSION"
VERSION="$(cat "$VERSION_FILE" 2>/dev/null || echo "unknown")"

LOCK="$ROOT/.backend.lock"
SIG="$ROOT/.backend.lock.asc"

clear
cat <<'BANNER'
==================================================
  Governed Infrastructure Bootstrap
==================================================
This establishes the control-plane foundation.
Run ONLY from a secure admin machine with
local provider credentials available.

This system ENFORCES:
- explicit backend selection
- template integrity verification
- signed intent (non-repudiation)
- deterministic rebuilds
==================================================
BANNER

echo "Bootstrap version: $VERSION"
echo

pause() {
  read -rp "Press ENTER to continue or CTRL+C to abort..."
}

fatal() {
  echo
  echo "FATAL: $1"
  exit 1
}

pause

### STEP 1 — Backend lock state
if [[ -f "$LOCK" ]]; then
  echo "Backend already locked:"
  echo
  sed 's/^/  /' "$LOCK"
  echo
else
  echo "No backend configured."
  echo
  pause
  "$ROOT/scripts/select-backend.sh"
fi

### STEP 2 — Verify backend integrity
echo
echo "Verifying backend integrity and signature..."
"$ROOT/scripts/verify-backend-lock.sh" || fatal "Backend verification failed"

### STEP 3 — Validate environment
echo
echo "Validating backend requirements..."
"$ROOT/scripts/validate-backend.sh" || fatal "Environment validation failed"

### STEP 4 — Terraform init gate
echo
pause
cd "$ROOT/infra/bootstrap"

echo "Running terraform init (backend is now immutable)..."
terraform init -input=false

### STEP 5 — Execution mode
echo
echo "Select execution mode:"
echo "  1) Plan only (safe, default)"
echo "  2) Apply (requires explicit confirmation)"
echo

read -rp "Choice [1/2]: " MODE

case "$MODE" in
  1)
    echo "Running terraform plan..."
    terraform plan
    ;;
  2)
    echo
    TOKEN="$(openssl rand -hex 3)"
    echo "To confirm APPLY, type the token: $TOKEN"
    read -rp "> " CONFIRM
    [[ "$CONFIRM" == "$TOKEN" ]] || fatal "Confirmation failed"

    echo
    echo "FINAL WARNING:"
    echo "This will modify foundational infrastructure."
    echo "This action WILL be auditable."
    echo
    read -rp "Type APPLY to proceed: " FINAL
    [[ "$FINAL" == "APPLY" ]] || fatal "Apply aborted"

    terraform apply
    ;;
  *)
    fatal "Invalid selection"
    ;;
esac

echo
echo "Bootstrap completed successfully."
echo "Control plane is governed under version $VERSION."
