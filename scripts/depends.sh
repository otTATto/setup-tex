#!/bin/sh
# 入っている TeX Live に、DEPENDS.txt の hard 行のパッケージを追加でインストールする
#
# 使い方: scripts/depends.sh [--texdir <dir>] [<DEPENDS.txt>]
#   <DEPENDS.txt>  hard <pkg> 行を並べたファイル（省略時はカレントディレクトリの DEPENDS.txt）
#   --texdir       TeX Live のインストール先（省略時は PATH 上の TeX Live から求める）
set -eu

texdir=
file=
while [ $# -gt 0 ]; do
    case $1 in
        --texdir) texdir=$2; shift 2 ;;
        -*) echo "❌ unknown option: $1" >&2; exit 2 ;;
        *)
            if [ -n "$file" ]; then echo "❌ too many arguments: $1" >&2; exit 2; fi
            file=$1; shift ;;
    esac
done
file=${file:-DEPENDS.txt}

if [ ! -f "$file" ]; then
    echo "❌ $file が見つかりません。" >&2
    exit 1
fi

if [ -z "$texdir" ]; then
    if ! command -v kpsewhich > /dev/null; then
        echo '❌ TeX Live が見つかりません。先に setup でインストールしてください。' >&2
        exit 1
    fi
    texdir=$(kpsewhich -var-value=SELFAUTOPARENT)
fi
tlmgr=$(echo "$texdir"/bin/*/tlmgr)
if [ ! -x "$tlmgr" ]; then
    echo "❌ $texdir に tlmgr が見つかりません。" >&2
    exit 1
fi

# インストール先と、コマンドのリンクを張る先の両方に書き込めないときは root でやり直す
sys_bin=$("$tlmgr" option sys_bin | sed 's/.*: //')
if [ "$(id -u)" -ne 0 ] && { [ ! -w "$texdir" ] || [ ! -w "$sys_bin" ]; }; then
    echo "🔑 $texdir と $sys_bin に書き込むため、sudo で実行します。"
    exec sudo sh "$0" --texdir "$texdir" "$file"
fi

packages=$(sed -n 's/^[[:space:]]*hard[[:space:]]\{1,\}\([^[:space:]#]\{1,\}\).*/\1/p' "$file")
if [ -z "$packages" ]; then
    echo "⚠️ $file に hard 行がありません。"
    exit 0
fi

# shellcheck disable=SC2086
"$tlmgr" install $packages
# 増えたコマンドにもシンボリックリンクを張る
"$tlmgr" path add

echo "✅ $file のパッケージをインストールしました。"
