#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

echo "== Setting up GCP governed backend =="
echo

mkdir -p "$ROOT/backend_templates"

cat > "$ROOT/backend_templates/gcp.tf" <<'EOF'
terraform {
  backend "gcs" {
    bucket  = "REPLACE_ME"
    prefix  = "terraform/state/bootstrap"
  }
}
EOF

# --- extend backend selector ---
grep -q 'gcp)' "$ROOT/scripts/select-backend.sh" 2>/dev/null || \
sed -i '/case "\$BACKEND"/a\
  gcp)\n\
    TEMPLATE="backend_templates/gcp.tf"\n\
    ;;\n' "$ROOT/scripts/select-backend.sh" 2>/dev/null || true

# --- extend backend validator ---
grep -q 'backend \"gcs\"' "$ROOT/scripts/validate-backend.sh" 2>/dev/null || \
sed -i '/Unknown backend/i\
if grep -q \"backend \\\"gcs\\\"\" \"$TARGET\"; then\n\
  echo \"GCP GCS backend validated\"\n\
  exit 0\n\
fi\n' "$ROOT/scripts/validate-backend.sh" 2>/dev/null || true

echo
echo "GCP backend template added."
echo "Reminder:"
echo "  - Replace bucket before first bootstrap"
echo "  - Ensure bucket has versioning + uniform access"
echo
echo "Next:"
echo "  git add backend_templates scripts"
echo "  git commit -m \"Add governed GCP backend support\""
