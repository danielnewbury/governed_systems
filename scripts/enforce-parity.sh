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

### REGION PARITY (provider-scoped)
allowed_regions=$(yq -r ".providers.${backend}.regions[]" "$POLICY" 2>/dev/null || true)

[[ -n "$allowed_regions" ]] || {
  echo "FATAL: no regions defined for provider '$backend' in policy"
  exit 1
}

echo "$allowed_regions" | grep -qx "$region" || {
  echo "FATAL: region '$region' not allowed for provider '$backend'"
  echo "Allowed:"
  echo "$allowed_regions" | sed 's/^/  - /'
  exit 1
}

echo "$allowed_regions" | grep -qx "$region" || {
  echo "FATAL: region '$region' not allowed for provider '$backend'"
  echo "Allowed:"
  echo "$allowed_regions" | sed 's/^/  - /'
  exit 1
}


### NAMING PARITY (provider-scoped)
pattern=$(yq -r ".providers.${backend}.naming.pattern" "$POLICY")


[[ -n "$pattern" ]] || {
  echo "FATAL: no naming pattern defined for provider '$backend'"
  exit 1
}

if ! [[ "$system_name" =~ $pattern ]]; then
  echo "FATAL: system_name violates naming policy"
  echo "Given:    $system_name"
  echo "Expected: $pattern"
  exit 1
fi

