#!/usr/bin/env bash
set -euo pipefail

TARGET_DIR="${1:-$HOME/floodshell/bin}"
IGNORE_FILE="$TARGET_DIR/.lintignore"
BRIEF_MODE="${2:-}"

printf "📦 Scanning: %s\n" "$TARGET_DIR"

# Build find-exclude pattern from .lintignore
EXCLUDES=()
if [[ -f "$IGNORE_FILE" ]]; then
  while IFS= read -r line; do
    [[ -z "$line" || "$line" == \#* ]] && continue
    EXCLUDES+=( -path "$TARGET_DIR/$line" -prune -o )
  done < "$IGNORE_FILE"
fi

# ShellCheck
printf "🔍 Checking shell scripts...\n"
sh_issues=$(find "$TARGET_DIR" "${EXCLUDES[@]}" -type f -name '*.sh' -exec shellcheck {} + 2>/dev/null || true)
sh_count=$(echo "$sh_issues" | grep -c '^In ' || true)
[[ "$BRIEF_MODE" != "--brief" ]] && echo "$sh_issues"

# ESLint
js_count=0
if command -v eslint >/dev/null; then
  printf "\n🔍 Checking JavaScript with ESLint...\n"
  js_issues=$(find "$TARGET_DIR" "${EXCLUDES[@]}" -type f -name '*.js' -exec eslint {} + 2>/dev/null || true)
  js_count=$(echo "$js_issues" | grep -c '^\s\+[0-9]' || true)
  [[ "$BRIEF_MODE" != "--brief" ]] && echo "$js_issues"
  if [[ "$js_count" -gt 0 && "$BRIEF_MODE" != "--no-prompt" ]]; then
    read -rp $'\n🧹 Fix JavaScript lint errors automatically? [y/N]: ' RESP
    if [[ "$RESP" =~ ^[Yy]$ ]]; then
      find "$TARGET_DIR" "${EXCLUDES[@]}" -type f -name '*.js' -exec eslint --fix {} +
      echo "✅ ESLint auto-fix complete."
    fi
  fi
else
  echo "⚠️  ESLint not found. Skipping JS lint."
fi

# Ruff
py_count=0
if command -v ruff >/dev/null; then
  printf "\n🐍 Checking Python with Ruff...\n"
  py_issues=$(find "$TARGET_DIR" "${EXCLUDES[@]}" -type f -name '*.py' -exec ruff check {} + 2>/dev/null || true)
  py_count=$(echo "$py_issues" | grep -c '^[^[:space:]]\+:[0-9]' || true)
  [[ "$BRIEF_MODE" != "--brief" ]] && echo "$py_issues"
else
  echo "⚠️  Ruff not found. Skipping Python lint."
fi

# Go
go_count=0
if command -v golangci-lint >/dev/null; then
  printf "\n🐹 Checking Go with golangci-lint...\n"
  go_output=$(golangci-lint run "$TARGET_DIR" 2>&1 || true)
  if echo "$go_output" | grep -q 'no go files to analyze'; then
    echo "ℹ️  No Go files to analyze."
    go_output=""
  else
    [[ "$BRIEF_MODE" != "--brief" ]] && echo "$go_output"
  fi
  go_count=$(echo "$go_output" | grep -c '^' || true)
else
  echo "⚠️  golangci-lint not found. Skipping Go lint."
fi

# Rust
rs_count=0
if command -v cargo >/dev/null && [[ -f "$TARGET_DIR/Cargo.toml" ]]; then
  printf "\n🦀 Checking Rust with cargo clippy...\n"
  rs_output=""
  cd "$TARGET_DIR" && rs_output=$(cargo clippy --message-format=short 2>&1 || true)
  if echo "$rs_output" | grep -q 'no targets specified'; then
    echo "ℹ️  No Rust targets to analyze."
    rs_output=""
  else
    [[ "$BRIEF_MODE" != "--brief" ]] && echo "$rs_output"
  fi
  rs_count=$(echo "$rs_output" | grep -c '^' || true)
else
  echo "⚠️  Rust project or cargo not found. Skipping Rust lint."
fi

# Shebang fixer
printf "\n🔒 Checking executable bits...\n"
while IFS= read -r -d '' file; do
  if [[ -x "$file" && ! $(head -n1 "$file") =~ ^#! ]]; then
    echo "⚠️  $file: Executable but no shebang"
    case "$file" in
      *.sh) sed -i '1i#!/usr/bin/env bash' "$file" ;;
      *.js) sed -i '1i#!/usr/bin/env node' "$file" ;;
      *.py) sed -i '1i#!/usr/bin/env python3' "$file" ;;
    esac
  fi
done < <(find "$TARGET_DIR" "${EXCLUDES[@]}" -type f -perm -u+x -print0)

# Symlink checker
printf "\n🔗 Checking broken symlinks...\n"
find "$TARGET_DIR" -xtype l -print || true

# Summary
printf "\n🧾 Bellybutton Clean:\n"
echo "✅ Shell: $sh_count issues"
echo "✅ JavaScript: $js_count issues"
echo "✅ Python: $py_count issues"
echo "✅ Go: $go_count issues"
echo "✅ Rust: $rs_count issues"

if command -v notify-send >/dev/null; then
  notify-send "Bellybutton Scan Complete" "Shell: $sh_count, JS: $js_count, Python: $py_count, Go: $go_count, Rust: $rs_count"
fi
