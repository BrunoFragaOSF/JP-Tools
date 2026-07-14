$ErrorActionPreference = "Stop"

$Repository = "BrunoFragaOSF/JP-Tools"
$ArchiveUrl = if ($env:JP_TOOLS_ARCHIVE_URL) {
    $env:JP_TOOLS_ARCHIVE_URL
} else {
    "https://github.com/$Repository/releases/latest/download/JP-Tools.zip"
}
$TempDir = Join-Path ([System.IO.Path]::GetTempPath()) ("jp-tools-installer-" + [guid]::NewGuid().ToString("N"))
$ArchivePath = Join-Path $TempDir "JP-Tools.zip"
$PackageRoot = Join-Path $TempDir "package"

New-Item -ItemType Directory -Force -Path $TempDir | Out-Null

try {
    Write-Host "JP Tools: baixando o instalador mais recente do GitHub..."
    Invoke-WebRequest -UseBasicParsing -Uri $ArchiveUrl -OutFile $ArchivePath

    Write-Host "JP Tools: extraindo o pacote..."
    Expand-Archive -Force -Path $ArchivePath -DestinationPath $PackageRoot

    $PackageDir = Get-ChildItem -Path $PackageRoot -Directory |
        Where-Object { $_.Name -like "JP-Tools-*" } |
        Select-Object -First 1

    if (-not $PackageDir -or
        -not (Test-Path (Join-Path $PackageDir.FullName "scripts\install-windows.ps1")) -or
        -not (Test-Path (Join-Path $PackageDir.FullName "tools"))) {
        throw "O pacote baixado nao possui a estrutura esperada. Origem: $ArchiveUrl"
    }

    if ($env:JP_TOOLS_BOOTSTRAP_TEST -eq "1") {
        Write-Host "JP Tools: pacote validado em modo de teste."
        return
    }

    Write-Host "JP Tools: iniciando a instalacao..."
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PackageDir.FullName "scripts\install-windows.ps1")
    if ($LASTEXITCODE -ne 0) {
        throw "O instalador do JP Tools terminou com o codigo $LASTEXITCODE."
    }
} finally {
    Remove-Item -Recurse -Force $TempDir -ErrorAction SilentlyContinue
}
