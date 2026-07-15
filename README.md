# JP Tools

**Versao atual:** `1.2.5`

Ferramentas de terminal para automatizar tarefas repetitivas em criativos JustPremium/GumGum, principalmente projetos DSK e MSK.

O codigo e publico, roda localmente e nao envia arquivos dos projetos para servidores do JP Tools. Na maior parte do trabalho, os comandos usados serao `jp-capture`, `jp-poster` e `jp-compress`.

## O Que Faz

- gera `banner/backup.jpg` na resolucao correta;
- gera posters a partir dos videos usados nos paineis;
- comprime imagens individualmente ou em lote;
- preserva e restaura os arquivos anteriores a compressao;
- remove capturas, posters e backups antigos;
- reconhece projetos DSK, MSK e workspaces multi-root do VS Code;
- valida filtros antes de alterar arquivos e explica erros encontrados.

## Uso Mais Comum

Abra o terminal dentro da pasta do projeto e execute:

```bash
jp-capture
jp-poster
jp-compress
```

### `jp-capture`

Sem argumentos, encontra todas as versoes no escopo atual e gera `banner/backup.jpg`.

- DSK: `1920x1200`.
- MSK: `300x600`, incluindo as barras do preview.
- Espera padrao: `3` segundos.
- Detecta DSK ou MSK separadamente para cada versao.

### `jp-poster`

Sem argumentos, encontra os videos locais e as referencias em HTML, JS ou JSON.

- Formato padrao: `16x9`.
- Tempo padrao: segundo `1`.
- Saida: `banner/assets/poster.jpg`, `poster2.jpg` etc.
- Cada fonte de video unica recebe seu proprio poster.

### `jp-compress`

Sem argumentos, comprime JPG, PNG e WebP dentro de `banner/assets`, alem de `banner/backup.jpg`.

- Qualidade padrao: `80`.
- So substitui uma imagem quando o resultado fica menor.
- Antes de substituir, salva o original em `.jp-compress-original` na pasta da versao.
- O backup preserva a estrutura original, como `.jp-compress-original/banner/assets/CTA.png`.

## Onde Os Comandos Atuam

O JP Tools pode ser executado na pasta geral do projeto, em `DSK`, `MSK`, em um idioma ou diretamente em uma versao.

```text
Projeto/
  DSK/
    Baseball/index.html
    F1/index.html
  MSK/
    Baseball/index.html
    F1/index.html
```

Sem filtro, o comando processa todas as versoes validas abaixo da pasta atual.

Se `DSK` e `MSK` estiverem adicionados separadamente ao mesmo workspace multi-root do VS Code, o JP Tools reconhece as duas raizes. O comando pode ser executado no terminal de qualquer uma delas.

Somente pastas com uma estrutura valida de projeto, incluindo `index.html` e `banner`, entram na varredura.

## Filtros E Ajustes

A ordem e sempre:

```text
comando -> ajustes -> filtros
```

Exemplo:

```bash
jp-poster 16x9 5 DSK/F1
```

- `jp-poster`: comando;
- `16x9`: formato;
- `5`: tempo;
- `DSK/F1`: filtro de pasta.

Regras importantes:

- use `/` para niveis de pasta: `EN/V1`, nao `EN V1`;
- filtros diferenciam maiusculas e minusculas;
- `--and` adiciona outro grupo;
- `--not` exclui o filtro seguinte;
- operadores nunca podem ficar sem um valor depois deles;
- filtros de imagem exigem nome completo e extensao, como `CTA.png`;
- ajustes escritos depois de `--and` valem para aquele grupo.

Exemplos:

```bash
jp-capture EN/V1 --and FR/V2
jp-capture EN/V1 --not EN/V2
jp-poster 5 expanded_video.html
jp-poster 5 expanded_video.html --and 20 left.html
jp-compress 80 EN/V1 CTA.png --and 70 NL/V2 chat-2.png
```

No `jp-poster`, um ajuste global pode receber excecoes:

```bash
jp-poster 20 --and 5 F1 --and 15 expanded_video.html
```

Nesse exemplo, o projeto usa `20` segundos, `F1` usa `5` segundos e os paineis `expanded_video.html` usam `15` segundos. Quando mais de um grupo corresponde ao mesmo video, o ultimo grupo escrito tem prioridade.

Um nome HTML sem caminho, como `expanded_video.html`, encontra todos os paineis com esse nome. Para limitar a uma versao, use o caminho completo:

```bash
jp-poster 5 DSK/F1/banner/expanded_video.html
```

O HTML precisa conter uma referencia direta para `.mp4`, `.webm`, `.mov` ou `.m4v`. Arquivos sem video sao informados e ignorados.

## Comandos Disponiveis

| Comando | Funcao |
| --- | --- |
| `jp-capture` | Gera `banner/backup.jpg`. |
| `jp-capture-remove` | Remove `banner/backup.jpg`. |
| `jp-poster` | Gera posters dos videos. |
| `jp-poster-remove` | Remove `poster.jpg`, `poster2.jpg` etc. |
| `jp-compress` | Comprime imagens e guarda os originais. |
| `jp-compress-original` | Restaura os originais e remove os backups restaurados. |
| `jp-compress-original-remove` | Remove pastas `.jp-compress-original` restantes. |
| `jp-help` | Mostra ajuda, regras e exemplos baseados no projeto atual. |

Exemplos de restauracao e limpeza:

```bash
jp-compress-original
jp-compress-original EN/V1 --not CTA.png
jp-compress-original-remove EN/V1 --and FR/V2
jp-poster-remove EN/V1
jp-capture-remove EN/V1
```

Use `jp-help` para consultar formatos, variaveis avancadas e exemplos dinamicos com nomes encontrados no projeto atual.

## Instalacao

### Mac

Abra o Terminal, cole o comando completo e pressione Enter:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/BrunoFragaOSF/JP-Tools/main/scripts/bootstrap-mac.sh)"
```

### Windows

Abra o PowerShell, cole o comando completo e pressione Enter:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -Command "Invoke-RestMethod 'https://raw.githubusercontent.com/BrunoFragaOSF/JP-Tools/main/scripts/bootstrap-windows.ps1' | Invoke-Expression"
```

O instalador baixa o pacote da release mais recente, instala ou valida as dependencias, configura o runtime privado do Playwright/Chromium e adiciona os comandos ao `PATH`.

- Mac: comandos instalados em `~/bin`.
- Windows: comandos instalados em `%USERPROFILE%\bin`.

No Windows, o instalador recarrega o `PATH` depois do WinGet e detecta as pastas do ImageMagick sem exigir que o PowerShell seja fechado durante a primeira instalacao.

Depois de instalar, abra um terminal novo e execute:

```bash
jp-help
```

## Atualizacao

Execute novamente o comando de instalacao do seu sistema. O bootstrap baixa a release mais recente e substitui os comandos antigos.

## Desinstalacao

### Mac

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/BrunoFragaOSF/JP-Tools/main/scripts/uninstall-mac.sh)"
```

### Windows

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -Command "Invoke-RestMethod 'https://raw.githubusercontent.com/BrunoFragaOSF/JP-Tools/main/scripts/uninstall-windows.ps1' | Invoke-Expression"
```

O desinstalador remove os comandos e o runtime privado do JP Tools. Antes de remover dependencias compartilhadas, como Node, FFmpeg e ImageMagick, ele pede confirmacao porque outros projetos podem utiliza-las.

## Erros E Protecoes

Os comandos interrompem a execucao antes de alterar arquivos quando encontram problemas como:

- filtro ou pasta inexistente;
- caminho de pasta escrito sem `/`;
- diferenca de maiusculas e minusculas;
- imagem sem extensao ou com nome incorreto;
- `--and` ou `--not` sem valor;
- HTML sem referencia direta de video;
- pasta sem uma estrutura valida de banner;
- dependencia ou executavel nao encontrado;
- versao ou hash de ferramenta independente diferente do homologado.

As mensagens informam o motivo e, quando possivel, sugerem pastas, HTMLs ou imagens reais encontrados no projeto.

Outras protecoes:

- `jp-compress` so substitui uma imagem se o arquivo novo for menor;
- os originais sao preservados antes da compressao;
- filtros sao validados antes do processamento;
- o Chromium e iniciado depois da instalacao para validar o runtime;
- nao existe telemetria nem upload automatico dos projetos.

## Dependencias

O JP Tools utiliza dependencias conhecidas e obtidas por gerenciadores oficiais.

| Dependencia | Para que serve | Origem | Politica |
| --- | --- | --- | --- |
| Node.js | Executa os comandos e a logica do JP Tools. | Homebrew no Mac e WinGet no Windows | Atualizacao normal. |
| Playwright | Automatiza o navegador para capturas, posters e validacoes. | npm | Atualizacao normal, instalado no runtime privado. |
| Chromium | Renderiza banners e midias usados pelo `jp-capture` e pelo `jp-poster`. | Distribuicao do Playwright | Versao compativel com o Playwright instalado. |
| WebP | Le, comprime e converte imagens WebP. | Homebrew ou suporte dos fallbacks | Atualizacao normal. |
| FFmpeg | Extrai frames de videos para posters e funciona como fallback de imagem. | Homebrew ou WinGet | Versao e hashes homologados. |
| ImageMagick | Comprime e converte imagens quando nao existe um otimizador especifico. | Homebrew ou WinGet | Versao e hashes homologados. |
| jpegoptim | Otimiza imagens JPEG no Mac. | Homebrew no Mac | Versao e hashes homologados. |
| pngquant | Reduz cores e peso de imagens PNG no Mac. | Homebrew no Mac | Versao e hashes homologados. |
| oxipng | Faz uma otimizacao adicional sem perda em imagens PNG no Mac. | Homebrew no Mac | Versao e hashes homologados. |

No Mac, somente FFmpeg, ImageMagick, jpegoptim, pngquant e oxipng ficam fixados com `brew pin`. No Windows, FFmpeg e ImageMagick usam versoes homologadas e manifestos oficiais do WinGet.

O instalador compara versoes, origens e hashes registrados em `dependencies.lock.json`. Se uma ferramenta independente nao corresponder ao lock, a instalacao para em vez de aceitar outro arquivo silenciosamente.

No Windows, o `jp-compress` usa ImageMagick ou FFmpeg como fallback para formatos cujos otimizadores especificos do Mac nao estao instalados.

## Limitacoes

- `jp-capture` depende de Playwright e Chromium;
- videos remotos podem bloquear acesso ou captura;
- o filtro HTML do `jp-poster` exige uma referencia direta de video naquele HTML;
- videos definidos apenas por uma logica JS compartilhada nao podem ser associados com seguranca a um painel especifico;
- a compressao depende dos otimizadores disponiveis no sistema;
- filtros sao intencionalmente rigidos para evitar alteracoes acidentais.
