#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

echo "== Setting up LOCAL governed backend (testing only) =="
echo

# -------- directories --------
mkdir -p \
  "$ROOT/scripts" \
  "$ROOT/backend_templates" \
  "$ROOT/infra/bootstrap/state"

# -------- backend template --------
cat > "$ROOT/backend_templates/local.tf" <<'EOF'
terraform {
  backend "local" {
    path = "state/terraform.tfstate"
  }
}
EOF

# -------- select-backend --------
cat > "$ROOT/scripts/select-backend.sh" <<'EOF'
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
EOF

# -------- verify-backend-lock --------
cat > "$ROOT/scripts/verify-backend-lock.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LOCK="$ROOT/.backend.lock"
SIG="$ROOT/.backend.lock.asc"

[[ -f "$LOCK" ]] || { echo "Missing backend lock"; exit 1; }
[[ -f "$SIG" ]] || { echo "Missing backend signature"; exit 1; }

gpg --verify "$SIG" "$LOCK"

TEMPLATE="$(grep '^template=' "$LOCK" | cut -d= -f2)"
EXPECTED="$(grep '^sha256=' "$LOCK" | cut -d= -f2)"

FILE="$ROOT/$TEMPLATE"
[[ -f "$FILE" ]] || { echo "Template missing"; exit 1; }

ACTUAL="$(sha256sum "$FILE" | awk '{print $1}')"
[[ "$EXPECTED" == "$ACTUAL" ]] || { echo "Checksum mismatch"; exit 1; }

echo "Backend lock verified."
EOF

# -------- validate-backend --------
cat > "$ROOT/scripts/validate-backend.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TARGET="$ROOT/infra/bootstrap/backend.tf"

[[ -f "$TARGET" ]] || { echo "backend.tf missing"; exit 1; }

if grep -q 'backend "local"' "$TARGET"; then
  echo "LOCAL backend validated (testing mode)"
  exit 0
fi

echo "Unknown backend"
exit 1
EOF

# -------- permissions --------
chmod +x \
  "$ROOT/scripts/select-backend.sh" \
  "$ROOT/scripts/verify-backend-lock.sh" \
  "$ROOT/scripts/validate-backend.sh"

echo
echo "LOCAL backend scaffolding complete."
echo "Next steps:"
echo "  git add backend_templates scripts infra"
echo "  git commit -m \"Add governed LOCAL backend support\""
