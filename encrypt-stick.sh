#!/usr/bin/env bash
# One-time setup: turn the plaintext files on this stick into an encrypted
# gocryptfs vault. Run this ONCE, from the stick, after you've placed your
# .env / auth.json / hermes-default.tar.gz / state.db next to it.
#
# It creates hermes-portable.vault/ (ciphertext) and moves your sensitive
# files into it. After that, use ./open-hermes-vault.sh to work with them.
#
# Usage:  bash encrypt-stick.sh
set -euo pipefail

SOURCE="${BASH_SOURCE[0]}"
while [ -L "$SOURCE" ]; do
	DIR="$(cd -P "$(dirname "$SOURCE")" && pwd)"
	SOURCE="$(readlink "$SOURCE")"
	[[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
done
HERE="$(cd -P "$(dirname "$SOURCE")" && pwd)"

VAULT="$HERE/hermes-portable.vault"
MOUNT="${HERMES_MOUNT:-$HOME/hermes-portable.open}"

GOCRYPTFS=""
for c in "$HERE/gocryptfs" "$(command -v gocryptfs 2>/dev/null || true)" "$HOME/.local/bin/gocryptfs"; do
	if [ -n "$c" ] && [ -x "$c" ]; then
		GOCRYPTFS="$c"
		break
	fi
done
if [ -z "$GOCRYPTFS" ] && [ -f "$HERE/gocryptfs" ]; then
	chmod +x "$HERE/gocryptfs" 2>/dev/null || true
	GOCRYPTFS="$HERE/gocryptfs"
fi
[ -n "$GOCRYPTFS" ] || {
	echo "ERROR: gocryptfs not found. Get it: https://github.com/rfjakob/gocryptfs/releases"
	exit 1
}

if [ -f "$VAULT/gocryptfs.conf" ]; then
	echo "A vault already exists at $VAULT — nothing to do."
	echo "Open it with ./open-hermes-vault.sh"
	exit 0
fi

echo "This will create an encrypted vault and move your sensitive files into it."
echo "Choose a STRONG passphrase and store it in a password manager — if you"
echo "lose it, the data is unrecoverable. There is no backdoor."
echo ""
mkdir -p "$VAULT"
"$GOCRYPTFS" -init "$VAULT" # prompts for a passphrase (twice)

mkdir -p "$MOUNT"
"$GOCRYPTFS" "$VAULT" "$MOUNT" # prompts for the passphrase you just set

# Move sensitive payload into the encrypted view
moved=0
for item in .env auth.json hermes-default.tar.gz state.db state.db-wal state.db-shm run-hermes bootstrap.sh README.md; do
	if [ -e "$HERE/$item" ]; then
		mv "$HERE/$item" "$MOUNT/"
		echo "  encrypted: $item"
		moved=$((moved + 1))
	fi
done

UNMOUNT="$(command -v fusermount3 || command -v fusermount)"
if [ -z "$UNMOUNT" ]; then
	echo "ERROR: neither fusermount3 nor fusermount found — cannot unmount."
	exit 1
fi
"$UNMOUNT" -u "$MOUNT"
echo ""
echo "Done — $moved item(s) are now encrypted inside hermes-portable.vault/."
echo "From now on: ./open-hermes-vault.sh  →  work  →  ./close-hermes-vault.sh"