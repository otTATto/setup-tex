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

$root = Split-Path $PSScriptRoot -Parent
$work = Join-Path ([IO.Path]::GetTempPath()) "setup.tex-$PID"
New-Item -ItemType Directory $work | Out-Null
try {
    # 1. install-tl を取得
    $zip = Join-Path $work 'install-tl.zip'
    # Invoke-WebRequest は一部のミラーに拒否されるため、Windows 標準の curl.exe を使う
    curl.exe -fsSL --retry 3 -o $zip 'https://mirror.ctan.org/systems/texlive/tlnet/install-tl.zip'
    if ($LASTEXITCODE) { throw "install-tl の取得に失敗しました (exit $LASTEXITCODE)" }
    Expand-Archive $zip $work
    $installer = (Get-ChildItem $work -Directory -Filter 'install-tl-*')[0].FullName

    if (-not $TexDir) {
        $year = (Select-String "$installer\release-texlive.txt" -Pattern 'version (\d{4})').Matches[0].Groups[1].Value
        $TexDir = "C:\texlive\$year"
    }

    # 2. texlive.profile を渡して TeX Live をインストール
    & "$installer\install-tl-windows.bat" -no-gui -profile "$root\texlive.profile" -texdir $TexDir
    if ($LASTEXITCODE) { throw "❌ install-tl が失敗しました (exit $LASTEXITCODE)" }

    # 3. DEPENDS.txt のパッケージをインストール
    # Get-Content は PowerShell 5.1 で UTF-8 を Shift_JIS として読み、日本語コメントの
    # 文字化けで改行が消えて hard 行が欠けることがあるため、.NET の UTF-8 API で読む
    $packages = [IO.File]::ReadAllLines("$root\DEPENDS.txt") | ForEach-Object {
        if ($_ -match '^\s*hard\s+(\S+)') { $Matches[1] }
    }
    & "$TexDir\bin\windows\tlmgr.bat" install @packages
    if ($LASTEXITCODE) { throw "❌ tlmgr install が失敗しました (exit $LASTEXITCODE)" }

    Write-Host "✅ TeX Live を $TexDir にインストールしました。PATH を反映させるには、ターミナルを開き直してください。"
}
finally {
    Remove-Item -Recurse -Force $work
}
