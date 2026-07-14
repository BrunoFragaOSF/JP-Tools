#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TOOLS_DIR="$SCRIPT_DIR/tools"
RUNTIME_DIR="$SCRIPT_DIR/runtime"
LOCK_PATH="$SCRIPT_DIR/dependencies.lock.json"
BIN_DIR="$HOME/bin"

for required in "$LOCK_PATH" "$RUNTIME_DIR/package.json"; do
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

remove_node24_path_line() {
    local file="$1"
    [ -f "$file" ] || return 0
    local tmp="$file.jp-tools-node-clean"
    grep -Ev '^export PATH="[^"]*/opt/node@24/bin:\$PATH"$' "$file" > "$tmp" || true
    mv "$tmp" "$file"
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

export HOMEBREW_NO_ENV_HINTS=1

echo "Atualizando o catalogo oficial do Homebrew..."
brew update
export HOMEBREW_NO_AUTO_UPDATE=1

echo "Validando hashes das ferramentas independentes..."
/usr/bin/ruby "$SCRIPT_DIR/scripts/verify-macos-dependencies.rb" preflight "$LOCK_PATH"

LOCKED_FORMULAE=()
while IFS= read -r formula; do
    LOCKED_FORMULAE+=("$formula")
done < <(/usr/bin/ruby -rjson -e 'puts JSON.parse(File.read(ARGV[0])).dig("macos", "lockedFormulae").keys.sort' "$LOCK_PATH")

LOCKED_NAMES=" ${LOCKED_FORMULAE[*]} "
PINNED_NAMES=" $(brew list --pinned | tr '\n' ' ') "
FORMULAE_TO_UNPIN=()
while IFS= read -r formula; do
    if [[ "$LOCKED_NAMES" != *" $formula "* ]] && [[ "$PINNED_NAMES" == *" $formula "* ]]; then
        FORMULAE_TO_UNPIN+=("$formula")
    fi
done < <(/usr/bin/ruby -rjson -e 'puts JSON.parse(File.read(ARGV[0])).dig("migration", "unpinFormulae")' "$LOCK_PATH")
if [ "${#FORMULAE_TO_UNPIN[@]}" -gt 0 ]; then
    echo "Liberando pins antigos: ${FORMULAE_TO_UNPIN[*]}"
    brew unpin "${FORMULAE_TO_UNPIN[@]}"
fi

brew unpin node@24 2>/dev/null || true
if brew list --versions node@24 >/dev/null 2>&1; then
    echo "Migrando node@24 para o Node atualizado normalmente..."
    brew uninstall --ignore-dependencies node@24 2>/dev/null || true
fi

remove_node24_path_line "$HOME/.zshrc"
remove_node24_path_line "$HOME/.bash_profile"
remove_node24_path_line "$HOME/.bashrc"

BREW_PREFIX="$(brew --prefix)"
if ! brew list --versions node >/dev/null 2>&1 && [ ! -e "$BREW_PREFIX/bin/node" ]; then
    rm -rf "$BREW_PREFIX/lib/node_modules/npm" "$BREW_PREFIX/lib/node_modules/corepack"
    rm -f "$BREW_PREFIX/bin/npm" "$BREW_PREFIX/bin/npx" "$BREW_PREFIX/bin/corepack"
fi

echo "Instalando dependencias..."
if ! brew install --yes node webp "${LOCKED_FORMULAE[@]}"; then
    echo "O Homebrew informou um problema. O ambiente instalado sera validado antes de continuar."
fi

brew unpin node webp 2>/dev/null || true
PINNED_NAMES=" $(brew list --pinned | tr '\n' ' ') "
for formula in "${LOCKED_FORMULAE[@]}"; do
    if brew list --versions "$formula" >/dev/null 2>&1 && [[ "$PINNED_NAMES" != *" $formula "* ]]; then
        brew pin "$formula"
    fi
done

/usr/bin/ruby "$SCRIPT_DIR/scripts/verify-macos-dependencies.rb" installed "$LOCK_PATH"

add_path_line "$HOME/.zshrc" 'export PATH="$HOME/bin:$PATH"'
add_path_line "$HOME/.bash_profile" 'export PATH="$HOME/bin:$PATH"'
add_path_line "$HOME/.bashrc" 'export PATH="$HOME/bin:$PATH"'

export PATH="$HOME/bin:$BREW_PREFIX/bin:$BREW_PREFIX/sbin:$PATH"
hash -r

if ! command -v node >/dev/null 2>&1 || ! command -v npm >/dev/null 2>&1; then
    echo "JP Tools error: Node/npm nao foram encontrados apos a instalacao."
    exit 1
fi

EXPECTED_FFMPEG_VERSION="$(/usr/bin/ruby -rjson -e 'puts JSON.parse(File.read(ARGV[0])).dig("macos", "lockedFormulae", "ffmpeg", "version")' "$LOCK_PATH")"
if ! ffmpeg -version 2>/dev/null | head -n 1 | grep -Fq "ffmpeg version $EXPECTED_FFMPEG_VERSION"; then
    echo "JP Tools error: o executavel FFmpeg nao corresponde a versao $EXPECTED_FFMPEG_VERSION."
    exit 1
fi

EXPECTED_IMAGEMAGICK_VERSION="$(/usr/bin/ruby -rjson -e 'puts JSON.parse(File.read(ARGV[0])).dig("macos", "lockedFormulae", "imagemagick", "version")' "$LOCK_PATH")"
if ! magick -version 2>/dev/null | head -n 1 | grep -Fq "ImageMagick $EXPECTED_IMAGEMAGICK_VERSION"; then
    echo "JP Tools error: o executavel ImageMagick nao corresponde a versao $EXPECTED_IMAGEMAGICK_VERSION."
    exit 1
fi

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

rm -rf "$BIN_DIR/node_modules"
rm -f "$BIN_DIR/package-lock.json"
cp "$RUNTIME_DIR/package.json" "$BIN_DIR/package.json"
cp "$LOCK_PATH" "$BIN_DIR/jp-tools-dependencies.lock.json"

ln -sf "$BIN_DIR/jp-capture" "$BIN_DIR/jp-capture-remove"
ln -sf "$BIN_DIR/jp-poster" "$BIN_DIR/jp-poster-remove"
ln -sf "$BIN_DIR/jp-compress" "$BIN_DIR/jp-compress-original"
ln -sf "$BIN_DIR/jp-compress" "$BIN_DIR/jp-compress-original-remove"

echo "Instalando as versoes atuais de Playwright e Chromium..."
npm install --prefix "$BIN_DIR" --save-exact playwright@latest --ignore-scripts --no-audit --no-fund
node "$BIN_DIR/node_modules/playwright/cli.js" install chromium
node "$SCRIPT_DIR/scripts/verify-runtime.js" "$BIN_DIR"

PLAYWRIGHT_VERSION="$(node -p "require('$BIN_DIR/node_modules/playwright/package.json').version")"

echo ""
echo "JP Tools instalado. Abra um novo terminal do VSCode ou rode: source ~/.zshrc"
echo "Node $(node --version) | Playwright $PLAYWRIGHT_VERSION"
echo "Ferramentas independentes conferidas pelo lock da versao 1.2.3."
echo "Teste com: jp-help"
