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
if ($LASTEXITCODE) { throw "❌　コンパイルに失敗しました (exit $LASTEXITCODE)" }
latexmk -cd -r "$check\latexmkrc" -c "$check\sample.tex" | Out-Null

if ($Update) {
    Move-Item -Force $actual $expected
    Write-Host "⚠️ check/expected.pdf を更新しました。"
    exit 0
}

if ((Get-FileHash $actual).Hash -eq (Get-FileHash $expected).Hash) {
    Remove-Item $actual
    Write-Host '✅ check/expected.pdf と一致しました。'
    exit 0
}
Write-Host '🚨 check/expected.pdf と一致しません。check/sample.pdf と見比べてください。'
Write-Host '🤔 TeX Live の更新で差が出ることもあります。問題がなければ -Update で正解を更新します。'
exit 1
