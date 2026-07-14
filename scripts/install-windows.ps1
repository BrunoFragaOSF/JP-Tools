$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$ToolsDir = Join-Path $ScriptDir "tools"
$RuntimeDir = Join-Path $ScriptDir "runtime"
$LockPath = Join-Path $ScriptDir "dependencies.lock.json"
$BinDir = Join-Path $env:USERPROFILE "bin"
$ToolInstallDir = Join-Path $BinDir "jp-tools"

if (-not (Test-Path $LockPath) -or -not (Test-Path (Join-Path $RuntimeDir "package.json"))) {
    throw "JP Tools error: dependencies.lock.json ou runtime/package.json ausente."
}

$DependencyLock = Get-Content -Raw $LockPath | ConvertFrom-Json
$LockedPackages = $DependencyLock.windows.lockedPackages
$DynamicPackages = $DependencyLock.windows.dynamicPackages

function Add-PathIfExists($pathToAdd) {
    if ($pathToAdd -and (Test-Path $pathToAdd) -and (($env:Path -split ";") -notcontains $pathToAdd)) {
        $env:Path = "$pathToAdd;$env:Path"
    }
}

function Refresh-ToolPath() {
    Add-PathIfExists (([Environment]::GetFolderPath("ProgramFiles")) + "\nodejs")
    Add-PathIfExists (([Environment]::GetFolderPath("ProgramFilesX86")) + "\nodejs")
    Add-PathIfExists (Join-Path $env:LOCALAPPDATA "Programs\nodejs")
    Add-PathIfExists (Join-Path $env:LOCALAPPDATA "Microsoft\WinGet\Links")
    Add-PathIfExists (Join-Path $env:APPDATA "npm")
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

function Get-SystemArchitecture() {
    if ($env:PROCESSOR_ARCHITEW6432 -eq "ARM64" -or $env:PROCESSOR_ARCHITECTURE -eq "ARM64") {
        return "arm64"
    }
    return "x64"
}

function Confirm-WinGetManifest($package, $architecture) {
    $packageArchitecture = $architecture
    $expectedHash = $package.installerSha256.$packageArchitecture
    if (-not $expectedHash -and $architecture -eq "arm64" -and $package.installerSha256.x64) {
        $packageArchitecture = "x64"
        $expectedHash = $package.installerSha256.x64
    }
    if (-not $expectedHash) {
        throw "JP Tools error: $($package.id) $($package.version) nao foi homologado para Windows $architecture."
    }

    Write-Host "Validando manifesto e hash de $($package.id) $($package.version) [$packageArchitecture]..."
    $manifestPath = Join-Path ([System.IO.Path]::GetTempPath()) ("jp-tools-manifest-" + [guid]::NewGuid().ToString("N") + ".yaml")
    try {
        Invoke-WebRequest -UseBasicParsing -Uri $package.manifestUrl -OutFile $manifestPath
        $actualManifestHash = (Get-FileHash -Algorithm SHA256 $manifestPath).Hash
        if ($actualManifestHash -ne $package.manifestSha256) {
            throw "JP Tools error: o manifesto oficial de $($package.id) foi alterado. Nada foi instalado."
        }
        $manifest = Get-Content -Raw $manifestPath
    } finally {
        Remove-Item -Force $manifestPath -ErrorAction SilentlyContinue
    }

    $versionPattern = "PackageVersion:\s*" + [regex]::Escape($package.version)
    $hashPattern = "InstallerSha256:\s*" + [regex]::Escape($expectedHash)
    if ($manifest -notmatch $versionPattern -or $manifest -notmatch $hashPattern) {
        throw "JP Tools error: o manifesto oficial de $($package.id) nao corresponde ao hash homologado. Nada foi instalado."
    }
}

function Install-LockedWinGetPackage($package) {
    Write-Host "Instalando $($package.id) $($package.version)..."
    & winget install --id $package.id --version $package.version -e --accept-source-agreements --accept-package-agreements --disable-interactivity
    if ($LASTEXITCODE -ne 0) {
        Write-Host "O WinGet retornou codigo $LASTEXITCODE. O ambiente sera validado antes de continuar."
    }
}

function Install-OrUpdate-WinGetPackage($packageId) {
    Write-Host "Instalando ou atualizando $packageId..."
    & winget install --id $packageId -e --accept-source-agreements --accept-package-agreements --disable-interactivity
    if ($LASTEXITCODE -ne 0) {
        & winget upgrade --id $packageId -e --accept-source-agreements --accept-package-agreements --disable-interactivity
    }
    if ($LASTEXITCODE -ne 0) {
        Write-Host "O WinGet nao encontrou atualizacao ou retornou codigo $LASTEXITCODE. O ambiente sera validado antes de continuar."
    }
}

$winget = Get-Command winget -ErrorAction SilentlyContinue
if (-not $winget) {
    throw "JP Tools error: WinGet nao encontrado. Ele e necessario para instalar e verificar as dependencias no Windows."
}

$architecture = Get-SystemArchitecture
Confirm-WinGetManifest $LockedPackages.ffmpeg $architecture
Confirm-WinGetManifest $LockedPackages.imagemagick $architecture

Install-OrUpdate-WinGetPackage $DynamicPackages.node.id
Install-LockedWinGetPackage $LockedPackages.ffmpeg
Install-LockedWinGetPackage $LockedPackages.imagemagick

Refresh-ToolPath

$nodePath = Resolve-CommandPath @("node.exe", "node")
$npmPath = Resolve-CommandPath @("npm.cmd", "npm")
$ffmpegPath = Resolve-CommandPath @("ffmpeg.exe", "ffmpeg")
$magickPath = Resolve-CommandPath @("magick.exe", "magick")

if (-not $nodePath -or -not $npmPath -or -not $ffmpegPath -or -not $magickPath) {
    throw "JP Tools error: Node, npm, FFmpeg ou ImageMagick nao foi encontrado apos a instalacao. Abra um terminal novo e execute o instalador novamente."
}

$actualNodeVersion = (& $nodePath "--version").Trim()
$ffmpegHeader = (& $ffmpegPath "-version" | Select-Object -First 1)
if ($ffmpegHeader -notmatch ("ffmpeg version\s+" + [regex]::Escape($LockedPackages.ffmpeg.version))) {
    throw "JP Tools error: FFmpeg instalado nao corresponde a versao $($LockedPackages.ffmpeg.version)."
}

$magickHeader = (& $magickPath "-version" | Select-Object -First 1)
$imageMagickBinaryVersion = $LockedPackages.imagemagick.version -replace '\.(\d+)$', '-$1'
if ($magickHeader -notmatch ("ImageMagick\s+" + [regex]::Escape($imageMagickBinaryVersion))) {
    throw "JP Tools error: ImageMagick instalado nao corresponde a versao $($LockedPackages.imagemagick.version)."
}

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

Copy-Tool "jp-capture"
Copy-Tool "jp-poster"
Copy-Tool "jp-compress"
Copy-Tool "jp-help"
Copy-Item -Force (Join-Path $ToolsDir "jp-project-roots.js") (Join-Path $ToolInstallDir "jp-project-roots.js")
Copy-Item -Force (Join-Path $RuntimeDir "package.json") (Join-Path $ToolInstallDir "package.json")
Copy-Item -Force $LockPath (Join-Path $ToolInstallDir "jp-tools-dependencies.lock.json")
Remove-Item -Recurse -Force (Join-Path $ToolInstallDir "node_modules") -ErrorAction SilentlyContinue
Remove-Item -Force (Join-Path $ToolInstallDir "package-lock.json") -ErrorAction SilentlyContinue

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

Write-Host "Instalando as versoes atuais de Playwright e Chromium..."
Invoke-Tool $npmPath @("install", "--prefix", $ToolInstallDir, "--save-exact", "playwright@latest", "--ignore-scripts", "--no-audit", "--no-fund")
$playwrightCli = Join-Path $ToolInstallDir "node_modules\playwright\cli.js"
Invoke-Tool $nodePath @($playwrightCli, "install", "chromium")
Invoke-Tool $nodePath @((Join-Path $ScriptDir "scripts\verify-runtime.js"), $ToolInstallDir)
$playwrightPackage = Join-Path $ToolInstallDir "node_modules\playwright\package.json"
$playwrightVersion = (& $nodePath "-p" "require(process.argv[1]).version" $playwrightPackage).Trim()

Write-Host ""
Write-Host "JP Tools instalado. Abra um novo terminal do VSCode."
Write-Host "Node, Playwright e Chromium foram instalados nas versoes atuais."
Write-Host "Ferramentas independentes conferidas pelo lock da versao 1.2.3."
Write-Host "Node $actualNodeVersion | Playwright $playwrightVersion | FFmpeg $($LockedPackages.ffmpeg.version) | ImageMagick $($LockedPackages.imagemagick.version)"
Write-Host "Teste com: jp-help"
Write-Host "No Windows, jp-compress usa ImageMagick e FFmpeg como fallback para os otimizadores disponiveis no Mac."
