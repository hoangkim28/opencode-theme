#!/usr/bin/env bash
# Generate preview images for the OpenCode themes from the wallpapers + palette
# swatches. No screenshots — fully synthetic, safe to publish. Requires ImageMagick 7.
# Usage: ./generate-preview.sh [out-dir] [WIDTHxHEIGHT]
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTDIR="${1:-$HERE/../previews}"
SIZE="${2:-1280x720}"
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

FONT="$(fc-match -f '%{file}' 'DejaVu Sans' 2>/dev/null || true)"
FONTBOLD="$(fc-match -f '%{file}' 'DejaVu Sans:bold' 2>/dev/null || true)"
FONT_ARGS=()
FONT_BOLD_ARGS=()
[[ -n "$FONT" ]] && FONT_ARGS=(-font "$FONT")
[[ -n "$FONTBOLD" ]] && FONT_BOLD_ARGS=(-font "$FONTBOLD")

make_preview() {
    # $1 wallpaper  $2 name  $3 title color  $4 label color  $5 out  then swatches "hex|label"...
    local WALL="$1" NAME="$2" TITLECOL="$3" LABELCOL="$4" OUT="$5"
    local TMP DRAW CW CH CX CY n pad gap size sy i hex lab x item
    local -a SWATCH_ARGS=() LABEL_ARGS=()
    shift 5
    local SW=("$@")

    TMP="$(mktemp --suffix=.png)"
    TEMP_FILES+=("$TMP")
    magick "$WALL" -resize "${SIZE}^" -gravity center -extent "$SIZE" "$TMP"

    CW=$((W - 40))
    ((CW > 1040)) && CW=1040
    CH=210
    ((H < 340)) && CH=190
    CX=$(((W - CW) / 2))
    CY=$((H - CH - 35))
    ((CY < 20)) && CY=20
    n=${#SW[@]}; pad=30; gap=12
    size=$(( (CW-2*pad-(n-1)*gap)/n ))
    ((size < 8)) && size=8
    sy=$(( CY+92 ))

    DRAW="roundrectangle $CX,$CY $((CX+CW)),$((CY+CH)) 24,24"
    i=0
    for item in "${SW[@]}"; do
        hex="${item%%|*}"; lab="${item##*|}"
        x=$(( CX+pad+i*(size+gap) ))
        SWATCH_ARGS+=(-fill "$hex" -draw "roundrectangle $x,$sy $((x+size)),$((sy+size)) 12,12")
        LABEL_ARGS+=(-fill "$LABELCOL" -annotate "+${x}+$((sy+size+26))" "$lab")
        i=$((i+1))
    done

    magick "$TMP" \
        -fill 'rgba(33,30,30,0.82)' -draw "$DRAW" \
        -fill "$TITLECOL" "${FONT_BOLD_ARGS[@]}" -pointsize 40 -annotate "+$((CX+pad))+$((CY+50))" "$NAME" \
        -fill '#9A988F' "${FONT_ARGS[@]}" -pointsize 18 -annotate "+$((CX+pad+2))+$((CY+76))" 'KDE Plasma Global Theme' \
        "${SWATCH_ARGS[@]}" \
        "${FONT_ARGS[@]}" -pointsize 15 "${LABEL_ARGS[@]}" \
        "$OUT"
}

mkdir -p "$OUTDIR"
make_preview "$HERE/../wallpaper/OpenCode/contents/images_dark/3840x2160.png" "OpenCode Dark" '#E9E8E7' '#B7B5A9' "$OUTDIR/preview-dark.png" \
    "#211E1E|bg" "#2A2626|surface" "#CFCECD|text" "#FAB283|accent" \
    "#FFC09F|hover" "#D98A5E|deep" "#7FD88F|green" "#E5C07B|yellow" \
    "#5C9CF5|blue" "#9D7CD8|purple"
make_preview "$HERE/../wallpaper/OpenCode/contents/images/3840x2160.png" "OpenCode Light" '#211E1E' '#6B6666' "$OUTDIR/preview-light.png" \
    "#F1ECEC|bg" "#E7E1E1|surface" "#211E1E|text" "#D68C27|accent" \
    "#C47A22|hover" "#B06F1E|deep" "#3D9A57|green" "#B0851F|yellow" \
    "#3B7DD8|blue" "#9D7CD8|purple"

echo "Wrote $OUTDIR/preview-dark.png and $OUTDIR/preview-light.png ($SIZE)"
