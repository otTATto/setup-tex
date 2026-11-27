<#
.SYNOPSIS
    最小構成の TeX Live を導入し、DEPENDS.txt のパッケージをインストールする
.PARAMETER TexDir
    インストール先（省略時は install-tl の既定 C:\texlive\YYYY になる）
#>
param(
    [string]$TexDir
)
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'  # Expand-Archive の進捗表示を省く

# mirror.ctan.org は毎回別のミラーへリダイレクトするが、
# curl の --retry は証明書エラーなどを再試行しないので、失敗したら取得し直す
# Invoke-WebRequest は一部のミラーに拒否されるため、Windows 標準の curl.exe を使う
function Get-CtanFile([string]$Path, [string]$OutFile) {
    $url = "https://mirror.ctan.org/$Path"
    $max = 5
    for ($i = 1; ; $i++) {
        curl.exe -fsSL --retry 3 -o $OutFile $url
        $status = $LASTEXITCODE
        if (-not $status) { return }
        if ($i -ge $max) { throw "❌ Failed to fetch $url after $max attempts (curl exit $status)" }
        Write-Warning "Attempt $i/$max to fetch $url failed (curl exit $status); retrying with another mirror in $($i * 5)s"
        Start-Sleep -Seconds ($i * 5)
    }
}

$root = Split-Path $PSScriptRoot -Parent
$work = Join-Path ([IO.Path]::GetTempPath()) "setup.tex-$PID"
New-Item -ItemType Directory $work | Out-Null
try {
    # 1. install-tl を取得
    $zip = Join-Path $work 'install-tl.zip'
    Get-CtanFile 'systems/texlive/tlnet/install-tl.zip' $zip
    Expand-Archive $zip $work
    $installer = (Get-ChildItem $work -Directory -Filter 'install-tl-*')[0].FullName

    if (-not $TexDir) {
        $year = (Select-String "$installer\release-texlive.txt" -Pattern 'version (\d{4})').Matches[0].Groups[1].Value
        $TexDir = "C:\texlive\$year"
    }

    # 2. texlive.profile を渡して TeX Live をインストール
    & "$installer\install-tl-windows.bat" -no-gui -profile "$root\texlive.profile" -texdir $TexDir
    if ($LASTEXITCODE) { throw "❌ install-tl failed (exit $LASTEXITCODE)" }

    # 3. DEPENDS.txt のパッケージをインストール
    # Get-Content は PowerShell 5.1 で UTF-8 を Shift_JIS として読み、日本語コメントの
    # 文字化けで改行が消えて hard 行が欠けることがあるため、.NET の UTF-8 API で読む
    $packages = [IO.File]::ReadAllLines("$root\DEPENDS.txt") | ForEach-Object {
        if ($_ -match '^\s*hard\s+(\S+)') { $Matches[1] }
    }
    & "$TexDir\bin\windows\tlmgr.bat" install @packages
    if ($LASTEXITCODE) { throw "❌ tlmgr install failed (exit $LASTEXITCODE)" }

    Write-Host "✅ Installed TeX Live to $TexDir; reopen the terminal to pick up the new PATH"
}
finally {
    Remove-Item -Recurse -Force $work
}
