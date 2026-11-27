<#
.SYNOPSIS
    check/sample.tex をコンパイルし、期待する check/expected.pdf と一致するか確かめる
.PARAMETER Update
    比較せず、生成した PDF で check/expected.pdf を置き換える
#>
param([switch]$Update)
$ErrorActionPreference = 'Stop'

$check = Join-Path (Split-Path $PSScriptRoot -Parent) 'check'
$actual = "$check\sample.pdf"
$expected = "$check\expected.pdf"

# 日時を固定し、同じ入力からは同じバイト列の PDF が出るようにする
$env:SOURCE_DATE_EPOCH = '0'
$env:FORCE_SOURCE_DATE = '1'

latexmk -cd -r "$check\latexmkrc" "$check\sample.tex"
if ($LASTEXITCODE) { throw "❌ Compilation failed (exit $LASTEXITCODE)" }
latexmk -cd -r "$check\latexmkrc" -c "$check\sample.tex" | Out-Null

if ($Update) {
    Move-Item -Force $actual $expected
    Write-Host "⚠️ Updated check/expected.pdf"
    exit 0
}

if ((Get-FileHash $actual).Hash -eq (Get-FileHash $expected).Hash) {
    Remove-Item $actual
    Write-Host '✅ Matches check/expected.pdf'
    exit 0
}
Write-Host '🚨 Does not match check/expected.pdf; compare it with check/sample.pdf'
Write-Host '🤔 TeX Live updates can change the output; if it looks fine, run with -Update to replace the expected PDF'
exit 1
