#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TOOLS_DIR="$SCRIPT_DIR/tools"
RUNTIME_DIR="$SCRIPT_DIR/runtime"
LOCK_PATH="$SCRIPT_DIR/dependencies.lock.json"
BIN_DIR="$HOME/bin"
NODE_FORMULA="node@24"

for required in "$LOCK_PATH" "$RUNTIME_DIR/package.json" "$RUNTIME_DIR/package-lock.json"; do
    if [ ! -f "$required" ]; then
        echo "JP Tools error: arquivo obrigatorio ausente: $required"
        exit 1
    fi
done

add_path_line() {
    local file="$1"
    local line="$2"
    touch "$file"
    if ! grep -Fqx "$line" "$file"; then
        printf '\n%s\n' "$line" >> "$file"
    fi
}

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

export HOMEBREW_NO_AUTO_UPDATE=1
export HOMEBREW_NO_ENV_HINTS=1

echo "Validando versoes, formulas e hashes homologados..."
/usr/bin/ruby "$SCRIPT_DIR/scripts/verify-macos-dependencies.rb" preflight "$LOCK_PATH"

BREW_FORMULAE=()
while IFS= read -r formula; do
    BREW_FORMULAE+=("$formula")
done < <(/usr/bin/ruby -rjson -e 'puts JSON.parse(File.read(ARGV[0])).fetch("macos").fetch("formulae").keys.sort' "$LOCK_PATH")

echo "Instalando a arvore Homebrew homologada..."
brew install "${BREW_FORMULAE[@]}"

for formula in "${BREW_FORMULAE[@]}"; do
    brew pin "$formula"
done

/usr/bin/ruby "$SCRIPT_DIR/scripts/verify-macos-dependencies.rb" installed "$LOCK_PATH"

NODE_BIN="$(brew --prefix "$NODE_FORMULA")/bin"
NODE_PATH_LINE="export PATH=\"$NODE_BIN:\$PATH\""

add_path_line "$HOME/.zshrc" 'export PATH="$HOME/bin:$PATH"'
add_path_line "$HOME/.bash_profile" 'export PATH="$HOME/bin:$PATH"'
add_path_line "$HOME/.bashrc" 'export PATH="$HOME/bin:$PATH"'
add_path_line "$HOME/.zshrc" "$NODE_PATH_LINE"
add_path_line "$HOME/.bash_profile" "$NODE_PATH_LINE"
add_path_line "$HOME/.bashrc" "$NODE_PATH_LINE"

export PATH="$NODE_BIN:$HOME/bin:/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin:/usr/local/sbin:$PATH"
hash -r

EXPECTED_NODE_VERSION="$(/usr/bin/ruby -rjson -e 'puts JSON.parse(File.read(ARGV[0])).dig("macos", "formulae", "node@24", "version")' "$LOCK_PATH")"
if [ "$(node --version)" != "v$EXPECTED_NODE_VERSION" ]; then
    echo "JP Tools error: Node $(node --version) instalado, esperado v$EXPECTED_NODE_VERSION."
    exit 1
fi

EXPECTED_FFMPEG_VERSION="$(/usr/bin/ruby -rjson -e 'puts JSON.parse(File.read(ARGV[0])).dig("macos", "formulae", "ffmpeg", "version")' "$LOCK_PATH")"
if ! ffmpeg -version 2>/dev/null | head -n 1 | grep -Fq "ffmpeg version $EXPECTED_FFMPEG_VERSION"; then
    echo "JP Tools error: o executavel FFmpeg nao corresponde a versao $EXPECTED_FFMPEG_VERSION."
    exit 1
fi

EXPECTED_IMAGEMAGICK_VERSION="$(/usr/bin/ruby -rjson -e 'puts JSON.parse(File.read(ARGV[0])).dig("macos", "formulae", "imagemagick", "version")' "$LOCK_PATH")"
if ! magick -version 2>/dev/null | head -n 1 | grep -Fq "ImageMagick $EXPECTED_IMAGEMAGICK_VERSION"; then
    echo "JP Tools error: o executavel ImageMagick nao corresponde a versao $EXPECTED_IMAGEMAGICK_VERSION."
    exit 1
fi

if ! command -v npm >/dev/null 2>&1; then
    echo "JP Tools error: npm nao foi encontrado no Node homologado."
    exit 1
fi

node "$SCRIPT_DIR/scripts/verify-runtime.js" --lock-only "$RUNTIME_DIR" "$LOCK_PATH"

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

cp "$RUNTIME_DIR/package.json" "$BIN_DIR/package.json"
cp "$RUNTIME_DIR/package-lock.json" "$BIN_DIR/package-lock.json"
cp "$LOCK_PATH" "$BIN_DIR/jp-tools-dependencies.lock.json"

ln -sf "$BIN_DIR/jp-capture" "$BIN_DIR/jp-capture-remove"
ln -sf "$BIN_DIR/jp-poster" "$BIN_DIR/jp-poster-remove"
ln -sf "$BIN_DIR/jp-compress" "$BIN_DIR/jp-compress-original"
ln -sf "$BIN_DIR/jp-compress" "$BIN_DIR/jp-compress-original-remove"

PLAYWRIGHT_VERSION="$(/usr/bin/ruby -rjson -e 'puts JSON.parse(File.read(ARGV[0])).dig("npmRuntime", "playwright", "version")' "$LOCK_PATH")"
echo "Instalando o runtime npm fechado do JP Tools..."
npm ci --prefix "$BIN_DIR" --ignore-scripts --no-audit --no-fund
node "$BIN_DIR/node_modules/playwright/cli.js" install chromium
node "$SCRIPT_DIR/scripts/verify-runtime.js" "$BIN_DIR" "$LOCK_PATH"

echo ""
echo "JP Tools instalado. Abra um novo terminal do VSCode ou rode: source ~/.zshrc"
echo "Todas as dependencias foram conferidas com o lock da versao 1.2.4."
echo "Node $EXPECTED_NODE_VERSION | Playwright $PLAYWRIGHT_VERSION"
echo "Teste com: jp-help"
