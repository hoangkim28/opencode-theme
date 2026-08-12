#!/usr/bin/env bash
# Interactive real-screenshot capture for the OpenCode themes (dark + light).
# Run from inside a KDE Plasma session. Usage: ./capture-screenshots.sh [dark|light|all]
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(dirname "$HERE")"
MODE="${1:-all}"

case "${XDG_CURRENT_DESKTOP:-}" in
    *KDE*) ;;
    *)
        echo "ERROR: must run inside a KDE Plasma session (XDG_CURRENT_DESKTOP='${XDG_CURRENT_DESKTOP:-}')" >&2
        exit 1
        ;;
esac

for tool in spectacle magick; do
    if ! command -v "$tool" >/dev/null 2>&1; then
        echo "ERROR: required tool not found: $tool" >&2
        exit 1
    fi
done

notify() {
    command -v kdialog >/dev/null 2>&1 && kdialog --passivepopup "$1" 5 2>/dev/null || true
}

shoot() {
    local out="$1" desc="$2"
    echo ">>> $desc"
    notify "$desc"
    read -r -p "Press Enter to capture (Ctrl+C to abort)... " _
    spectacle --background --nonotify --fullscreen --output "$out"
    sleep 1
}

capture_variant() {
    local variant="$1"
    local outdir="$ROOT/screenshots/$variant"
    mkdir -p "$outdir"
    echo "==> Applying OpenCode $variant to the live session"
    "$ROOT/install.sh" "$variant"
    sleep 3

    shoot "$outdir/.raw-desktop.png" "Close ALL windows so only the desktop and panel are visible, then press Enter."
    magick "$outdir/.raw-desktop.png" -resize '1280x' "$outdir/desktop.png"

    shoot "$outdir/.raw-konsole.png" "Open Konsole with the OpenCode $variant profile and a starship prompt visible, then press Enter."
    magick "$outdir/.raw-konsole.png" -resize '1280x' "$outdir/konsole.png"

    shoot "$outdir/.raw-vscode.png" "Open VS Code (OpenCode theme active) with a code file visible, then press Enter."
    magick "$outdir/.raw-vscode.png" -resize '1280x' "$outdir/vscode.png"

    read -r -p "Capture System Settings > Colors & Themes > Global Theme too? [y/N] " yes
    if [[ "${yes,,}" == "y" ]]; then
        shoot "$outdir/.raw-settings.png" "Open System Settings > Colors & Themes > Global Theme, then press Enter."
        magick "$outdir/.raw-settings.png" -resize '1280x' "$outdir/system-settings.png"
    fi

    rm -f "$outdir"/.raw-*.png
}

if [[ "$MODE" == "all" || "$MODE" == "dark" ]]; then
    capture_variant dark
fi
if [[ "$MODE" == "all" || "$MODE" == "light" ]]; then
    capture_variant light
fi

if [[ "$MODE" == "all" || "$MODE" == "light" ]]; then
    echo "==> Restoring the dark theme"
    "$ROOT/install.sh"
fi

echo "==> Done. Screenshots in $ROOT/screenshots/{dark,light}/"
