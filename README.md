# TeX Setup

$\TeX$ 環境を Windows/macOS や GitHub Actions にセットアップするための **個人的な** 設定ファイルとスクリプトです。

## 🚀 セットアップ手順

### Windows/macOS にセットアップする

1. 以下のスクリプトを実行することで、端末に最小構成の TeX Live を導入し、どの文書でも使うような基本的なパッケージ（以降、「基本パッケージ」と呼ぶ。）をインストールします

   ```powershell
   # Windows
   scripts\setup.ps1
   ```
   ```sh
   # macOS
   sudo scripts/setup.sh
   ```
2. 試しに以下を実行し、`check/sample.tex` ファイルが期待どおりにコンパイルされることを確認します

   ```powershell
   # Windows
   # PATH を反映させるために、ターミナルを開き直してから実行します
   scripts\check.ps1
   ```
   ```sh
   # macOS
   scripts/check.sh
   ```
3. `✅ check/expected.pdf と一致しました。` と返れば OK です

### GitHub Actions にセットアップする

1. Workflow の yml に以下のように書きます

   ```yml
   - uses: actions/checkout@v7
   - uses: otTATto/tex-setup@v1
     with: 
       depends: path/to/DEPENDS.txt   # 任意: 基本パッケージの他に追加で入れたいパッケージを指定
   ```

- `depends`: ワークスペースからの相対パスで、形式はこのリポジトリの `DEPENDS.txt` と同じ `hard <pkg>` 行です
- `cache`: インストール先をキャッシュし、2 回目以降はインストールを飛ばします（既定は `true` です）
- ubuntu / windows / macos のランナーに対応しています

## 📝 設定ファイルとスクリプト

### ⚙️ 設定ファイル

各種設定ファイルは以下のとおりです。

| ファイル名 | 役割 |
| :-- | :-- |
| `texlive.profile` | TeX Live のインストール設定 | 
| `DEPENDS.txt` | インストールする基本パッケージの定義 |

### 📦 setup スクリプト

setup スクリプトは、以下の 3 つのことを行います。

1. TeX Live 公式インストーラ `install-tl` を取得する
2. `install-tl` に `texlive.profile` を渡して TeX Live をインストールする
3. TeX Live に同梱されるパッケージマネージャ `tlmgr` に `DEPENDS.txt` を渡して基本パッケージをインストールする

#### \[補足\] TeX Live のインストール先を変えたい

無指定の場合、TeX Live は `install-tl` の既定の場所（Windows: `C:\texlive\YYYY`, macOS: `/usr/local/texlive/YYYY`）にインストールされますが、任意の場所にインストールしたい場合は、以下のように指定してインストールします。

```powershell
# Windows
scripts\setup.ps1 -TexDir <path>
```
```sh
# macOS
sudo scripts/setup.sh --texdir <path>
```

### ⚖️ check スクリプト

check スクリプトは、以下の 2 つのことを行います。

1. `latexmk` で `check/sample.tex` をコンパイルする
2. 生成された `check/sample.pdf` が期待する `check/expected.pdf` と一致するか検証する

#### \[補足\] 期待するファイルを新しいものに置き換えたい

`check/sample.tex` を更新した場合や、`latexmk` が更新されて生成される PDF が変わった場合などには、以下を実行して、期待するファイル `check/expected.pdf` を新しく作り直すことができます。

```powershell
# Windows
scripts\check.ps1 -Update
```
```sh
# macOS
scripts/check.sh --update
```

## 📖 参考

- [**TeX Live** - TeX Wiki](https://texwiki.texjp.org/?TeX%20Live)
- [**TeX Live package dependencies**](https://tug.org/texlive/pkgdepend.html)
- [**install-tl** - TeX Live cross-platform installer](https://www.tug.org/texlive/doc/install-tl.html)
- [**latexmk** - TeX Wiki](https://texwiki.texjp.org/?Latexmk)
