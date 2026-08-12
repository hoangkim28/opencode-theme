#!/usr/bin/env bash
# Regenerate the OpenCode wallpaper pair (dark + light). Requires ImageMagick 7.
# Minimal design: a uniform warm neutral base and the official OpenCode simple
# wordmark centered (white on dark / black on light). Keeping the base uniform
# avoids visible concentric color bands on large displays.
# Output: one wallpaper package "OpenCode" with light/dark variants:
#   contents/images/        light variant (used with light color schemes)
#   contents/images_dark/   dark variant (used with dark color schemes)
# Plasma auto-switches between them when the color scheme changes.
# Usage: ./generate-wallpaper.sh [output-dir] [WIDTHxHEIGHT]
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTDIR="${1:-$HERE/../wallpaper}"
SIZE="${2:-3840x2160}"
if [[ ! "$SIZE" =~ ^([1-9][0-9]*)x([1-9][0-9]*)$ ]]; then
    echo "ERROR: size must be WIDTHxHEIGHT using positive integers" >&2
    exit 2
fi
W="${BASH_REMATCH[1]}"
H="${BASH_REMATCH[2]}"

TEMP_FILES=()
cleanup() {
    if ((${#TEMP_FILES[@]})); then
        rm -f -- "${TEMP_FILES[@]}"
    fi
}
trap cleanup EXIT

make_wallpaper() {
    # $1 base  $2 wordmark-png  $3 out
    local BASE="$1" WORDMARK="$2" OUT="$3"
    local WORDTMP WW WH

    # official wordmark centered, scaled to 30% of canvas width
    WORDTMP="$(mktemp --suffix=.png)"
    TEMP_FILES+=("$WORDTMP")
    mkdir -p "$(dirname "$OUT")"
    WW=$(( W * 30 / 100 ))
    magick "$WORDMARK" -resize "${WW}x" -strip "$WORDTMP"
    WW="$(magick identify -format '%w' "$WORDTMP")"
    WH="$(magick identify -format '%h' "$WORDTMP")"

    # Keep the background flat: radial glow/vignette layers create visible
    # concentric circles and shift the intended theme color across the canvas.
    magick -size "$SIZE" xc:"$BASE" \
        \( "$WORDTMP" \) -gravity Center -compose over -composite \
        -depth 8 -strip -quality 92 "$OUT"

    echo "Wrote $OUT ($SIZE)"
}

make_wallpaper '#211E1E' "$HERE/../assets/opencode-wordmark-simple-dark.png" "$OUTDIR/OpenCode/contents/images_dark/$SIZE.png"
make_wallpaper '#F1ECEC' "$HERE/../assets/opencode-wordmark-simple-light.png" "$OUTDIR/OpenCode/contents/images/$SIZE.png"
