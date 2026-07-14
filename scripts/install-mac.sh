#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TOOLS_DIR="$SCRIPT_DIR/tools"
BIN_DIR="$HOME/bin"
PLAYWRIGHT_VERSION="1.61.1"
NODE_FORMULA="node@24"
FFMPEG_FORMULA="ffmpeg@8"
IMAGEMAGICK_FORMULA="imagemagick@7"
BREW_FORMULAE=(
    "$NODE_FORMULA"
    "$FFMPEG_FORMULA"
    jpegoptim
    pngquant
    oxipng
    webp
    "$IMAGEMAGICK_FORMULA"
)

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
    local line="$2"
    touch "$file"
    if ! grep -Fqx "$line" "$file"; then
        printf '\n%s\n' "$line" >> "$file"
    fi
}

add_path_line "$HOME/.zshrc" 'export PATH="$HOME/bin:$PATH"'
add_path_line "$HOME/.bash_profile" 'export PATH="$HOME/bin:$PATH"'
add_path_line "$HOME/.bashrc" 'export PATH="$HOME/bin:$PATH"'

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

echo "Instalando dependencias homologadas do JP Tools..."
brew install "${BREW_FORMULAE[@]}"

for formula in "${BREW_FORMULAE[@]}"; do
    brew pin "$formula" 2>/dev/null || true
done

NODE_BIN="$(brew --prefix "$NODE_FORMULA")/bin"
NODE_PATH_LINE="export PATH=\"$NODE_BIN:\$PATH\""
add_path_line "$HOME/.zshrc" "$NODE_PATH_LINE"
add_path_line "$HOME/.bash_profile" "$NODE_PATH_LINE"
add_path_line "$HOME/.bashrc" "$NODE_PATH_LINE"

export PATH="$NODE_BIN:$HOME/bin:/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin:/usr/local/sbin:$PATH"
hash -r

if ! command -v node >/dev/null 2>&1; then
    echo "Node nao foi encontrado no PATH apos a instalacao. Abra um novo Terminal e rode novamente o comando de instalacao do README."
    exit 1
fi

if ! command -v npm >/dev/null 2>&1 || ! command -v npx >/dev/null 2>&1; then
    echo "npm/npx nao foram encontrados no PATH apos instalar Node. Abra um novo Terminal e rode novamente o comando de instalacao do README."
    exit 1
fi

case "$(node --version)" in
    v24.*) ;;
    *)
        echo "JP Tools error: Node 24 LTS nao ficou ativo. Versao encontrada: $(node --version)"
        exit 1
        ;;
esac

if ! ffmpeg -version 2>/dev/null | head -n 1 | grep -q 'ffmpeg version 8'; then
    echo "JP Tools error: FFmpeg 8 nao ficou ativo."
    exit 1
fi

if ! magick -version 2>/dev/null | head -n 1 | grep -q 'ImageMagick 7'; then
    echo "JP Tools error: ImageMagick 7 nao ficou ativo."
    exit 1
fi

echo "Instalando Playwright $PLAYWRIGHT_VERSION e o Chromium correspondente..."
npm install -g "playwright@$PLAYWRIGHT_VERSION"
npx --yes "playwright@$PLAYWRIGHT_VERSION" install chromium

GLOBAL_ROOT="$(npm root -g)"
if ! node -e "var pkg=require(process.argv[1] + '/playwright/package.json'); process.exit(pkg.version === process.argv[2] ? 0 : 1)" "$GLOBAL_ROOT" "$PLAYWRIGHT_VERSION" >/dev/null 2>&1; then
    echo "Playwright $PLAYWRIGHT_VERSION nao ficou acessivel para o Node."
    exit 1
fi

echo ""
echo "JP Tools instalado. Abra um novo terminal do VSCode ou rode: source ~/.zshrc"
echo "Dependencias homologadas: Node 24 LTS, Playwright $PLAYWRIGHT_VERSION, FFmpeg 8 e ImageMagick 7."
echo "Teste com: jp-help"
