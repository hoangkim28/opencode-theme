#!/usr/bin/env bash
# Install the "OpenCode" KDE Plasma Global Themes (dark + light) + terminal themes.
# Re-runnable. Backs up nothing it overwrites (files are replaced wholesale).
# Usage: ./install.sh [dark|light|noapply]   (default: dark)
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DATA="${XDG_DATA_HOME:-$HOME/.local/share}"
CONF="${XDG_CONFIG_HOME:-$HOME/.config}"
MODE="${1:-dark}"
RELEASE_VERSION="$(tr -d '[:space:]' < "$HERE/VERSION")"
case "$MODE" in
    dark|light|noapply) ;;
    *)
        echo "Usage: $0 [dark|light|noapply]" >&2
        exit 2
        ;;
esac

echo "==> Installing OpenCode themes (mode: $MODE)"

# 1. Plasma color schemes (both variants)
mkdir -p "$DATA/color-schemes"
cp "$HERE/colors/OpenCodeDark.colors"  "$DATA/color-schemes/"
cp "$HERE/colors/OpenCodeLight.colors" "$DATA/color-schemes/"

# 2. Look-and-Feel (Global Theme) packages (both variants)
mkdir -p "$DATA/plasma/look-and-feel"
for pkg in com.kim.opencode-dark com.kim.opencode-light; do
    rm -rf "$DATA/plasma/look-and-feel/$pkg"
    cp -r "$HERE/lookandfeel/$pkg" "$DATA/plasma/look-and-feel/"
done

# 2b. Plasma desktop themes (warm panel + widget colors; both variants)
mkdir -p "$DATA/plasma/desktoptheme"
for dt in opencode-dark opencode-light; do
    rm -rf "$DATA/plasma/desktoptheme/$dt"
    cp -r "$HERE/desktoptheme/$dt" "$DATA/plasma/desktoptheme/"
done

# 3. Wallpaper package (dual dark/light variant — follows the color scheme)
mkdir -p "$DATA/wallpapers"
rm -rf "$DATA/wallpapers/OpenCode"
cp -r "$HERE/wallpaper/OpenCode" "$DATA/wallpapers/OpenCode"

# 4. Konsole profiles + color schemes
mkdir -p "$DATA/konsole"
cp "$HERE/konsole/OpenCodeDark.colorscheme"  "$HERE/konsole/OpenCodeDark.profile" \
   "$HERE/konsole/OpenCodeLight.colorscheme" "$HERE/konsole/OpenCodeLight.profile" "$DATA/konsole/"

# 5. Alacritty colors (importable files; does not overwrite your config)
mkdir -p "$CONF/alacritty"
cp "$HERE/alacritty/opencode-dark.toml" "$HERE/alacritty/opencode-light.toml" "$CONF/alacritty/"
echo "    alacritty: add  import = [\"~/.config/alacritty/opencode-dark.toml\"]  (or ...-light.toml)  under [general]"

# 6. Boot splash (KSplash theme with the OpenCode wordmark)
mkdir -p "$DATA/plasma/look-and-feel"
rm -rf "$DATA/plasma/look-and-feel/com.kim.opencode-splash"
cp -r "$HERE/splash/com.kim.opencode-splash" "$DATA/plasma/look-and-feel/"

# 7. Terminal themes (ghostty / kitty / wezterm importable files)
mkdir -p "$CONF/ghostty/themes"
cp "$HERE/terminals/ghostty/opencode-dark" "$HERE/terminals/ghostty/opencode-light" "$CONF/ghostty/themes/"
mkdir -p "$CONF/kitty"
cp "$HERE/terminals/kitty/opencode-dark.conf" "$HERE/terminals/kitty/opencode-light.conf" "$CONF/kitty/"
mkdir -p "$CONF/wezterm"
cp "$HERE/terminals/wezterm/opencode-dark.lua" "$HERE/terminals/wezterm/opencode-light.lua" "$CONF/wezterm/"
echo "    ghostty:  themes are at ~/.config/ghostty/themes/ (theme = opencode-dark)"
echo "    kitty:    include ~/.config/kitty/opencode-dark.conf in kitty.conf"
echo "    wezterm:  dofile('~/.config/wezterm/opencode-dark.lua').colors in wezterm.lua"
echo "    starship: cp starship/opencode-dark.toml ~/.config/starship.toml"

# 8. VS Code theme extension (packaged .vsix)
if [ -f "$HERE/vscode/opencode-theme-$RELEASE_VERSION.vsix" ]; then
    cp "$HERE/vscode/opencode-theme-$RELEASE_VERSION.vsix" "$CONF/opencode-theme.vsix"
    echo "    vscode:   code --install-extension $CONF/opencode-theme.vsix"
fi

if [ "$MODE" = "noapply" ]; then
    echo "==> Files installed without applying. Pick 'OpenCode Dark' or 'OpenCode Light' in System Settings > Colors & Themes > Global Theme."
    exit 0
fi

# apply the chosen variant (dark or light)
if [ "$MODE" = "light" ]; then
    PKG="com.kim.opencode-light"; SCHEME="OpenCodeLight"; ACCENT="214,140,39"
    PROFILE="OpenCodeLight.profile"; DESKTHEME="opencode-light"
else
    PKG="com.kim.opencode-dark"; SCHEME="OpenCodeDark"; ACCENT="250,178,131"
    PROFILE="OpenCodeDark.profile"; DESKTHEME="opencode-dark"
fi

APPLY_FAILURES=0
run_apply() {
    local label="$1"
    shift
    if ! "$@"; then
        echo "ERROR: failed to apply $label" >&2
        APPLY_FAILURES=$((APPLY_FAILURES + 1))
    fi
}

run_core_apply() {
    local label="$1" command_name="$2"
    shift 2
    if command -v "$command_name" >/dev/null 2>&1; then
        run_apply "$label" "$command_name" "$@"
    else
        echo "WARNING: $command_name is unavailable; $label was installed but not applied" >&2
    fi
}

echo "==> Applying OpenCode ${MODE^} to the current session"
run_core_apply "global theme" plasma-apply-lookandfeel -a "$PKG"
run_core_apply "color scheme" plasma-apply-colorscheme "$SCHEME"
run_core_apply "desktop theme" plasma-apply-desktoptheme "$DESKTHEME"
run_core_apply "wallpaper" plasma-apply-wallpaperimage "$DATA/wallpapers/OpenCode/"

if command -v kwriteconfig6 >/dev/null 2>&1; then
    run_apply "accent color" kwriteconfig6 --file kdeglobals --group General --key AccentColor "$ACCENT"
    run_apply "Konsole profile" kwriteconfig6 --file konsolerc --group "Desktop Entry" --key DefaultProfile "$PROFILE"
    run_apply "splash theme" kwriteconfig6 --file ksplashrc --group KSplash --key Theme "com.kim.opencode-splash"
    run_apply "wallpaper override reset" kwriteconfig6 --file plasmarc --group Wallpapers --key usersWallpapers ""
else
    echo "WARNING: kwriteconfig6 is unavailable; session preferences were not updated" >&2
fi

if command -v qdbus >/dev/null 2>&1; then
    if ! qdbus org.kde.KWin /KWin org.kde.KWin.reconfigure; then
        echo "WARNING: KWin reconfigure request failed" >&2
    fi
elif command -v qdbus-qt6 >/dev/null 2>&1; then
    if ! qdbus-qt6 org.kde.KWin /KWin org.kde.KWin.reconfigure; then
        echo "WARNING: KWin reconfigure request failed" >&2
    fi
else
    echo "WARNING: qdbus is unavailable; KWin was not reconfigured" >&2
fi

echo "==> Done. Pick 'OpenCode Dark' or 'OpenCode Light' in System Settings > Colors & Themes > Global Theme."
if ((APPLY_FAILURES > 0)); then
    echo "ERROR: $APPLY_FAILURES apply operation(s) failed; installed files were kept" >&2
    exit 1
fi
