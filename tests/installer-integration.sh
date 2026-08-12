#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_TMP="$(mktemp -d)"
trap 'rm -rf -- "$TEST_TMP"' EXIT

cd "$ROOT"

INVALID_DATA="$TEST_TMP/invalid-data"
INVALID_CONFIG="$TEST_TMP/invalid-config"
if XDG_DATA_HOME="$INVALID_DATA" XDG_CONFIG_HOME="$INVALID_CONFIG" ./install.sh typo >/dev/null 2>&1; then
    echo "invalid mode unexpectedly succeeded" >&2
    exit 1
fi
test ! -e "$INVALID_DATA"
test ! -e "$INVALID_CONFIG"

DATA="$TEST_TMP/data"
CONFIG="$TEST_TMP/config"
XDG_DATA_HOME="$DATA" XDG_CONFIG_HOME="$CONFIG" ./install.sh noapply >/dev/null
test -f "$DATA/color-schemes/OpenCodeDark.colors"
test -f "$CONFIG/ghostty/themes/opencode-dark"
XDG_DATA_HOME="$DATA" XDG_CONFIG_HOME="$CONFIG" ./uninstall.sh >/dev/null
test "$(find "$DATA" "$CONFIG" -type f | wc -l)" -eq 0

if command -v kpackagetool6 >/dev/null 2>&1; then
    KDE_DATA="$TEST_TMP/kde-data"
    mkdir -p "$KDE_DATA"
    XDG_DATA_HOME="$KDE_DATA" kpackagetool6 --type Plasma/LookAndFeel \
        --install lookandfeel/com.kim.opencode-dark >/dev/null
    XDG_DATA_HOME="$KDE_DATA" kpackagetool6 --type Wallpaper/Images \
        --install wallpaper/OpenCode >/dev/null

    WRONG_DATA="$TEST_TMP/wrong-type-data"
    mkdir -p "$WRONG_DATA"
    if XDG_DATA_HOME="$WRONG_DATA" kpackagetool6 --type Plasma/Wallpaper \
        --install wallpaper/OpenCode >/dev/null 2>&1; then
        echo "wallpaper unexpectedly accepted as Plasma/Wallpaper" >&2
        exit 1
    fi
fi

echo "Installer integration tests passed"
