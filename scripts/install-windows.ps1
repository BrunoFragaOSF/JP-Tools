$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$ToolsDir = Join-Path $ScriptDir "tools"
$BinDir = Join-Path $env:USERPROFILE "bin"
$ToolInstallDir = Join-Path $BinDir "jp-tools"

New-Item -ItemType Directory -Force -Path $BinDir | Out-Null
New-Item -ItemType Directory -Force -Path $ToolInstallDir | Out-Null

function Copy-Tool($name) {
    Copy-Item -Force (Join-Path $ToolsDir $name) (Join-Path $ToolInstallDir "$name.js")
}

function Write-Cmd($cmdName, $toolName) {
    $cmdPath = Join-Path $BinDir "$cmdName.cmd"
    $toolPath = Join-Path $ToolInstallDir "$toolName.js"
    $content = "@echo off" + [Environment]::NewLine + "node ""$toolPath"" %*"
    $content | Set-Content -Encoding ASCII $cmdPath
}

function Add-PathIfExists($pathToAdd) {
    if ($pathToAdd -and (Test-Path $pathToAdd) -and (($env:Path -split ";") -notcontains $pathToAdd)) {
        $env:Path = "$pathToAdd;$env:Path"
    }
}

function Refresh-NodePath() {
    Add-PathIfExists (([Environment]::GetFolderPath("ProgramFiles")) + "\nodejs")
    Add-PathIfExists (([Environment]::GetFolderPath("ProgramFilesX86")) + "\nodejs")
    Add-PathIfExists (Join-Path $env:LOCALAPPDATA "Programs\nodejs")
    Add-PathIfExists (Join-Path $env:APPDATA "npm")
}

function Has-Command($name) {
    return [bool](Get-Command $name -ErrorAction SilentlyContinue)
}

function Resolve-CommandPath($names) {
    foreach ($name in $names) {
        $cmd = Get-Command $name -ErrorAction SilentlyContinue
        if ($cmd) { return $cmd.Source }
    }
    return $null
}

function Invoke-Tool($commandPath, $arguments) {
    & $commandPath @arguments
    if ($LASTEXITCODE -ne 0) {
        throw "Command failed: $commandPath $($arguments -join ' ')"
    }
}

Copy-Tool "jp-capture"
Copy-Tool "jp-poster"
Copy-Tool "jp-compress"
Copy-Tool "jp-help"
Copy-Item -Force (Join-Path $ToolsDir "jp-project-roots.js") (Join-Path $ToolInstallDir "jp-project-roots.js")

Write-Cmd "jp-capture" "jp-capture"
Write-Cmd "jp-capture-remove" "jp-capture"
Write-Cmd "jp-poster" "jp-poster"
Write-Cmd "jp-poster-remove" "jp-poster"
Write-Cmd "jp-compress" "jp-compress"
Write-Cmd "jp-compress-original" "jp-compress"
Write-Cmd "jp-compress-original-remove" "jp-compress"
Write-Cmd "jp-help" "jp-help"

$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
if (($userPath -split ";") -notcontains $BinDir) {
    [Environment]::SetEnvironmentVariable("Path", "$userPath;$BinDir", "User")
}
$env:Path = "$env:Path;$BinDir"

if (Has-Command "winget") {
    winget install --id OpenJS.NodeJS.LTS -e --accept-source-agreements --accept-package-agreements
    winget install --id Gyan.FFmpeg -e --accept-source-agreements --accept-package-agreements
    winget install --id ImageMagick.ImageMagick -e --accept-source-agreements --accept-package-agreements
} else {
    Write-Host "winget nao encontrado. Instale Node.js, FFmpeg e ImageMagick manualmente."
}

Refresh-NodePath

$nodePath = Resolve-CommandPath @("node.exe", "node")
$npmPath = Resolve-CommandPath @("npm.cmd", "npm")
$npxPath = Resolve-CommandPath @("npx.cmd", "npx")

if (-not $nodePath -or -not $npmPath -or -not $npxPath) {
    Write-Host "Node/npm/npx nao foram encontrados apos a instalacao. Abra um novo terminal e rode novamente o comando de instalacao do README."
    exit 1
}

Write-Host "Instalando Playwright e Chromium..."
Invoke-Tool $npmPath @("install", "-g", "playwright")
Invoke-Tool $npxPath @("playwright", "install", "chromium")

$globalRoot = (& $npmPath "root" "-g").Trim()
& $nodePath -e "require(process.argv[1] + '/playwright')" $globalRoot
if ($LASTEXITCODE -ne 0) {
    Write-Host "Playwright nao ficou acessivel para o Node. Rode: npm install -g playwright && npx playwright install chromium"
    exit 1
}

Write-Host ""
Write-Host "JP Tools instalado. Abra um novo terminal do VSCode."
Write-Host "Teste com: jp-help"
Write-Host "No Windows, jp-compress usa ImageMagick/FFmpeg como fallback. Para compressao mais forte de PNG/JPG, jpegoptim/pngquant/oxipng/cwebp via Scoop/Chocolatey ainda podem melhorar o resultado."
