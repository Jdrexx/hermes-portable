#!/usr/bin/env bash
# Unlock the encrypted Hermes vault that sits NEXT TO this script (e.g. on a
# USB stick). The decrypted view is mounted to a LOCAL directory on this
# machine — FUSE cannot mount onto a directory inside a FAT/exFAT stick.
# Nothing plaintext is written to the host disk; the mountpoint is a live
# virtual view of the encrypted files, which stay on the stick.
#
# Usage:  bash open-hermes-vault.sh
#         HERMES_MOUNT=/custom/path bash open-hermes-vault.sh
set -euo pipefail

SOURCE="${BASH_SOURCE[0]}"
while [ -L "$SOURCE" ]; do
	DIR="$(cd -P "$(dirname "$SOURCE")" && pwd)"
	SOURCE="$(readlink "$SOURCE")"
	[[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
done
HERE="$(cd -P "$(dirname "$SOURCE")" && pwd)"

VAULT="$HERE/hermes-portable.vault"
MOUNT="${HERMES_MOUNT:-$HOME/hermes-portable.open}" # local mountpoint

# Find gocryptfs: bundled next to this script, then PATH, then ~/.local/bin
GOCRYPTFS=""
for c in "$HERE/gocryptfs" "$(command -v gocryptfs 2>/dev/null || true)" "$HOME/.local/bin/gocryptfs"; do
	if [ -n "$c" ] && [ -x "$c" ]; then
		GOCRYPTFS="$c"
		break
	fi
done
if [ -z "$GOCRYPTFS" ] && [ -f "$HERE/gocryptfs" ]; then
	chmod +x "$HERE/gocryptfs" 2>/dev/null || true # exFAT drops the +x bit
	GOCRYPTFS="$HERE/gocryptfs"
fi
if [ -z "$GOCRYPTFS" ]; then
	echo "ERROR: gocryptfs not found (looked next to this script, on PATH, and in ~/.local/bin)."
	echo "Get a static build: https://github.com/rfjakob/gocryptfs/releases"
	exit 1
fi

[ -f "$VAULT/gocryptfs.conf" ] || {
	echo "ERROR: no vault found at $VAULT (run ./encrypt-stick.sh first)"
	exit 1
}
mkdir -p "$MOUNT"
if mountpoint -q "$MOUNT" 2>/dev/null; then
	echo "Already open at $MOUNT"
	exit 0
fi

"$GOCRYPTFS" "$VAULT" "$MOUNT"
echo "Open at: $MOUNT   (lock it with ./close-hermes-vault.sh)"