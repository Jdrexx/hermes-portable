#!/usr/bin/env bash
# Lock the encrypted Hermes vault (unmount the local decrypted view).
#
# Usage:  bash close-hermes-vault.sh
set -euo pipefail
MOUNT="${HERMES_MOUNT:-$HOME/hermes-portable.open}"
if ! mountpoint -q "$MOUNT" 2>/dev/null; then echo "Not mounted."; exit 0; fi
UNMOUNT="$(command -v fusermount3 || command -v fusermount)"
"$UNMOUNT" -u "$MOUNT" && echo "Vault locked."
