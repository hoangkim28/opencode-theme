#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_TMP="$(mktemp -d)"
trap 'rm -rf -- "$TEST_TMP"' EXIT

expect_failure() {
    if "$@" >/dev/null 2>&1; then
        echo "expected failure: $*" >&2
        exit 1
    fi
}

cd "$ROOT"

expect_failure scripts/generate-preview.sh "$TEST_TMP/preview" 640X360
expect_failure scripts/generate-wallpaper.sh "$TEST_TMP/wallpaper" 0x360
expect_failure scripts/capture-screenshots.sh invalid

INJECTION_MARKER="$TEST_TMP/injected"
ODD_OUT="$TEST_TMP/out'; touch '$INJECTION_MARKER'; echo '"
scripts/generate-preview.sh "$ODD_OUT" 640x360 >/dev/null
test -f "$ODD_OUT/preview-dark.png"
test -f "$ODD_OUT/preview-light.png"
test ! -e "$INJECTION_MARKER"

WALLPAPER_OUT="$TEST_TMP/wallpaper"
mkdir -p \
    "$WALLPAPER_OUT/OpenCode/contents/images" \
    "$WALLPAPER_OUT/OpenCode/contents/images_dark"
scripts/generate-wallpaper.sh "$WALLPAPER_OUT" 320x180 >/dev/null

for variant in images images_dark; do
    image="$WALLPAPER_OUT/OpenCode/contents/$variant/320x180.png"
    test -f "$image"
    test "$(magick identify -format '%wx%h' "$image")" = "320x180"
done

echo "Generator integration tests passed"
