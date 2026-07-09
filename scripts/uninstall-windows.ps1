$ErrorActionPreference = "Continue"

$BinDir = Join-Path $env:USERPROFILE "bin"
$ToolInstallDir = Join-Path $BinDir "jp-tools"
$Commands = @(
    "jp-capture.cmd",
    "jp-capture-remove.cmd",
    "jp-poster.cmd",
    "jp-poster-remove.cmd",
    "jp-compress.cmd",
    "jp-compress-original.cmd",
    "jp-compress-original-remove.cmd",
    "jp-help.cmd"
)

foreach ($cmd in $Commands) {
    Remove-Item -Force (Join-Path $BinDir $cmd) -ErrorAction SilentlyContinue
}
Remove-Item -Recurse -Force $ToolInstallDir -ErrorAction SilentlyContinue

try {
    if ((Test-Path $BinDir) -and -not (Get-ChildItem -Force $BinDir -ErrorAction SilentlyContinue)) {
        Remove-Item -Force $BinDir -ErrorAction SilentlyContinue
    }
} catch {}

$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($userPath) {
    $newPath = (($userPath -split ";") | Where-Object { $_ -and ($_ -ne $BinDir) }) -join ";"
    [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
}

$playwrightCache = Join-Path $env:LOCALAPPDATA "ms-playwright"
Remove-Item -Recurse -Force $playwrightCache -ErrorAction SilentlyContinue

$npm = Get-Command npm.cmd -ErrorAction SilentlyContinue
if ($npm) {
    & $npm.Source uninstall -g playwright
}

Write-Host ""
Write-Host "JP Tools foi removido."
$answer = Read-Host "Remover tambem dependencias instaladas para o JP Tools? Isso pode afetar outros projetos. [y/N]"
if ($answer -match '^(y|yes|s|sim)$') {
    $winget = Get-Command winget -ErrorAction SilentlyContinue
    if ($winget) {
        winget uninstall --id OpenJS.NodeJS.LTS -e --accept-source-agreements
        winget uninstall --id Gyan.FFmpeg -e --accept-source-agreements
        winget uninstall --id ImageMagick.ImageMagick -e --accept-source-agreements
    } else {
        Write-Host "winget nao encontrado. Dependencias de sistema nao foram removidas."
    }
} else {
    Write-Host "Dependencias mantidas."
}

Write-Host ""
Write-Host "Desinstalacao concluida. Abra um novo terminal para atualizar o PATH."
