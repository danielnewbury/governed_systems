#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
POLICY="$ROOT/policy/provider-parity.yaml"
LOCK="$ROOT/.backend.lock"

command -v yq >/dev/null || {
  echo "FATAL: yq is required for parity enforcement"
  exit 1
}

[[ -f "$LOCK" ]] || {
  echo "FATAL: backend lock missing"
  exit 1
}

# shellcheck disable=SC1090
source <(sed 's/^/export /' "$LOCK")

[[ -n "${backend:-}" ]] || { echo "FATAL: backend not defined"; exit 1; }
[[ -n "${region:-}" ]] || { echo "FATAL: region not defined in backend lock"; exit 1; }
[[ -n "${system_name:-}" ]] || { echo "FATAL: system_name not defined"; exit 1; }

### REGION PARITY
allowed_regions=$(yq ".regions.${backend}[]" "$POLICY" 2>/dev/null || true)

echo "$allowed_regions" | grep -qx "$region" || {
  echo "FATAL: region '$region' not allowed for provider '$backend'"
  echo "Allowed:"
  echo "$allowed_regions" | sed 's/^/  - /'
  exit 1
}

### NAMING PARITY
pattern=$(yq ".naming.pattern" "$POLICY")

if ! [[ "$system_name" =~ $pattern ]]; then
  echo "FATAL: system_name violates naming policy"
  echo "Given:    $system_name"
  echo "Expected: $pattern"
  exit 1
fi

echo "Provider parity enforcement passed:"
echo "  backend=$backend"
echo "  region=$region"
echo "  system_name=$system_name"
