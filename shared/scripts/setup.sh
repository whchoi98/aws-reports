#!/usr/bin/env bash
# One-time setup for the aws-reports skills (benchmark-report, poc-report): npm packages, fonts (NanumSquareOTF, D2Coding), uv check.
# Safe to re-run; it skips what is already there.
set -euo pipefail
cd "$(dirname "$0")"

if [ ! -d node_modules/docx ] || [ ! -d node_modules/marked ] || [ ! -d node_modules/docx-preview ]; then
  npm install --no-fund --no-audit --silent
fi

case "$(uname -s)" in
  Darwin) FONT_ROOT="$HOME/Library/Fonts" ;;
  *) FONT_ROOT="$HOME/.local/share/fonts" ;;
esac

# install_font <file to look for> <npm package under @kfonts> <version> <subdir>
# Fonts come from the npm registry packages @kfonts/* (OFL-1.1); only the src/ font files are copied.
install_font() {
  local probe=$1 pkg=$2 ver=$3 sub=$4
  local d found=""
  for d in "$FONT_ROOT" /usr/share/fonts /usr/local/share/fonts /Library/Fonts; do
    [ -d "$d" ] && [ -n "$(find "$d" -name "$probe" -print -quit 2>/dev/null)" ] && found=1
  done
  if [ -n "$found" ]; then
    echo "font ok: $probe"; return
  fi
  local tmp; tmp=$(mktemp -d)
  curl -sSfL "https://registry.npmjs.org/@kfonts/$pkg/-/$pkg-$ver.tgz" -o "$tmp/pkg.tgz"
  tar xzf "$tmp/pkg.tgz" -C "$tmp"
  mkdir -p "$FONT_ROOT/$sub"
  find "$tmp/package/src" -maxdepth 1 \( -name '*.otf' -o -name '*.ttf' \) -exec cp {} "$FONT_ROOT/$sub/" \;
  rm -rf "$tmp"
  command -v fc-cache >/dev/null && fc-cache -f "$FONT_ROOT/$sub" >/dev/null
  echo "font installed: $FONT_ROOT/$sub ($pkg $ver, OFL-1.1)"
}
install_font NanumSquareR.otf nanum-square-otf 0.2.0 nanumsquare-otf
install_font D2Coding.ttf d2coding 0.2.0 d2coding

if command -v uv >/dev/null; then
  echo "uv ok: $(uv --version)"
else
  echo "WARN: uv not found. Install it (https://docs.astral.sh/uv/) or pip install fonttools brotli matplotlib playwright"
fi
echo "setup done"
