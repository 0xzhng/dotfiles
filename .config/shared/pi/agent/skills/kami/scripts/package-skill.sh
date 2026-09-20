#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT="${1:-"$ROOT/dist/kami.zip"}"

mkdir -p "$(dirname "$OUT")"
rm -f "$OUT"

cd "$ROOT"

zip -qr "$OUT" . \
  -x ".git/*" \
  -x ".vercel/*" \
  -x "dist/*" \
  -x "__pycache__/*" \
  -x "*.pyc" \
  -x ".DS_Store" \
  -x "*/.DS_Store" \
  -x "assets/examples/*" \
  -x "assets/fonts/TsangerJinKai02-W04.ttf" \
  -x "assets/fonts/TsangerJinKai02-W05.ttf"

if zipinfo -1 "$OUT" | grep -qE 'assets/fonts/TsangerJinKai02-W0[45]\.ttf$'; then
  echo "✗ bundled TsangerJinKai02 TTF found in $OUT" >&2
  exit 1
fi

echo "✓ wrote $OUT"
