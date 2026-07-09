#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

echo "Iniciando JP Tools Installer em: $SCRIPT_DIR"

xattr -dr com.apple.quarantine "$SCRIPT_DIR" 2>/dev/null || true
chmod +x "$SCRIPT_DIR/INSTALL-MAC.command" "$SCRIPT_DIR/scripts/install-mac.command" 2>/dev/null || true

exec /bin/bash "$SCRIPT_DIR/scripts/install-mac.command"
