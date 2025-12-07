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
