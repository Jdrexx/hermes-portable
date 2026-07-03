#!/usr/bin/env bash
set -euo pipefail

# Resolve the script directory portably (readlink -f is missing on older macOS)
SOURCE="${BASH_SOURCE[0]}"
while [ -L "$SOURCE" ]; do
    DIR="$(cd -P "$(dirname "$SOURCE")" && pwd)"
    SOURCE="$(readlink "$SOURCE")"
    [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
done
SCRIPT_DIR="$(cd -P "$(dirname "$SOURCE")" && pwd)"
cd "$SCRIPT_DIR"

echo "============================================"
echo "  Portable Hermes — First Run Bootstrap"
echo "============================================"
echo ""

# ── 1. Detect OS / Arch ──────────────────────────────────────────
OS="$(uname -s)"
ARCH="$(uname -m)"
echo "[1/5] Detected: $OS / $ARCH"

# ── 2. Check Python 3.10+ ────────────────────────────────────────
echo "[2/5] Checking Python..."
PYTHON=""
for candidate in python3 python; do
    if command -v "$candidate" &>/dev/null; then
        if "$candidate" -c 'import sys; sys.exit(0 if sys.version_info >= (3, 10) else 1)' 2>/dev/null; then
            PYTHON="$candidate"
            echo "       Found $candidate $("$candidate" -c 'import sys; print(".".join(map(str, sys.version_info[:2])))')"
            break
        fi
    fi
done
if [ -z "$PYTHON" ]; then
    echo "ERROR: Python 3.10+ is required. Install it first."
    echo "       https://www.python.org/downloads/"
    exit 1
fi

# ── 3. Get uv (bundled copy, or download the right one for this OS) ──
echo "[3/5] Checking uv..."
UV="$SCRIPT_DIR/uv"
if [ -x "$UV" ] && "$UV" --version &>/dev/null; then
    echo "       Using bundled uv $("$UV" --version | awk '{print $2}')"
else
    echo "       Downloading uv for $OS/$ARCH..."
    curl -LsSf https://astral.sh/uv/install.sh | env UV_UNMANAGED_INSTALL="$SCRIPT_DIR" sh
    "$UV" --version >/dev/null
    echo "       Done."
fi

# ── 4. Install Hermes engine onto the stick ──────────────────────
echo "[4/5] Installing Hermes Agent via uv..."
export UV_TOOL_DIR="$SCRIPT_DIR/.uv-tools"
export UV_TOOL_BIN_DIR="$SCRIPT_DIR/.uv-tools/bin"
export UV_CACHE_DIR="$SCRIPT_DIR/.uv-cache"
mkdir -p "$UV_TOOL_DIR" "$UV_TOOL_BIN_DIR" "$UV_CACHE_DIR"

if "$UV" tool list 2>/dev/null | grep -q '^hermes-agent '; then
    echo "       Hermes already installed — upgrading..."
    "$UV" tool upgrade hermes-agent
else
    "$UV" tool install hermes-agent
fi
echo "       Done."

# ── 5. Unpack profile into data/ (if you exported one) ───────────
echo "[5/5] Seeding profile and configuration..."
if [ -d "$SCRIPT_DIR/data" ]; then
    echo "       data/ already exists — skipping unpack."
elif [ -f "$SCRIPT_DIR/hermes-default.tar.gz" ]; then
    tar xzf "$SCRIPT_DIR/hermes-default.tar.gz"
    mv default data/
    echo "       Extracted profile to data/"
else
    mkdir -p "$SCRIPT_DIR/data"
    echo "       No hermes-default.tar.gz found — starting with a fresh profile."
    echo "       (Export yours with: hermes profile export default -o hermes-default.tar.gz)"
fi

for f in .env auth.json; do
    if [ -f "$SCRIPT_DIR/$f" ] && [ ! -f "$SCRIPT_DIR/data/$f" ]; then
        cp "$SCRIPT_DIR/$f" "$SCRIPT_DIR/data/$f"
        echo "       Copied $f to data/"
    fi
done

if [ -f "$SCRIPT_DIR/state.db" ] && [ ! -f "$SCRIPT_DIR/data/state.db" ]; then
    cp "$SCRIPT_DIR/state.db" "$SCRIPT_DIR/data/"
    [ -f "$SCRIPT_DIR/state.db-wal" ] && cp "$SCRIPT_DIR/state.db-wal" "$SCRIPT_DIR/data/"
    [ -f "$SCRIPT_DIR/state.db-shm" ] && cp "$SCRIPT_DIR/state.db-shm" "$SCRIPT_DIR/data/"
    echo "       Copied state.db (+ WAL journals) to data/"
fi

echo ""
echo "============================================"
echo "  Bootstrap complete!"
echo "============================================"
echo ""
echo "  Run ./run-hermes to start."
echo ""
