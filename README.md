# JP Tools

**Versao atual:** `1.1.0`

Ferramentas de terminal para acelerar tarefas repetitivas em criativos JustPremium/GumGum, principalmente banners DSK/MSK.

Este repositorio e publico para facilitar a instalacao e permitir que qualquer pessoa confira o codigo antes de usar. Os scripts ficam abertos nas pastas `tools/` e `scripts/`, entao o time pode revisar o funcionamento sempre que quiser.

## Download

Baixe a pasta compactada pela aba **Releases** do GitHub.

1. Abra a release mais recente.
2. Baixe o arquivo compactado do JP Tools.
3. Descompacte a pasta.
4. Rode o instalador do seu sistema.

## Uso Mais Comum

Na maior parte do tempo voce provavelmente so vai usar estes tres comandos:

```bash
jp-capture
jp-poster
jp-compress
```

Eles cobrem o fluxo principal:

- `jp-capture`: gera `banner/backup.jpg` das versoes.
- `jp-poster`: gera posters de videos em `banner/assets`.
- `jp-compress`: comprime imagens e salva backup dos originais.

O JP Tools deve ser usado dentro da pasta do projeto, DSK, MSK, idioma ou versao. Sem filtro, ele varre tudo abaixo da pasta atual. Com filtro, ele processa apenas as pastas/versoes indicadas.

Exemplo de estrutura comum:

```text
Projeto/
  EN/V1/index.html
  EN/V1/banner/assets/
  EN/V2/index.html
  EN/V2/banner/assets/
  FR/Product_Test/index.html
```

Exemplos de uso:

```bash
jp-capture msk 3 EN/V1
jp-poster 16x9 2 EN/V1 --and EN/V2
jp-compress 80 EN/V1 CTA.png
```

Os comandos foram feitos para falhar quando algo parece errado. Se um filtro de pasta, versao ou imagem nao existir, ou se o nome estiver com maiuscula/minuscula diferente, o erro tenta explicar o problema e sugerir um exemplo usando pastas reais do projeto.

Os outros comandos sao complementos avancados para remover capturas/posters, restaurar imagens originais ou limpar backups.

## Instalacao

Depois de baixar a pasta compactada pela **Release**, descompacte e use apenas um dos arquivos abaixo.

### Mac

Clique duas vezes em:

```text
INSTALL-MAC.command
```

Se o macOS bloquear por seguranca, abra o Terminal dentro da pasta do JP Tools e rode:

```bash
xattr -dr com.apple.quarantine .
chmod +x INSTALL-MAC.command scripts/install-mac.command
bash INSTALL-MAC.command
```

### Windows

Clique duas vezes em:

```text
INSTALL-WINDOWS.bat
```

Se Node acabou de ser instalado e ainda nao entrou no `PATH`, abra um novo terminal e rode o instalador novamente.

## O Que Cada Pasta Faz

```text
INSTALL-MAC.command          instalador amigavel para Mac
INSTALL-WINDOWS.bat          instalador amigavel para Windows
UNINSTALL-MAC.command        desinstalador amigavel para Mac
UNINSTALL-WINDOWS.bat        desinstalador amigavel para Windows
scripts/                     scripts internos chamados pelos instaladores
tools/                       comandos JP Tools instalados no computador
```

A pasta `scripts/` e necessaria. Os arquivos da raiz sao os atalhos que a pessoa clica; eles chamam os scripts internos para fazer a instalacao/desinstalacao de verdade.

A pasta `tools/` contem os comandos principais:

```text
tools/jp-capture
tools/jp-poster
tools/jp-compress
tools/jp-help
```

## Teste Apos Instalar

Abra um terminal novo e rode:

```bash
jp-help
```

O `jp-help` mostra os comandos disponiveis e tenta detectar pastas, versoes e imagens da pasta atual para montar exemplos reais do projeto.

## Desinstalacao

Use um destes arquivos:

```text
UNINSTALL-MAC.command
UNINSTALL-WINDOWS.bat
```

O desinstalador remove os comandos do JP Tools e pergunta antes de remover dependencias como Node, FFmpeg, ImageMagick, Playwright e Chromium, porque elas podem ser usadas por outros projetos.

## Dependencias

O instalador tenta instalar ou configurar:

- Node.js
- Playwright
- Chromium
- FFmpeg
- ImageMagick
- Otimizadores de imagem quando disponiveis, como `jpegoptim`, `pngquant`, `oxipng` e `webp`

No Windows, algumas otimizacoes podem depender do que estiver disponivel no sistema. O `jp-compress` usa ImageMagick/FFmpeg como fallback.

## Regras de Filtro

Os filtros sao rigidos para evitar erro silencioso em producao.

- A ordem importa: comando, opcoes fixas, depois filtro.
- Pastas e versoes usam `/` para niveis: `EN/V1`, nao `EN V1`.
- Filtros sao case-sensitive: `text-1.png` e diferente de `TEXT-1.png`.
- `--and` soma grupos.
- `--not` exclui grupos.
- No `jp-compress`, imagem precisa ter nome completo, extensao, case exato e existir.

Exemplos:

```bash
jp-capture msk 3 EN/V1
jp-capture EN/V1 --and FR/Product_Test --not DE/Simulated_DSK
jp-poster 16x9 2 EN/V1 --and NL/V2
jp-compress 80 EN/V1 CTA.png --and NL/V2 chat-2.png
```

Se voce digitar algo errado, os comandos tentam explicar o motivo e sugerir um exemplo baseado nas pastas reais da pasta atual.

Exemplo de erro esperado:

```text
JP Tools error: Invalid folder/version filter.
  - Folder/version filter not found: EN V2. Did you mean EN/V2? Use / for folder levels.
```

## Comandos

### jp-capture

Gera `banner/backup.jpg`.

```bash
jp-capture
jp-capture msk 3 EN/V1
jp-capture dsk 10 EN/V1
jp-capture EN/V1 --and FR/Product_Test --not DE/Simulated_DSK
```

Parametros:

- `msk` ou `dsk`: forca o tipo de captura.
- tempo em segundos: espera antes de capturar. Exemplo: `3`, `5`, `10`.
- filtro: pasta/versao que deve ser processada.

Sem `msk` ou `dsk`, o comando tenta detectar pelo caminho atual.

Variaveis uteis:

```bash
JP_CAPTURE_WAIT=5000 jp-capture msk
JP_CAPTURE_QUALITY=90 jp-capture dsk
```

### jp-capture-remove

Remove `banner/backup.jpg` das versoes filtradas.

```bash
jp-capture-remove
jp-capture-remove EN/V1
jp-capture-remove EN/V1 --and FR/Product_Test
```

### jp-poster

Gera `poster.jpg`, `poster2.jpg`, `poster3.jpg` etc. em `banner/assets`, buscando videos locais ou referencias em HTML/JS/JSON.

```bash
jp-poster
jp-poster 16x9 2 EN/V1
jp-poster 9x16 5 EN/V1 --and NL/V2
jp-poster 300x600 1 FR/Product_Test
```

Formatos aceitos:

- `16x9`
- `9x16`
- `1x1`
- `msk`
- `dsk`
- `WxH`, por exemplo `300x600`

Variaveis uteis:

```bash
JP_POSTER_QUALITY=90 jp-poster 16x9 2
JP_POSTER_FIT=contain jp-poster 9x16 2
```

### jp-poster-remove

Remove posters gerados dentro de `banner/assets`.

```bash
jp-poster-remove
jp-poster-remove EN/V1
jp-poster-remove EN/V1 --and NL/V2
```

### jp-compress

Comprime imagens em `banner/assets` e tambem `banner/backup.jpg`.

Antes de substituir qualquer imagem, salva o original em `.jp-compress-original` ao lado de `index.html`/`banner`.

```bash
jp-compress
jp-compress 80
jp-compress 65 EN/V1
jp-compress 80 EN/V1 CTA.png
jp-compress 80 EN/V1 CTA.png --and NL/V2 chat-2.png
```

Qualidade:

- padrao: `80`
- minimo: `0`
- maximo: `100`

O comando so substitui a imagem se o resultado comprimido for menor.

### jp-compress-original

Restaura imagens originais salvas antes do `jp-compress`.

```bash
jp-compress-original
jp-compress-original EN/V1
jp-compress-original EN/V1 --not CTA.png
jp-compress-original FR/Product_Test --not Logo.png, Cta.png --and NL/V2 --not Headline.png
```

Depois de restaurar uma imagem, o backup restaurado e removido. Pastas vazias sao limpas.

### jp-compress-original-remove

Remove pastas `.jp-compress-original` quando voce terminou e nao precisa mais restaurar imagens.

```bash
jp-compress-original-remove
jp-compress-original-remove EN/V1
jp-compress-original-remove EN/V1 --and FR/Product_Test
jp-compress-original-remove EN/V1 --not FR/Product_Test
```

### jp-help

Mostra ajuda no terminal.

```bash
jp-help
```

O diferencial e que ele tenta detectar a estrutura da pasta atual e exibir exemplos reais com os nomes encontrados ali.

## Transparencia

Este projeto e aberto para que o time consiga conferir o codigo antes de instalar.

Alguns pontos importantes:

- Os comandos sao scripts locais.
- O instalador copia os scripts para `~/bin` no Mac ou `%USERPROFILE%\\bin` no Windows.
- O instalador baixa dependencias conhecidas, como Node, Playwright, Chromium, FFmpeg e ImageMagick.
- Nao existe servidor proprio ou telemetria nestes scripts.
- Antes de instalar, voce pode abrir qualquer arquivo em `tools/` ou `scripts/` e revisar linha por linha.

## Limitacoes

- O `jp-capture` usa Playwright/Chromium para capturar previews, entao depende dessas ferramentas estarem instaladas corretamente.
- O `jp-poster` pode falhar em videos remotos com restricao de acesso/CORS.
- O `jp-compress` depende dos otimizadores disponiveis no sistema. Se um otimizador nao existir, usa fallback quando possivel.
- Filtros sao intencionalmente rigidos. Se o case ou o caminho estiver errado, o comando falha para evitar alteracoes acidentais.

## Atualizacao

Para atualizar, baixe a release mais recente e rode novamente:

```text
INSTALL-MAC.command
INSTALL-WINDOWS.bat
```

O instalador sobrescreve os comandos do JP Tools com a versao nova.
