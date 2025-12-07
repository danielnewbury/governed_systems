#!/usr/bin/env bash
set -euo pipefail

echo "=================================================="
echo " Governed GPG Identity Setup"
echo "=================================================="
echo
echo "This will create a cryptographic signing identity"
echo "used to authorize infrastructure bootstrap actions."
echo
echo "This identity:"
echo "  - binds human intent to infrastructure"
echo "  - enables non-repudiation"
echo "  - is REQUIRED for bootstrap"
echo

# --- guard: existing secret keys ---
if gpg --list-secret-keys >/dev/null 2>&1 && \
   [ "$(gpg --list-secret-keys 2>/dev/null | grep -c '^sec')" -gt 0 ]; then
  echo "WARNING: Existing GPG secret key(s) detected."
  echo
  echo "Fingerprint(s):"
  gpg --list-secret-keys --with-colons | awk -F: '/^fpr:/ {print "  " $10}'
  echo
  read -p "Use existing key? (y/N): " USE_EXISTING
  case "${USE_EXISTING:-n}" in
    y|Y)
      echo "Using existing GPG identity."
      ;;
    *)
      echo "Aborting to prevent accidental key misuse."
      exit 1
      ;;
  esac
else
  echo "No existing GPG secret keys found."
  echo
  echo "Launching guided GPG key generation..."
  echo
  echo "RECOMMENDED SETTINGS:"
  echo "  - Type: RSA and RSA"
  echo "  - Size: 4096"
  echo "  - Expiration: 1y or 2y (not never)"
  echo "  - Name/Email: accountable identity"
  echo
  read -p "Press ENTER to continue or CTRL+C to abort..."

  gpg --full-generate-key
fi

echo
echo "--------------------------------------------------"
echo " Configuring environment"
echo "--------------------------------------------------"

export GPG_TTY="$(tty)"

# Persist for future shells if possible
if ! grep -q "GPG_TTY" ~/.bashrc 2>/dev/null; then
  echo 'export GPG_TTY=$(tty)' >> ~/.bashrc
fi

echo
echo "Available secret keys:"
gpg --list-secret-keys --keyid-format=long

echo
read -p "Enter key ID to use for infrastructure signing: " KEYID

if [ -z "$KEYID" ]; then
  echo "FATAL: No key ID provided."
  exit 1
fi

# Configure git signing (recommended)
git config --global user.signingkey "$KEYID"
git config --global commit.gpgsign true

echo
echo "Selected signing key:"
gpg --fingerprint "$KEYID"

echo
echo "=================================================="
echo " GPG identity ready"
echo "=================================================="
echo
echo "Next step:"
echo "  ./bootstrap.sh"
echo
echo "This identity will be used to sign backend intent."
