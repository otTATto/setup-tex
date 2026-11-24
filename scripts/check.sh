#!/bin/sh
# check/sample.tex をコンパイルし、期待する check/expected.pdf と一致するか確かめる
#
# 使い方: scripts/check.sh [--update]
#   --update  比較せず、生成した PDF で check/expected.pdf を置き換える
set -eu

check=$(cd "$(dirname "$0")/../check" && pwd)
actual=$check/sample.pdf
expected=$check/expected.pdf

# 日時を固定し、同じ入力からは同じバイト列の PDF が出るようにする
export SOURCE_DATE_EPOCH=0 FORCE_SOURCE_DATE=1

latexmk -cd -r "$check/latexmkrc" "$check/sample.tex"
latexmk -cd -r "$check/latexmkrc" -c "$check/sample.tex" > /dev/null

if [ "${1:-}" = --update ]; then
    mv -f "$actual" "$expected"
    echo '⚠️ check/expected.pdf を更新しました。'
    exit 0
fi

if cmp -s "$actual" "$expected"; then
    rm -f "$actual"
    echo '✅ check/expected.pdf と一致しました。'
    exit 0
fi
echo '🚨 check/expected.pdf と一致しません。check/sample.pdf と見比べてください。'
echo '🤔 TeX Live の更新で差が出ることもあります。問題がなければ --update で正解を更新します。'
exit 1
