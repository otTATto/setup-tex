<#
.SYNOPSIS
    入っている TeX Live に、DEPENDS.txt の hard 行のパッケージを追加でインストールする
.PARAMETER Path
    hard <pkg> 行を並べたファイル（省略時はカレントディレクトリの DEPENDS.txt）
.PARAMETER TexDir
    TeX Live のインストール先（省略時は PATH 上の TeX Live から求める）
#>
param(
    [string]$Path = 'DEPENDS.txt',
    [string]$TexDir
)
$ErrorActionPreference = 'Stop'

if (-not (Test-Path -PathType Leaf $Path)) { throw "❌ $Path not found" }

if (-not $TexDir) {
    $cmd = Get-Command tlmgr -ErrorAction SilentlyContinue
    if (-not $cmd) { throw '❌ TeX Live not found; install it with setup first' }
    # <TexDir>\bin\windows\tlmgr.bat から 3 つさかのぼる
    $TexDir = Split-Path (Split-Path (Split-Path $cmd.Source -Parent) -Parent) -Parent
}
$tlmgr = "$TexDir\bin\windows\tlmgr.bat"
if (-not (Test-Path $tlmgr)) { throw "❌ tlmgr not found in $TexDir" }

# Get-Content は PowerShell 5.1 で UTF-8 を Shift_JIS として読むため、.NET の UTF-8 API で読む
$packages = @([IO.File]::ReadAllLines((Resolve-Path $Path)) | ForEach-Object {
    if ($_ -match '^\s*hard\s+(\S+)') { $Matches[1] }
})
if (-not $packages) {
    Write-Host "⚠️ No hard lines in $Path"
    exit 0
}

& $tlmgr install @packages
if ($LASTEXITCODE) { throw "❌ tlmgr install failed (exit $LASTEXITCODE)" }

Write-Host "✅ Installed the packages in $Path"
