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
