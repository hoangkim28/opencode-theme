#!/usr/bin/env bash
# Remove the "OpenCode" theme files (both dark and light). Does not change your
# active theme; switch to another Global Theme first in System Settings.
set -euo pipefail
DATA="${XDG_DATA_HOME:-$HOME/.local/share}"
CONF="${XDG_CONFIG_HOME:-$HOME/.config}"

rm -rf "$DATA/plasma/look-and-feel/com.kim.opencode-dark"
rm -rf "$DATA/plasma/look-and-feel/com.kim.opencode-light"
rm -rf "$DATA/plasma/look-and-feel/com.kim.opencode-splash"
rm -rf "$DATA/plasma/desktoptheme/opencode-dark"
rm -rf "$DATA/plasma/desktoptheme/opencode-light"
rm -rf "$DATA/wallpapers/OpenCode"
rm -f  "$DATA/color-schemes/OpenCodeDark.colors"
rm -f  "$DATA/color-schemes/OpenCodeLight.colors"
rm -f  "$DATA/konsole/OpenCodeDark.colorscheme"
rm -f  "$DATA/konsole/OpenCodeDark.profile"
rm -f  "$DATA/konsole/OpenCodeLight.colorscheme"
rm -f  "$DATA/konsole/OpenCodeLight.profile"
rm -f  "$CONF/alacritty/opencode-dark.toml"
rm -f  "$CONF/alacritty/opencode-light.toml"
rm -f  "$CONF/ghostty/themes/opencode-dark"
rm -f  "$CONF/ghostty/themes/opencode-light"
rm -f  "$CONF/kitty/opencode-dark.conf"
rm -f  "$CONF/kitty/opencode-light.conf"
rm -f  "$CONF/wezterm/opencode-dark.lua"
rm -f  "$CONF/wezterm/opencode-light.lua"
rm -f  "$CONF/opencode-theme.vsix"

echo "Removed OpenCode theme files."
echo "If it was your active theme, pick a different Global Theme in System Settings."
