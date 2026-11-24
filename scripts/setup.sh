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

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

# 1. install-tl を取得
curl -fsSL --retry 3 -o "$work/install-tl-unx.tar.gz" https://mirror.ctan.org/systems/texlive/tlnet/install-tl-unx.tar.gz
tar -xzf "$work/install-tl-unx.tar.gz" -C "$work"
installer=$(echo "$work"/install-tl-*)

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
