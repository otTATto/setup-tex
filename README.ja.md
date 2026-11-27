<h1 align="center">Setup TeX</h1>

<p align="center"><strong><em>Minimal TeX Live. One command. On your PC and in CI.</em></strong></p>

<p align="center">
  <a href="https://www.npmjs.com/package/@ottatto/setup-tex"><img src="https://img.shields.io/npm/v/@ottatto/setup-tex?logo=npm&style=for-the-badge" alt="npm"></a>
  <img src="https://img.shields.io/node/v/@ottatto/setup-tex?logo=nodedotjs&style=for-the-badge" alt="Node.js">
  <a href="https://github.com/otTATto/setup-tex/releases"><img src="https://img.shields.io/github/v/release/otTATto/setup-tex?logo=github&style=for-the-badge" alt="GitHub Release"></a>
</p>
<p align="center">
  <a href="https://tug.org/texlive/"><img src="https://img.shields.io/badge/TeX_Live-scheme--infraonly-008080?logo=latex&style=for-the-badge" alt="TeX Live"></a>
</p>

[English](README.md) | 日本語

$\TeX$ 環境を PC や GitHub Actions にセットアップするための「**個人的な**」設定ファイルとスクリプトです。

## 🚀 セットアップ手順

### 💻 PC にセットアップする

> [!IMPORTANT]
> Node.js（22 以降）が必要です。

1. 以下を実行して、端末の任意の場所から `stex` コマンドを使えるようにします

   ```sh
   npm install -g @ottatto/setup-tex
   ```
2. 以下を実行することで、端末に最小構成の TeX Live を導入し、どの文書でも使うような基本的なパッケージ（以降、「基本パッケージ」と呼ぶ。）をインストールします

   ```sh
   stex setup
   ```

   - macOS では、途中で `sudo` のパスワードが必要になります
   - Windows では、PATH を反映させるために、終了後にターミナルを開き直します
3. 試しに以下を実行し、同梱のサンプルが期待どおりにコンパイルされることを確認します

   ```sh
   stex check
   ```
4. `✅ Matches check/expected.pdf` と返れば OK です

<details>
<summary><strong>補足① インストールせずに試してみたい</strong></summary>

- 以下のように `npx` を使えば、インストールせずに `stex` コマンドを試せます

  ```sh
  npx @ottatto/setup-tex@latest setup
  ```

- ただし、以降の説明における `stex` を `npx @ottatto/setup-tex@latest` に読み替えて実行する必要があります

</details>

<details>
<summary><strong>補足② 文書ごとに追加でパッケージを入れたい</strong></summary>

- 文書のディレクトリに、基本パッケージと同じ形式（`hard <pkg>` 行）の `DEPENDS.txt` を置いておき、そこで以下を実行すると、足りないパッケージを追加でインストールできます

  ```sh
  cd path/to/document
  stex depends                       # ./DEPENDS.txt を読む
  stex depends path/to/DEPENDS.txt
  ```

</details>

<details>
<summary><strong>補足③ Clone してスクリプトを直接実行したい</strong></summary>

- `stex` の各コマンドは、`scripts/` のスクリプトを呼んでいるだけなので、Clone したリポジトリで直接実行することもできます

  ```powershell
  # Windows
  scripts\setup.ps1
  scripts\depends.ps1 path\to\DEPENDS.txt
  scripts\check.ps1
  ```
  ```sh
  # macOS
  scripts/setup.sh
  scripts/depends.sh path/to/DEPENDS.txt
  scripts/check.sh
  ```

</details>

### 🤖 GitHub Actions にセットアップする

1. Workflow の yml に以下のように書きます

   ```yml
   - uses: actions/checkout@v7
   - uses: otTATto/setup-tex@v1
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

<details>
<summary><strong>［補足］TeX Live のインストール先を変えたい</strong></summary>

- 無指定の場合、TeX Live は `install-tl` の既定の場所（Windows: `C:\texlive\YYYY`, macOS: `/usr/local/texlive/YYYY`）にインストールされます
- 任意の場所にインストールしたい場合は、以下のように指定してインストールします

   ```sh
   stex setup --texdir <path>
   ```

</details>

### 🧩 depends スクリプト

depends スクリプトは、以下の 2 つのことを行います。

1. 指定の `DEPENDS.txt`（省略時はカレントディレクトリの `DEPENDS.txt`）から `hard <pkg>` 行のパッケージを読み取る
2. 既に入っている TeX Live に、`tlmgr` でそのパッケージを追加でインストールし、増えたコマンドにも PATH を通す

- インストール先は PATH 上の TeX Live から決められます
- 別の場所の TeX Live に入れる場合は `--texdir <path>` を指定してください

### ⚖️ check スクリプト

check スクリプトは、以下の 2 つのことを行います。

1. `latexmk` で `check/sample.tex` をコンパイルする
2. 生成された `check/sample.pdf` が期待する `check/expected.pdf` と一致するか検証する

<details>
<summary><strong>［補足］期待するファイルを新しいものに置き換えたい</strong></summary>

- `check/sample.tex` を更新した場合や、TeX Live の更新で生成される PDF が変わった場合などには、以下を実行して、期待するファイル `check/expected.pdf` を新しく作り直すことができます

   ```powershell
   # Windows
   scripts\check.ps1 -Update
   ```
   ```sh
   # macOS
   scripts/check.sh --update
   ```

</details>

## 🗂️ リポジトリの構造

大まかには、以下のような構造になっています。

```
.
├── bin/              # stex コマンドの入口
├── check/            # check スクリプトが検証する TeX ファイルなど
├── scripts/          # setup・depends・check スクリプト
├── texlive.profile   # TeX Live のインストール設定
├── DEPENDS.txt       # インストールする基本パッケージの定義
├── action.yml        # GitHub Actions から setup・depends スクリプトを呼び出す action
├── package.json 
└── README.md
```

## 📖 参考

- [**TeX Live** - TeX Wiki](https://texwiki.texjp.org/?TeX%20Live)
- [**TeX Live package dependencies**](https://tug.org/texlive/pkgdepend.html)
- [**install-tl** - TeX Live cross-platform installer](https://www.tug.org/texlive/doc/install-tl.html)
- [**latexmk** - TeX Wiki](https://texwiki.texjp.org/?Latexmk)
