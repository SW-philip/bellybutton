#!/usr/bin/env bash
set -euo pipefail

TARGET_DIR="${1:-$HOME/.local/bin}"
IGNORE_FILE="$TARGET_DIR/.lintignore"
BRIEF_MODE="${2:-}"
JOBS="${JOBS:-4}"

echo "📦 Scanning: $TARGET_DIR"

# Build find-exclude pattern from .lintignore
EXCLUDES=()
if [[ -f "$IGNORE_FILE" ]]; then
  while IFS= read -r line; do
    [[ -z "$line" || "$line" == \#* ]] && continue
    EXCLUDES+=( -path "$TARGET_DIR/$line" -prune -o )
  done < "$IGNORE_FILE"
fi

# Unified find wrapper
scan_files() {
  find "$TARGET_DIR" "${EXCLUDES[@]}" -type f "$@"
}

# Shell
echo "🔍 Linting Shell..."
sh_issues=$(scan_files -name '*.sh' -print0 | xargs -0 -r -P "$JOBS" shellcheck -f json 2>/dev/null || true)
sh_count=0
[[ -n "$sh_issues" ]] && sh_count=$(echo "$sh_issues" | jq -s 'add | length')
echo "🟢 Shell issues: $sh_count"

# JS/TS
echo "🔍 Linting JavaScript/TypeScript..."
js_output=$(scan_files \\( -name '*.js' -o -name '*.ts' -o -name '*.mjs' \\) -print0 | \
  xargs -0 -r -P "$JOBS" eslint --format json 2>/dev/null || true)

js_count=0
[[ -n "$js_output" ]] && js_count=$(echo "$js_output" | jq '[.[][]] | length')
echo "🟠 JS/TS issues: $js_count"

# CSS
echo "🔍 Linting CSS..."
css_count=0
if find "$TARGET_DIR" -name '*.css' | grep -q .; then
  css_output=$(stylelint "$TARGET_DIR/**/*.css" 2>&1 || true)
  if [[ -n "$css_output" ]]; then
    css_count=$(echo "$css_output" | grep -c '✖')
    echo "$css_output"
  else
    echo "✅ No CSS issues found"
  fi
else
  echo "🟦 Skipping CSS — no .css files found"
fi
echo "🔵 CSS issues: $css_count"

# Python
echo "🔍 Linting Python..."
py_count=0
py_output=$(scan_files -name '*.py' -print0 | xargs -0 -r -P "$JOBS" flake8 2>/dev/null || true)
[[ -n "$py_output" ]] && py_count=$(echo "$py_output" | wc -l)
echo "🟣 Python issues: $py_count"

# JSON
echo "🔍 Linting JSON..."
json_count=$(scan_files -name '*.json' -print0 | xargs -0 -r -P "$JOBS" -n1 jsonlint 2>&1 | grep -c 'line' || true)
echo "🟤 JSON issues: $json_count"

# YAML
echo "🔍 Linting YAML..."
yaml_count=$(scan_files -name '*.yml' -o -name '*.yaml' -print0 | xargs -0 -r -P "$JOBS" -n1 yamllint -f parsable 2>/dev/null | wc -l)
echo "🟡 YAML issues: $yaml_count"

# Summary
if [[ "$BRIEF_MODE" == "--summary" ]]; then
  echo
  echo "🧾 Summary:"
  printf "  🟢 Shell:   %s\n  🟠 JS/TS:   %s\n  🔵 CSS:     %s\n  🟣 Python:  %s\n  🟤 JSON:    %s\n  🟡 YAML:    %s\n" \
    "$sh_count" "$js_count" "$css_count" "$py_count" "$json_count" "$yaml_count"
fi

echo
read -rp "💡 Would you like to auto-fix all detected issues? [y/N] " do_fix
