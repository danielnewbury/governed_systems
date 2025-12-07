#!/usr/bin/env bash
set -euo pipefail

VERSION="1.0.0"
TAG="v${VERSION}"
MSG="Governed control-plane bootstrap v${VERSION}"

fatal() {
  echo "FATAL: $1"
  exit 1
}

echo "== Release preparation for ${TAG} =="
echo

# 1. Ensure git repo is clean
if [[ -n "$(git status --porcelain)" ]]; then
  fatal "Git working tree is not clean. Commit or stash changes first."
fi

# 2. Create VERSION file
if [[ -f VERSION ]]; then
  EXISTING="$(cat VERSION)"
  if [[ "$EXISTING" != "$VERSION" ]]; then
    fatal "VERSION file exists with value '$EXISTING' (expected '$VERSION')"
  fi
else
  echo "Creating VERSION file..."
  echo "$VERSION" > VERSION
fi

# 3. Ensure .gitignore contains required entries
GITIGNORE=".gitignore"
touch "$GITIGNORE"

ensure_gitignore() {
  local entry="$1"
  if ! grep -qxF "$entry" "$GITIGNORE"; then
    echo "Adding '$entry' to .gitignore"
    echo "$entry" >> "$GITIGNORE"
  fi
}

ensure_gitignore ".backend.lock"
ensure_gitignore ".backend.lock.asc"
ensure_gitignore "infra/bootstrap/backend.tf"

# 4. Commit changes if needed
if [[ -n "$(git status --porcelain)" ]]; then
  echo
  echo "Committing release preparation artifacts..."
  git add VERSION "$GITIGNORE"
  git commit -m "Prepare ${TAG} release artifacts"
fi

# 5. Ensure tag does not already exist
if git rev-parse "$TAG" >/dev/null 2>&1; then
  fatal "Git tag '${TAG}' already exists."
fi

# 6. Create annotated tag
echo
echo "Creating annotated tag ${TAG}..."
git tag -a "$TAG" -m "$MSG"

echo
echo "Release ${TAG} prepared successfully."
echo
echo "Next step (manual):"
echo "  git push origin ${TAG}"
