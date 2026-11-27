#!/bin/sh
# 最小構成の TeX Live を導入し、DEPENDS.txt のパッケージをインストールする
#
# 使い方: sudo scripts/setup.sh [--texdir <dir>]
#   --texdir  インストール先（省略時は install-tl の既定 /usr/local/texlive/YYYY になる）
set -eu

root=$(cd "$(dirname "$0")/.." && pwd)
texdir=
while [ $# -gt 0 ]; do
    case $1 in
        --texdir) texdir=$2; shift 2 ;;
        *) echo "❌ unknown option: $1" >&2; exit 2 ;;
    esac
done

# mirror.ctan.org は毎回別のミラーへリダイレクトするが、
# curl の --retry は証明書エラーなどを再試行しないので、失敗したら取得し直す
fetch_ctan() {
    url=https://mirror.ctan.org/$1
    out=$2
    max=5
    i=1
    while :; do
        curl -fsSL --retry 3 -o "$out" "$url" && return 0
        status=$?
        if [ "$i" -ge "$max" ]; then
            echo "❌ failed to fetch $url after $max attempts (curl exit $status)" >&2
            return 1
        fi
        echo "⚠️ attempt $i/$max to fetch $url failed (curl exit $status); retrying with another mirror in $((i * 5))s" >&2
        sleep $((i * 5))
        i=$((i + 1))
    done
}

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

# 1. install-tl を取得
fetch_ctan systems/texlive/tlnet/install-tl-unx.tar.gz "$work/install-tl-unx.tar.gz"
tar -xzf "$work/install-tl-unx.tar.gz" -C "$work"
installer=$(echo "$work"/install-tl-[0-9]*)

if [ -z "$texdir" ]; then
    year=$(sed -n 's/.*version \([0-9]\{4\}\).*/\1/p' "$installer/release-texlive.txt" | head -n 1)
    texdir=/usr/local/texlive/$year
fi

# 2. texlive.profile を渡して TeX Live をインストール
"$installer/install-tl" -profile "$root/texlive.profile" -texdir "$texdir"

# 3. DEPENDS.txt のパッケージをインストール
packages=$(sed -n 's/^[[:space:]]*hard[[:space:]]\{1,\}\([^[:space:]#]\{1,\}\).*/\1/p' "$root/DEPENDS.txt")
# shellcheck disable=SC2086
"$(echo "$texdir"/bin/*)/tlmgr" install $packages

echo "✅ TeX Live を $texdir にインストールしました。"
