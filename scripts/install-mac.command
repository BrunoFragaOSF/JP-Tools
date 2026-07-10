#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TOOLS_DIR="$SCRIPT_DIR/tools"
BIN_DIR="$HOME/bin"

mkdir -p "$BIN_DIR"

copy_tool() {
    local name="$1"
    rm -f "$BIN_DIR/$name"
    cp "$TOOLS_DIR/$name" "$BIN_DIR/$name"
    chmod +x "$BIN_DIR/$name"
}

copy_tool jp-capture
copy_tool jp-poster
copy_tool jp-compress
copy_tool jp-help
copy_tool jp-project-roots.js

ln -sf "$BIN_DIR/jp-capture" "$BIN_DIR/jp-capture-remove"
ln -sf "$BIN_DIR/jp-poster" "$BIN_DIR/jp-poster-remove"
ln -sf "$BIN_DIR/jp-compress" "$BIN_DIR/jp-compress-original"
ln -sf "$BIN_DIR/jp-compress" "$BIN_DIR/jp-compress-original-remove"

add_path_line() {
    local file="$1"
    touch "$file"
    if ! grep -q 'export PATH="$HOME/bin:$PATH"' "$file"; then
        printf '
export PATH="$HOME/bin:$PATH"
' >> "$file"
    fi
}

add_path_line "$HOME/.zshrc"
add_path_line "$HOME/.bash_profile"
add_path_line "$HOME/.bashrc"

export PATH="$HOME/bin:/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin:/usr/local/sbin:$PATH"

if ! command -v brew >/dev/null 2>&1; then
    echo "Homebrew nao encontrado. Instalando Homebrew..."
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

if [ -x /opt/homebrew/bin/brew ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -x /usr/local/bin/brew ]; then
    eval "$(/usr/local/bin/brew shellenv)"
fi

brew install node ffmpeg jpegoptim pngquant oxipng webp imagemagick imageoptim-cli
brew install --cask imageoptim || true

export PATH="$HOME/bin:/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin:/usr/local/sbin:$PATH"

if ! command -v node >/dev/null 2>&1; then
    echo "Node nao foi encontrado no PATH apos a instalacao. Abra um novo Terminal e rode INSTALL-MAC.command novamente."
    exit 1
fi

if ! command -v npm >/dev/null 2>&1 || ! command -v npx >/dev/null 2>&1; then
    echo "npm/npx nao foram encontrados no PATH apos instalar Node. Abra um novo Terminal e rode INSTALL-MAC.command novamente."
    exit 1
fi

echo "Instalando Playwright e Chromium..."
npm install -g playwright
npx playwright install chromium

GLOBAL_ROOT="$(npm root -g)"
if ! node -e "require(process.argv[1] + '/playwright')" "$GLOBAL_ROOT" >/dev/null 2>&1; then
    echo "Playwright nao ficou acessivel para o Node. Rode: npm install -g playwright && npx playwright install chromium"
    exit 1
fi

echo ""
echo "JP Tools instalado. Abra um novo terminal do VSCode ou rode: source ~/.zshrc"
echo "Teste com: jp-help"
