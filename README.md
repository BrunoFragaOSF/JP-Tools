# JP Tools

**Versao atual:** `1.2.4`

Ferramentas de terminal para automatizar tarefas repetitivas em criativos JustPremium/GumGum, principalmente banners DSK e MSK.

O projeto e publico para que qualquer pessoa possa ler os scripts antes de instalar. Nao existe servidor proprio, telemetria ou envio dos arquivos do banner para o JP Tools.

## Para Que Serve

O JP Tools cobre o fluxo mais comum de preparacao e entrega de banners:

- gera `banner/backup.jpg` das versoes;
- gera posters a partir dos videos usados nos paineis;
- comprime imagens e preserva os arquivos originais;
- remove capturas e posters antigos;
- restaura imagens anteriores a compressao;
- valida filtros e explica erros antes de alterar arquivos;
- reconhece projetos abertos como workspace multi-root no VS Code.

## Uso Mais Simples

Na maior parte do trabalho, use apenas estes tres comandos:

```bash
jp-capture
jp-poster
jp-compress
```

### `jp-capture`

Sem argumentos, encontra todas as versoes no escopo atual e gera `banner/backup.jpg`.

- DSK: captura em `1920x1200`.
- MSK: captura em `300x600`, incluindo as barras do preview.
- Espera padrao: `3` segundos.
- Em um workspace com DSK e MSK, detecta o formato de cada `index.html` separadamente.

### `jp-poster`

Sem argumentos, encontra os videos locais e as referencias de video do projeto e gera `poster.jpg`, `poster2.jpg` etc. dentro de `banner/assets`.

- Formato padrao: `16x9`.
- Tempo padrao: segundo `1`.
- Cada fonte de video unica recebe seu poster no diretorio correto.

### `jp-compress`

Sem argumentos, comprime imagens em `banner/assets` e tambem `banner/backup.jpg`.

- Qualidade padrao: `80`.
- So substitui uma imagem quando o resultado comprimido fica menor.
- Salva o original em `.jp-compress-original` antes de substituir.

Os comandos sem filtro sao globais dentro do escopo detectado. Isso significa que eles processam todas as versoes validas abaixo da pasta atual ou todas as raizes de projeto detectadas no workspace.

## Instalacao Completa

### Mac

Abra o Terminal, cole o comando completo abaixo e pressione Enter:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/BrunoFragaOSF/JP-Tools/main/scripts/bootstrap-mac.sh)"
```

O bootstrap baixa `JP-Tools.zip` da release mais recente, valida a estrutura e executa o instalador pelo Terminal. Nao e necessario baixar, descompactar ou abrir arquivos pelo Finder.

### Windows

Abra o PowerShell, cole o comando completo abaixo e pressione Enter:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -Command "Invoke-RestMethod 'https://raw.githubusercontent.com/BrunoFragaOSF/JP-Tools/main/scripts/bootstrap-windows.ps1' | Invoke-Expression"
```

O bootstrap baixa o mesmo `JP-Tools.zip`, valida a estrutura e executa o instalador PowerShell. Nao e necessario baixar ou abrir um `.bat`.

### Onde Fica Instalado

- Mac: `~/bin`.
- Windows: `%USERPROFILE%\bin`.

Os caminhos e lançadores internos sao diferentes em cada sistema, mas os comandos usados no terminal sao os mesmos: `jp-capture`, `jp-poster`, `jp-compress`, `jp-help` etc.

### Versoes Homologadas E Verificacao

O instalador usa `dependencies.lock.json` como fonte unica das versoes e hashes permitidos. Ele nao aceita automaticamente uma atualizacao mais recente, mesmo que o Homebrew, npm ou WinGet passe a recomenda-la.

| Dependencia | Mac | Windows |
| --- | --- | --- |
| Node.js | `24.18.0` | `24.18.0` |
| Playwright | `1.61.1` | `1.61.1` |
| Chromium | `149.0.7827.55`, revisao `1228` | `149.0.7827.55`, revisao `1228` |
| FFmpeg | `8.1.2_1` | `8.1.2` |
| ImageMagick | `7.1.2-27` | `7.1.2.27` |
| jpegoptim | `1.5.6` | nao instalado |
| pngquant | `3.0.3` | nao instalado |
| oxipng | `10.1.1` | nao instalado |
| WebP | `1.6.0` | fornecido pelos fallbacks instalados |

No Mac, o lock cobre as 46 formulas Homebrew diretas e transitivas usadas por essa arvore. Antes de instalar, o JP Tools confere versao, revisao, dependencias, hash da formula, origem e hash do bottle compativel com aquele Mac. Depois da instalacao, confere as versoes novamente e aplica `brew pin` em toda a arvore.

No Windows, o instalador confere o hash completo de cada manifesto oficial do WinGet e o hash do instalador homologado para `x64` ou `arm64`. O WinGet faz a segunda verificacao do arquivo ao baixa-lo.

O Playwright nao e mais instalado globalmente. Ele fica dentro da pasta do JP Tools por meio de `npm ci`, usando um `package-lock.json` que fixa versoes, URLs e integridades SHA-512 da arvore npm. A revisao e a versao do Chromium tambem sao verificadas depois do download.

Se uma versao desaparecer ou qualquer metadado, URL ou hash mudar, a instalacao para antes de aceitar uma dependencia diferente. As versoes so mudam em uma nova release do JP Tools, depois de validacao.

### Teste Depois De Instalar

Abra um terminal novo dentro de um projeto e rode:

```bash
jp-help
```

O help detecta pastas, versoes, HTMLs de video e imagens reais do projeto para montar exemplos apropriados ao trabalho atual.

### Atualizacao

Rode novamente o comando de instalacao do seu sistema. Ele baixa a release mais recente e substitui os comandos antigos.

### Desinstalacao

Mac:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/BrunoFragaOSF/JP-Tools/main/scripts/uninstall-mac.sh)"
```

Windows:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -Command "Invoke-RestMethod 'https://raw.githubusercontent.com/BrunoFragaOSF/JP-Tools/main/scripts/uninstall-windows.ps1' | Invoke-Expression"
```

O desinstalador remove o runtime privado de Playwright/Chromium junto com o JP Tools e pergunta antes de remover dependencias compartilhadas do sistema, como Node, FFmpeg e ImageMagick.

## Onde Os Comandos Atuam

Rode o JP Tools dentro da pasta geral do projeto, DSK, MSK, idioma ou versao.

Exemplo:

```text
Projeto/
  DSK/
    Baseball/index.html
    Baseball/banner/assets/
    F1/index.html
    F1/banner/assets/
  MSK/
    Baseball/index.html
    Baseball/banner/assets/
```

Sem filtro, o comando varre tudo abaixo da pasta atual.

Quando `DSK` e `MSK` sao adicionados separadamente ao mesmo workspace multi-root do VS Code, o JP Tools reconhece as duas raizes. O comando pode ser executado no terminal de uma delas e processa as duas sem exigir que a pasta pai esteja aberta no Explorer.

Somente raizes com estrutura valida de projeto, incluindo `index.html` e `banner`, entram na varredura.

## Como Ler Um Comando

A ordem e sempre:

```text
comando -> ajustes -> filtros
```

Exemplo:

```bash
jp-poster 16x9 5 DSK/F1
```

- `jp-poster`: comando.
- `16x9`: ajuste de formato.
- `5`: ajuste de tempo.
- `DSK/F1`: filtro de pasta/versao.

As regras principais sao:

- pastas e versoes usam `/` para representar niveis: `EN/V1`, nao `EN V1`;
- filtros sao case-sensitive: `text-1.png` e diferente de `TEXT-1.png`;
- `--and` adiciona outro grupo;
- `--not` exclui o filtro seguinte;
- `--and` e `--not` nunca podem ficar sem um filtro depois deles;
- imagens devem usar nome completo, extensao e case exato;
- no `jp-poster` e `jp-compress`, ajustes depois de `--and` valem apenas para aquele grupo.

No `jp-poster`, existe uma forma especial de combinar um padrao global com excecoes:

```bash
jp-poster 20 --and 5 F1
```

Como nao existe filtro antes do primeiro `--and`, o segundo `20` vale globalmente. A pasta `F1` usa o segundo `5`. O `--and` continua exigindo ajustes/filtro depois dele.

As excecoes podem ser encadeadas:

```bash
jp-poster 20 --and 5 F1 --and 15 expanded_video.html
```

- o restante do projeto usa o segundo `20`;
- `F1` usa o segundo `5`;
- os paineis `expanded_video.html` usam o segundo `15`;
- quando dois filtros combinam com o mesmo video, o ultimo grupo escrito tem prioridade.

## Filtro Por HTML No `jp-poster`

O HTML pode ser usado diretamente como filtro, sem informar a pasta da versao.

```bash
jp-poster 5 expanded_video.html
```

Esse comando procura todo arquivo chamado exatamente `expanded_video.html` no escopo detectado. Se ele existir em `Baseball`, `F1` e `FIFA`, os tres videos recebem poster no segundo `5`.

Exemplo de resultado:

```text
HTML filter expanded_video.html: 3 panel(s) with video.
created DSK/Baseball/banner/assets/poster.jpg (...)
created DSK/F1/banner/assets/poster.jpg (...)
created DSK/FIFA/banner/assets/poster.jpg (...)
```

### Tempos Diferentes Por HTML

```bash
jp-poster 5 expanded_video.html --and 20 left.html
```

- todos os `expanded_video.html` usam o segundo `5`;
- todos os `left.html` usam o segundo `20`;
- se o segundo grupo nao informar tempo, ele herda o tempo padrao do inicio do comando.

### Somente Uma Versao

Use o caminho completo quando quiser limitar o filtro:

```bash
jp-poster 5 DSK/F1/banner/expanded_video.html
```

Assim apenas o painel de F1 recebe o poster.

### HTML Sem Video

O HTML precisa conter uma referencia direta para `.mp4`, `.webm`, `.mov` ou `.m4v`, por exemplo:

```html
<video src="assets/video.mp4"></video>
<div jp-createvideo-src="https://video-content.gumgum.com/video.mp4"></div>
```

Se `top.html` existir mas for apenas visual e nao tiver video, ele nao gera poster. A partir da versao `1.2.0`, o comando informa isso claramente:

```text
HTML filter top.html: matched 3 file(s), but none contains a direct video reference. No poster will be created for this group.
```

## Comandos

### `jp-capture`

Gera `banner/backup.jpg`.

```bash
jp-capture
jp-capture msk 3 EN/V1
jp-capture dsk 10 DSK/F1
jp-capture DSK/Baseball --and MSK/Baseball
jp-capture EN/V1 --not EN/V2
```

Parametros:

- `msk` ou `dsk`: forca o formato;
- numero: espera em segundos antes da captura;
- filtro: pasta ou versao que deve ser processada.

Variaveis avancadas:

```bash
JP_CAPTURE_WAIT=5000 jp-capture msk
JP_CAPTURE_QUALITY=90 jp-capture dsk
```

### `jp-capture-remove`

Remove `banner/backup.jpg`.

```bash
jp-capture-remove
jp-capture-remove EN/V1
jp-capture-remove EN/V1 --and FR/V2
```

### `jp-poster`

Gera posters para videos locais ou referencias encontradas em HTML, JS e JSON.

```bash
jp-poster
jp-poster 16x9 2 EN/V1
jp-poster 5 expanded_video.html
jp-poster 5 expanded_video.html --and 20 left.html
jp-poster 5 DSK/F1/banner/expanded_video.html
jp-poster 9x16 5 EN/V1 --and 2 NL/V2
jp-poster 20 --and 5 F1
jp-poster 20 --and 5 F1 --and 15 expanded_video.html
```

Formatos aceitos:

- `16x9`
- `9x16`
- `1x1`
- `square`
- `msk`
- `dsk`
- `WxH`, como `300x600`

Variaveis avancadas:

```bash
JP_POSTER_QUALITY=90 jp-poster 16x9 2
JP_POSTER_FIT=contain jp-poster 9x16 2
```

### `jp-poster-remove`

Remove `poster.jpg`, `poster2.jpg` etc. dentro de `banner/assets`.

```bash
jp-poster-remove
jp-poster-remove EN/V1
jp-poster-remove EN/V1 --and NL/V2
```

### `jp-compress`

Comprime imagens e salva os originais antes de substituir.

```bash
jp-compress
jp-compress 80
jp-compress 65 EN/V1
jp-compress 80 EN/V1 CTA.png
jp-compress 80 EN/V1 CTA.png --and 70 NL/V2 chat-2.png
```

Qualidade:

- padrao: `80`
- minimo: `0`
- maximo: `100`

### `jp-compress-original`

Restaura imagens salvas em `.jp-compress-original`. O backup restaurado e removido depois da restauracao.

```bash
jp-compress-original
jp-compress-original EN/V1
jp-compress-original EN/V1 --not CTA.png
jp-compress-original FR/V1 --not Logo.png --and NL/V2 --not Headline.png
```

### `jp-compress-original-remove`

Remove pastas `.jp-compress-original` que nao serao mais usadas.

```bash
jp-compress-original-remove
jp-compress-original-remove EN/V1
jp-compress-original-remove EN/V1 --and FR/V2
```

### `jp-help`

Mostra ajuda colorida, exemplos globais, filtros, comandos avancados e exemplos dinamicos baseados no projeto atual.

```bash
jp-help
```

## Erros E Protecoes

Os comandos tentam interromper a execucao antes de alterar arquivos quando encontram:

- filtro inexistente;
- caminho com `/` ausente;
- diferenca de maiusculas/minusculas;
- imagem sem extensao ou com nome incorreto;
- `--and` ou `--not` sem valor;
- HTML sem referencia direta de video;
- pasta sem estrutura valida de banner.

As mensagens mostram o motivo e, quando possivel, sugerem nomes reais encontrados no projeto.

## Dependencias

Os instaladores tentam instalar ou configurar:

- Node.js
- Playwright
- Chromium
- FFmpeg
- ImageMagick
- `jpegoptim`
- `pngquant`
- `oxipng`
- ferramentas WebP

No Windows, algumas otimizacoes dependem do que estiver disponivel no sistema. O `jp-compress` usa ImageMagick ou FFmpeg como fallback quando necessario.

## Estrutura Do Pacote

```text
README.md                       documentacao completa
scripts/bootstrap-mac.sh        download e instalacao no Mac
scripts/bootstrap-windows.ps1   download e instalacao no Windows
scripts/install-mac.sh          instalacao interna no Mac
scripts/install-windows.ps1     instalacao interna no Windows
scripts/uninstall-mac.sh        desinstalacao no Mac
scripts/uninstall-windows.ps1   desinstalacao no Windows
scripts/verify-runtime.js       validacao do Playwright e Chromium
scripts/verify-macos-dependencies.rb  validacao da arvore Homebrew
dependencies.lock.json          versoes, origens e hashes homologados
runtime/package-lock.json       arvore npm exata do Playwright
tools/                          comandos do JP Tools
```

A pasta `scripts/` e necessaria. Os bootstraps publicos baixam o pacote e chamam os instaladores internos adequados ao sistema.

## Transparencia

- Os comandos sao scripts locais e podem ser lidos em `tools/`.
- Os instaladores podem ser revisados em `scripts/`.
- No Mac, os comandos sao instalados em `~/bin`.
- No Windows, sao instalados em `%USERPROFILE%\\bin`.
- Nao existe telemetria nem upload automatico dos projetos.
- Dependencias sao baixadas de seus gerenciadores oficiais durante a instalacao.

## Limitacoes

- `jp-capture` depende de Playwright e Chromium.
- Videos remotos podem bloquear acesso ou captura.
- O filtro HTML do `jp-poster` considera referencias de video presentes diretamente naquele HTML; um video definido apenas dentro de logica JS compartilhada nao pode ser associado com seguranca a um painel especifico.
- A compressao depende dos otimizadores instalados no sistema.
- Filtros sao intencionalmente rigidos para evitar alteracoes acidentais.

## Novidades Da Versao 1.2.4

- lock central com versoes, origens e hashes homologados;
- 46 formulas diretas e transitivas do Homebrew verificadas antes e depois da instalacao;
- `brew pin` aplicado em toda a arvore instalada no Mac;
- manifestos e hashes do WinGet verificados no Windows;
- Playwright movido para um runtime privado e reproduzivel com `npm ci`;
- arvore npm fixada por `package-lock.json` e integridades SHA-512;
- Chromium validado por revisao, versao e existencia do executavel;
- instalacao interrompida quando qualquer dependencia nao corresponde ao lock;
- desinstaladores atualizados para remover o runtime privado e liberar as formulas fixadas.
