#!/bin/bash
set -e

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
)

for cmd in "${COMMANDS[@]}"; do
    rm -f "$BIN_DIR/$cmd"
done

rmdir "$BIN_DIR" 2>/dev/null || true

remove_path_line() {
    local file="$1"
    [ -f "$file" ] || return 0
    local tmp="$file.jp-tools-clean"
    grep -vx 'export PATH="$HOME/bin:$PATH"' "$file" > "$tmp" || true
    mv "$tmp" "$file"
}

remove_path_line "$HOME/.zshrc"
remove_path_line "$HOME/.bash_profile"
remove_path_line "$HOME/.bashrc"

if command -v npx >/dev/null 2>&1; then
    npx playwright uninstall chromium 2>/dev/null || true
fi

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
            brew uninstall --ignore-dependencies node ffmpeg jpegoptim pngquant oxipng webp imagemagick imageoptim-cli 2>/dev/null || true
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
