#!/usr/bin/env bash
# Generate preview images for the OpenCode themes from the wallpapers + palette
# swatches. No screenshots — fully synthetic, safe to publish. Requires ImageMagick 7.
# Usage: ./generate-preview.sh [out-dir] [WIDTHxHEIGHT]
set -e

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTDIR="${1:-$HERE/../previews}"
SIZE="${2:-1280x720}"
W="${SIZE%x*}"; H="${SIZE#*x}"

FONT="$(fc-match -f '%{file}' 'DejaVu Sans' 2>/dev/null || true)"
FONTBOLD="$(fc-match -f '%{file}' 'DejaVu Sans:bold' 2>/dev/null || true)"
[ -n "$FONT" ] && FONT="-font $FONT"
[ -n "$FONTBOLD" ] && FONTBOLD="-font $FONTBOLD"

make_preview() {
    # $1 wallpaper  $2 name  $3 title color  $4 label color  $5 out  then swatches "hex|label"...
    local WALL="$1" NAME="$2" TITLECOL="$3" LABELCOL="$4" OUT="$5"
    local TMP DRAW SWDRAW LABELS CW CH CX CY n pad gap size sy i hex lab x
    shift 5
    local SW=("$@")

    TMP="$(mktemp --suffix=.png)"
    magick "$WALL" -resize "${SIZE}^" -gravity center -extent "$SIZE" "$TMP"

    CW=1040; CH=210; CX=$(( (W-CW)/2 )); CY=$(( H-CH-70 ))
    n=${#SW[@]}; pad=40; gap=18
    size=$(( (CW-2*pad-(n-1)*gap)/n ))
    sy=$(( CY+92 ))

    DRAW="roundrectangle $CX,$CY $((CX+CW)),$((CY+CH)) 24,24"
    SWDRAW=""
    LABELS=""
    i=0
    for item in "${SW[@]}"; do
        hex="${item%%|*}"; lab="${item##*|}"
        x=$(( CX+pad+i*(size+gap) ))
        SWDRAW="$SWDRAW -fill '$hex' -draw 'roundrectangle $x,$sy $((x+size)),$((sy+size)) 12,12'"
        LABELS="$LABELS -fill '$LABELCOL' -annotate +$((x))+$((sy+size+26)) '$lab'"
        i=$((i+1))
    done

    eval magick "$TMP" \
        -fill "'rgba(33,30,30,0.82)'" -draw "'$DRAW'" \
        -fill "'$TITLECOL'" $FONTBOLD -pointsize 40 -annotate +$((CX+pad))+$((CY+50)) "'$NAME'" \
        -fill "'#9A988F'" $FONT -pointsize 18 -annotate +$((CX+pad+2))+$((CY+76)) "'KDE Plasma Global Theme'" \
        $SWDRAW \
        $FONT -pointsize 15 $LABELS \
        "'$OUT'"

    rm -f "$TMP"
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
