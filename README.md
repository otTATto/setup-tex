<h1 align="center">Setup TeX</h1>

<p align="center"><strong><em>Minimal <a>TeX Live</a>. One command. On your PC and in CI.</em></strong></p>

<p align="center">
  <a href="https://www.npmjs.com/package/@ottatto/setup-tex"><img src="https://img.shields.io/npm/v/@ottatto/setup-tex?logo=npm&style=for-the-badge" alt="npm"></a>
  <img src="https://img.shields.io/node/v/@ottatto/setup-tex?logo=nodedotjs&style=for-the-badge" alt="Node.js">
  <a href="https://github.com/otTATto/setup-tex/releases"><img src="https://img.shields.io/github/v/release/otTATto/setup-tex?logo=github&style=for-the-badge" alt="GitHub Release"></a>
</p>

English | [日本語](README.ja.md)

My **PERSONAL** config files and scripts for setting up a $\TeX$ environment on a PC or on GitHub Actions.

## 🚀 Setup

### 💻 On Your PC

> [!IMPORTANT]
> Node.js (22 or later) is required.

1. Run the following to make the `stex` command available anywhere in your terminal

   ```sh
   npm install -g @ottatto/setup-tex
   ```
2. Run the following to install a minimal TeX Live along with the packages used in almost every document (the "basic packages")

   ```sh
   stex setup
   ```

   - On macOS, you will be asked for your `sudo` password along the way
   - On Windows, reopen the terminal afterwards to pick up the new PATH
3. To try it out, run the following and make sure the bundled sample compiles as expected

   ```sh
   stex check
   ```
4. If it says `✅ Matches check/expected.pdf`, you are all set

<details>
<summary><strong>TIP 1: Try it without installing</strong></summary>

- With `npx`, you can try the `stex` command without installing it

  ```sh
  npx @ottatto/setup-tex@latest setup
  ```

- In that case, read `stex` in the rest of this README as `npx @ottatto/setup-tex@latest`

</details>

<details>
<summary><strong>TIP 2: Install extra packages per document</strong></summary>

- Put a `DEPENDS.txt` in the same format as the basic packages (`hard <pkg>` lines) in your document's directory, and run the following there to install the missing packages

  ```sh
  cd path/to/document
  stex depends                       # Reads ./DEPENDS.txt
  stex depends path/to/DEPENDS.txt
  ```

</details>

<details>
<summary><strong>TIP 3: Run the scripts directly from a clone</strong></summary>

- Each `stex` command just calls a script in `scripts/`, so you can also run them directly in a clone of this repository

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

### 🤖 On GitHub Actions

1. Write the following in your workflow yml

   ```yml
   - uses: actions/checkout@v7
   - uses: otTATto/setup-tex@v1
     with:
       depends: path/to/DEPENDS.txt   # Optional: extra packages to install besides the basic packages
   ```

- `depends`: A path relative to the workspace, in the same `hard <pkg>` format as this repository's `DEPENDS.txt`
- `cache`: Caches the installation and skips it from the second run on (defaults to `true`)
- Supports ubuntu / windows / macos runners

## 📝 Config Files and Scripts

### ⚙️ Config Files

The config files are as follows.

| File | Role |
| :-- | :-- |
| `texlive.profile` | Installation settings for TeX Live |
| `DEPENDS.txt` | The basic packages to install |

### 📦 setup Script

The setup script does the following 3 things.

1. Fetches `install-tl`, the official TeX Live installer
2. Installs TeX Live by passing `texlive.profile` to `install-tl`
3. Installs the basic packages by passing `DEPENDS.txt` to `tlmgr`, the package manager bundled with TeX Live

<details>
<summary><strong>TIP: Change where TeX Live is installed</strong></summary>

- By default, TeX Live is installed where `install-tl` puts it (Windows: `C:\texlive\YYYY`, macOS: `/usr/local/texlive/YYYY`)
- To install it elsewhere, specify the location as follows

   ```sh
   stex setup --texdir <path>
   ```

</details>

### 🧩 depends Script

The depends script does the following 2 things.

1. Reads the packages on the `hard <pkg>` lines of the given `DEPENDS.txt` (defaults to `DEPENDS.txt` in the current directory)
2. Installs them into the existing TeX Live with `tlmgr`, and puts any new commands on the PATH

- The TeX Live to install into is found from the PATH
- To install into a TeX Live elsewhere, specify `--texdir <path>`

### ⚖️ check Script

The check script does the following 2 things.

1. Compiles `check/sample.tex` with `latexmk`
2. Verifies that the generated `check/sample.pdf` matches the expected `check/expected.pdf`

<details>
<summary><strong>TIP: Replace the expected file</strong></summary>

- When you update `check/sample.tex`, or when a TeX Live update changes the generated PDF, you can regenerate the expected `check/expected.pdf` by running the following

   ```powershell
   # Windows
   scripts\check.ps1 -Update
   ```
   ```sh
   # macOS
   scripts/check.sh --update
   ```

</details>

## 🗂️ Repository Structure

Roughly, the repository is structured as follows.

```
.
├── bin/              # Entry point of the stex command
├── check/            # TeX files and more verified by the check script
├── scripts/          # setup, depends, and check scripts
├── texlive.profile   # Installation settings for TeX Live
├── DEPENDS.txt       # The basic packages to install
├── action.yml        # Action that calls the setup and depends scripts from GitHub Actions
├── package.json
└── README.md
```

## 📖 References

- [**TeX Live**](https://tug.org/texlive/)
- [**TeX Live package dependencies**](https://tug.org/texlive/pkgdepend.html)
- [**install-tl** - TeX Live cross-platform installer](https://www.tug.org/texlive/doc/install-tl.html)
- [**latexmk**](https://ctan.org/pkg/latexmk)
