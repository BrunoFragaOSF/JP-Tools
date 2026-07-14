#!/bin/bash
set -e

REPOSITORY="BrunoFragaOSF/JP-Tools"
ARCHIVE_URL="${JP_TOOLS_ARCHIVE_URL:-https://github.com/$REPOSITORY/releases/latest/download/JP-Tools.zip}"
TEMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/jp-tools-installer.XXXXXX")"
ARCHIVE_PATH="$TEMP_DIR/JP-Tools.zip"

cleanup() {
    rm -rf "$TEMP_DIR"
}

trap cleanup EXIT INT TERM

echo "JP Tools: baixando o instalador mais recente do GitHub..."
curl -fL --progress-bar --retry 3 --connect-timeout 15 "$ARCHIVE_URL" -o "$ARCHIVE_PATH"

echo "JP Tools: extraindo o pacote..."
/usr/bin/ditto -x -k "$ARCHIVE_PATH" "$TEMP_DIR/package"

PACKAGE_DIR="$(find "$TEMP_DIR/package" -mindepth 1 -maxdepth 1 -type d -name 'JP-Tools-*' -print | head -n 1)"

if [ -z "$PACKAGE_DIR" ] || [ ! -f "$PACKAGE_DIR/scripts/install-mac.sh" ] || [ ! -d "$PACKAGE_DIR/tools" ]; then
    echo "JP Tools error: o pacote baixado nao possui a estrutura esperada." >&2
    echo "Origem: $ARCHIVE_URL" >&2
    exit 1
fi

xattr -dr com.apple.quarantine "$PACKAGE_DIR" 2>/dev/null || true
chmod +x "$PACKAGE_DIR/scripts/install-mac.sh"

if [ "${JP_TOOLS_BOOTSTRAP_TEST:-0}" = "1" ]; then
    echo "JP Tools: pacote validado em modo de teste."
    exit 0
fi

echo "JP Tools: iniciando a instalacao..."
/bin/bash "$PACKAGE_DIR/scripts/install-mac.sh"
