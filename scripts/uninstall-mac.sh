#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
LOCK_PATH="$SCRIPT_DIR/dependencies.lock.json"
BIN_DIR="$HOME/bin"
COMMANDS=(
    jp-capture
    jp-capture-remove
    jp-poster
    jp-poster-remove
    jp-compress
    jp-compress-original
    jp-compress-original-remove
    jp-help
    jp-project-roots.js
)

if [ -f "$BIN_DIR/node_modules/playwright/cli.js" ] && command -v node >/dev/null 2>&1; then
    node "$BIN_DIR/node_modules/playwright/cli.js" uninstall chromium 2>/dev/null || true
fi

for cmd in "${COMMANDS[@]}"; do
    rm -f "$BIN_DIR/$cmd"
done

rm -rf "$BIN_DIR/node_modules"
rm -f "$BIN_DIR/package.json" "$BIN_DIR/package-lock.json" "$BIN_DIR/jp-tools-dependencies.lock.json"
rmdir "$BIN_DIR" 2>/dev/null || true

remove_path_line() {
    local file="$1"
    [ -f "$file" ] || return 0
    local tmp="$file.jp-tools-clean"
    grep -Ev '^(export PATH="\$HOME/bin:\$PATH"|export PATH="[^"]*/opt/node@24/bin:\$PATH")$' "$file" > "$tmp" || true
    mv "$tmp" "$file"
}

remove_path_line "$HOME/.zshrc"
remove_path_line "$HOME/.bash_profile"
remove_path_line "$HOME/.bashrc"

# Legacy cleanup for previous installations.
if command -v npm >/dev/null 2>&1; then
    npm uninstall -g playwright 2>/dev/null || true
fi

rm -rf "$HOME/Library/Caches/ms-playwright" 2>/dev/null || true

printf '
JP Tools foi removido.
'
printf 'Remover tambem dependencias instaladas para o JP Tools? Isso pode afetar outros projetos. [y/N] '
read -r answer
case "$answer" in
    y|Y|yes|YES|s|S|sim|SIM)
        if command -v brew >/dev/null 2>&1; then
            BREW_FORMULAE=()
            if [ -f "$LOCK_PATH" ]; then
                while IFS= read -r formula; do
                    BREW_FORMULAE+=("$formula")
                done < <(/usr/bin/ruby -rjson -e 'lock = JSON.parse(File.read(ARGV[0])); puts((lock.dig("macos", "lockedFormulae") || {}).keys + (lock.dig("macos", "dynamicFormulae") || []))' "$LOCK_PATH")
            else
                BREW_FORMULAE=(node ffmpeg jpegoptim pngquant oxipng webp imagemagick)
            fi
            brew unpin node@24 2>/dev/null || true
            brew unpin "${BREW_FORMULAE[@]}" 2>/dev/null || true
            brew uninstall --ignore-dependencies "${BREW_FORMULAE[@]}" 2>/dev/null || true
            brew uninstall --ignore-dependencies node@24 2>/dev/null || true
            brew uninstall --ignore-dependencies node imageoptim-cli 2>/dev/null || true
            brew uninstall --cask imageoptim 2>/dev/null || true
            brew cleanup 2>/dev/null || true
        else
            echo "Homebrew nao encontrado. Dependencias de sistema nao foram removidas."
        fi
        ;;
    *)
        echo "Dependencias mantidas."
        ;;
esac

printf '
Desinstalacao concluida. Abra um novo terminal para atualizar o PATH.
'
