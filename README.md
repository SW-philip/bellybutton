# 🫃 Bellybutton

> _"A little lint in your shell never hurt anyone. Until now."_

**Bellybutton** is a self-contained CLI lint suite for your local bin or dotfiles repo. It checks Bash, Python, JavaScript, Go, and Rust files for issues, fixes what it can, and even complains when you forget your shebangs.

## 🧠 Features

- ✅ ShellCheck for `.sh` scripts
- ✅ ESLint (with autofix!) for `.js`
- ✅ Ruff for `.py` (fast Python linting)
- ✅ golangci-lint for Go
- ✅ cargo clippy for Rust projects
- ✅ Broken symlink detection
- ✅ Executable files with no shebang warning & auto-repair
- ✅ `.lintignore` support
- ✅ `notify-send` summary
- ✅ Brief mode (`--brief`) or non-interactive (`--no-prompt`) modes

## 📦 Installation

Clone the repo:

```bash
git clone https://github.com/YOUR_USERNAME/bellybutton.git
cd bellybutton
chmod +x grammar.sh
```

(Optionally add to your PATH)

```bash
ln -s "$PWD/grammar.sh" ~/.local/bin/grammar
```

## 🛠 Dependencies

Make sure you have the following installed:

- `bash`
- `shellcheck`
- `eslint` + a config (`eslint.config.js`)
- `ruff`
- `golangci-lint` *(optional, for Go)*
- `cargo` *(optional, for Rust)*
- `notify-send` *(optional, for desktop notifications)*

Install the basics on Arch:

```bash
sudo pacman -S shellcheck nodejs ruff
npm install -g eslint
cargo install cargo-clippy
yay -S golangci-lint-bin
```
## 🧠 Install via AUR

```bash
yay -S bellybutton
# or
paru -S bellybutton

## 📂 Usage

```bash
grammar                 # Lints ~/floodshell/bin (default)
grammar ~/my/scripts    # Lint a custom directory
grammar --brief         # Hide long-form output
grammar --no-prompt     # Skip ESLint autofix prompt
```

## 🚫 Ignoring Files

Create a `.lintignore` in the target directory:

```
old_script.sh
legacy/*.py
```

## 📤 Publishing

If you’re feeling bold:

```bash
git init
git remote add origin https://github.com/YOUR_USERNAME/bellybutton.git
git add .
git commit -m "Initial release of bellybutton"
git push -u origin main
```

---

## 🤘 Author

Phil Repko. Breaking your shell so you can rebuild it stronger.
