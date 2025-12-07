#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

echo "== Setting up AWS governed backend =="
echo

mkdir -p "$ROOT/backend_templates"

cat > "$ROOT/backend_templates/aws.tf" <<'EOF'
terraform {
  backend "s3" {
    bucket         = "REPLACE_ME"
    key            = "terraform/state/bootstrap.tfstate"
    region         = "REPLACE_ME"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}
EOF

# --- extend backend selector ---
grep -q 'aws)' "$ROOT/scripts/select-backend.sh" 2>/dev/null || \
sed -i '/case "\$BACKEND"/a\
  aws)\n\
    TEMPLATE="backend_templates/aws.tf"\n\
    ;;\n' "$ROOT/scripts/select-backend.sh" 2>/dev/null || true

# --- extend backend validator ---
grep -q 'backend \"s3\"' "$ROOT/scripts/validate-backend.sh" 2>/dev/null || \
sed -i '/Unknown backend/i\
if grep -q \"backend \\\"s3\\\"\" \"$TARGET\"; then\n\
  echo \"AWS S3 backend validated\"\n\
  exit 0\n\
fi\n' "$ROOT/scripts/validate-backend.sh" 2>/dev/null || true

echo
echo "AWS backend template added."
echo "Reminder:"
echo "  - Replace bucket / region before first bootstrap"
echo "  - Ensure DynamoDB table exists"
echo
echo "Next:"
echo "  git add backend_templates scripts"
echo "  git commit -m \"Add governed AWS backend support\""
