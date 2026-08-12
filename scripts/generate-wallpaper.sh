#!/usr/bin/env bash
# Regenerate the OpenCode wallpaper pair (dark + light). Requires ImageMagick 7.
# Minimal design: warm neutral base, very soft center glow, and the official
# OpenCode simple wordmark centered (white on dark / black on light).
# Output: one wallpaper package "OpenCode" with light/dark variants:
#   contents/images/        light variant (used with light color schemes)
#   contents/images_dark/   dark variant (used with dark color schemes)
# Plasma auto-switches between them when the color scheme changes.
# Usage: ./generate-wallpaper.sh [output-dir] [WIDTHxHEIGHT]
set -e

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTDIR="${1:-$HERE/../wallpaper}"
SIZE="${2:-3840x2160}"
W="${SIZE%x*}"; H="${SIZE#*x}"

make_wallpaper() {
    # $1 base  $2 glow  $3 wordmark-png  $4 vignette  $5 out
    local BASE="$1" GLOW="$2" WORDMARK="$3" VIGN="$4" OUT="$5"
    local WORDTMP WW WH

    # official wordmark centered, scaled to 30% of canvas width
    WORDTMP="$(mktemp --suffix=.png)"
    WW=$(( W * 30 / 100 ))
    magick "$WORDMARK" -resize "${WW}x" -strip "$WORDTMP"
    WW="$(magick identify -format '%w' "$WORDTMP")"
    WH="$(magick identify -format '%h' "$WORDTMP")"

    magick -size "$SIZE" xc:"$BASE" \
        \( -size "$SIZE" radial-gradient:"$GLOW"-none \) -compose over -composite \
        \( "$WORDTMP" \) -gravity Center -compose over -composite \
        \( -size "$SIZE" radial-gradient:'rgba(255,255,255,0)'-"$VIGN" \) -compose over -composite \
        -attenuate 0.04 +noise Gaussian -depth 8 -strip -quality 92 "$OUT"

    rm -f "$WORDTMP"
    echo "Wrote $OUT ($SIZE)"
}

make_wallpaper '#211E1E' 'rgba(250,178,131,0.10)' "$HERE/../assets/opencode-wordmark-simple-dark.png" 'rgba(12,12,12,0.72)' "$OUTDIR/OpenCode/contents/images_dark/$SIZE.png"
make_wallpaper '#F1ECEC' 'rgba(214,140,39,0.08)' "$HERE/../assets/opencode-wordmark-simple-light.png" 'rgba(96,90,90,0.12)' "$OUTDIR/OpenCode/contents/images/$SIZE.png"
