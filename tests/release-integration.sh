#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION="$(tr -d '[:space:]' < "$ROOT/VERSION")"
TEST_TMP="$(mktemp -d)"
SYMLINK_TEST="$ROOT/terminals/.release-test-link"
cleanup() {
    rm -f -- "$SYMLINK_TEST"
    rm -rf -- "$TEST_TMP"
}
trap cleanup EXIT

cd "$ROOT"

test "$(find wallpaper -type f -name '3840x2160.png' | wc -l)" -eq 2
test "$(find lookandfeel -type f -name '3840x2160.png' | wc -l)" -eq 0
if compgen -G 'vscode/*.vsix' >/dev/null; then
    echo "tracked/source VSIX must not exist" >&2
    exit 1
fi

scripts/build-release.sh >/dev/null
cp dist/SHA256SUMS "$TEST_TMP/first-sums"
touch dist/.preserve-on-failure

if OPENCODE_BUILD_FAILPOINT=after-backup scripts/build-release.sh >/dev/null 2>&1; then
    echo "release failpoint unexpectedly succeeded" >&2
    exit 1
fi
test -f dist/.preserve-on-failure

ln -s /etc/passwd "$SYMLINK_TEST"
if scripts/build-release.sh >/dev/null 2>&1; then
    echo "release build unexpectedly accepted a source symlink" >&2
    exit 1
fi
test -f dist/.preserve-on-failure
rm -f -- "$SYMLINK_TEST" dist/.preserve-on-failure

scripts/build-release.sh >/dev/null
cmp "$TEST_TMP/first-sums" dist/SHA256SUMS

artifacts=(
    "opencode-lookandfeel-dark-$VERSION.tar.gz"
    "opencode-lookandfeel-light-$VERSION.tar.gz"
    "opencode-wallpaper-$VERSION.tar.gz"
    "opencode-theme-$VERSION.tar.gz"
    "opencode-theme-$VERSION.vsix"
)
for artifact in "${artifacts[@]}" SHA256SUMS; do
    test -f "dist/$artifact"
done

(
    cd dist
    sha256sum -c SHA256SUMS >/dev/null
)

for archive in dist/*.tar.gz; do
    if tar -tvf "$archive" | awk '$1 ~ /^l/ { found=1 } END { exit !found }'; then
        echo "symlink found in $archive" >&2
        exit 1
    fi
done

FULL="$TEST_TMP/full"
mkdir -p "$FULL"
tar -xzf "dist/opencode-theme-$VERSION.tar.gz" -C "$FULL"
BUNDLE="$FULL/opencode-theme-$VERSION"
test -d "$BUNDLE/desktoptheme/opencode-dark"
test -d "$BUNDLE/desktoptheme/opencode-light"
test -f "$BUNDLE/wallpaper/OpenCode/contents/images/3840x2160.png"
test -f "$BUNDLE/splash/com.kim.opencode-splash/contents/splash/images/wordmark-light.png"
test -f "$BUNDLE/terminals/ghostty/opencode-dark"
test -x "$BUNDLE/install.sh"
test -x "$BUNDLE/uninstall.sh"
test -f "$BUNDLE/vscode/themes/opencode-dark.json"
test -f "$BUNDLE/vscode/opencode-theme-$VERSION.vsix"

VSIX="$TEST_TMP/vsix"
mkdir -p "$VSIX"
unzip -q "dist/opencode-theme-$VERSION.vsix" -d "$VSIX"
cmp vscode/package.json "$VSIX/extension/package.json"
cmp vscode/themes/opencode-dark.json "$VSIX/extension/themes/opencode-dark.json"
cmp vscode/themes/opencode-light.json "$VSIX/extension/themes/opencode-light.json"

if command -v kpackagetool6 >/dev/null 2>&1; then
    KDE="$TEST_TMP/kde"
    mkdir -p "$KDE/dark" "$KDE/light" "$KDE/wallpaper" "$KDE/data"
    tar -xzf "dist/opencode-lookandfeel-dark-$VERSION.tar.gz" -C "$KDE/dark"
    tar -xzf "dist/opencode-lookandfeel-light-$VERSION.tar.gz" -C "$KDE/light"
    tar -xzf "dist/opencode-wallpaper-$VERSION.tar.gz" -C "$KDE/wallpaper"
    XDG_DATA_HOME="$KDE/data" kpackagetool6 --type Plasma/LookAndFeel \
        --install "$KDE/dark/com.kim.opencode-dark" >/dev/null
    XDG_DATA_HOME="$KDE/data" kpackagetool6 --type Plasma/LookAndFeel \
        --install "$KDE/light/com.kim.opencode-light" >/dev/null
    XDG_DATA_HOME="$KDE/data" kpackagetool6 --type Wallpaper/Images \
        --install "$KDE/wallpaper/OpenCode" >/dev/null
fi

echo "Release integration tests passed"
