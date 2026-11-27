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
    echo '⚠️ Updated check/expected.pdf'
    exit 0
fi

if cmp -s "$actual" "$expected"; then
    rm -f "$actual"
    echo '✅ Matches check/expected.pdf'
    exit 0
fi
echo '🚨 Does not match check/expected.pdf; compare it with check/sample.pdf'
echo '🤔 TeX Live updates can change the output; if it looks fine, run with --update to replace the expected PDF'
exit 1
