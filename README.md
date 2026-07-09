# JP Tools Installer

Use apenas um destes arquivos:

- `INSTALL-MAC.command` para instalar no Mac.
- `INSTALL-WINDOWS.bat` para instalar no Windows.
- `UNINSTALL-MAC.command` para remover do Mac.
- `UNINSTALL-WINDOWS.bat` para remover do Windows.

Os arquivos tecnicos ficam nas pastas `scripts` e `tools`; normalmente ninguem precisa abrir essas pastas.

## O que instala

- `jp-capture`
- `jp-capture-remove`
- `jp-poster`
- `jp-poster-remove`
- `jp-compress`
- `jp-compress-original`
- `jp-compress-original-remove`
- `jp-help`

O instalador tambem tenta instalar as dependencias necessarias: Node.js, FFmpeg, ImageMagick, Playwright, Chromium e otimizadores de imagem. O jp-compress salva os originais em .jp-compress-original ao lado de index.html/banner.

## Mac

Duas formas:

1. Clique duas vezes em `INSTALL-MAC.command`.
2. Se o macOS bloquear, abra o Terminal dentro da pasta e rode:

```bash
xattr -dr com.apple.quarantine .
chmod +x INSTALL-MAC.command scripts/install-mac.command
bash INSTALL-MAC.command
```

## Windows

Clique duas vezes em:

```text
INSTALL-WINDOWS.bat
```

Se Node acabou de ser instalado e ainda nao entrou no PATH da janela atual, o instalador procura os caminhos padrao automaticamente. Se ainda assim falhar, abra um novo terminal e rode `INSTALL-WINDOWS.bat` novamente.

## Desinstalar

Use:

- `UNINSTALL-MAC.command` no Mac.
- `UNINSTALL-WINDOWS.bat` no Windows.

O desinstalador remove o JP Tools e pergunta antes de remover dependencias como Node, FFmpeg, ImageMagick, Playwright e Chromium, porque elas podem estar sendo usadas por outros projetos.

## Teste apos instalar

Abra um terminal novo e rode:

```bash
jp-help
```

## Filtros avancados


Padrao direto de comandos e filtros:

- O `jp-help` tenta detectar as pastas/versoes e imagens da pasta atual para mostrar exemplos reais do projeto. Quando nao encontra estrutura conhecida, usa exemplos genericos.
- As mensagens de erro tambem tentam sugerir exemplos reais da pasta atual.

- A ordem importa: comando, depois opcoes fixas, depois filtro. Exemplo: `jp-capture msk 3 EN/V1`, nao `jp-capture EN/V1 3 msk`.

- Pasta/versao usa barra para niveis e case exato: `EN/V1`, `FR/Product_Test`, `DE`. `EN V1` nao equivale a `EN/V1`, e `en/v1` nao equivale a `EN/V1`.
- Varios grupos usam `--and`: `DE --and EN/V1 --and FR/Product_Test`.
- Exclusoes usam `--not`: `EN/V1 --and FR/Product_Test --not DE/Simulated_DSK`.
- No `jp-compress`, filtro de imagem precisa do nome completo, extensao, case exato e precisa existir: `CTA.png`, `chat-2.jpg`. `CTA` sozinho nao seleciona `CTA.png`, e `TEXT-1.png` nao seleciona `text-1.png`.

```bash
jp-capture EN/V1 --and FR/Product_Test --not DE/Simulated_DSK
jp-poster 16x9 2 EN/V1 --and NL/V2
jp-compress 80 EN/V1 CTA.png --and NL/V2 chat-2.png
jp-compress 80 EN/V1 CTA.png --and FR/Product_Test Banner.jpg
jp-compress-original FR/Product_Test --not Logo.png, Cta.png --and NL/V2 --not Headline.png, Text.jpg
jp-compress-original-remove EN/V1 --and FR/Product_Test
```
