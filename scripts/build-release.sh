#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION="$(tr -d '[:space:]' < "$ROOT/VERSION")"
DIST="$ROOT/dist"
BACKUP="$ROOT/.dist.previous.$$"
BUILD_ROOT="$(mktemp -d "$ROOT/.dist.next.XXXXXX")"
BUILD_TMP="$BUILD_ROOT/work"
OLD_MOVED=false
PUBLISHING=false
PUBLISHED=false

cleanup() {
    local status=$?
    trap - EXIT HUP INT TERM
    if [[ "$PUBLISHED" != true && "$PUBLISHING" == true ]]; then
        if [[ -e "$DIST" ]]; then
            rm -rf -- "$DIST"
        fi
        if [[ "$OLD_MOVED" == true && -e "$BACKUP" ]] && ! mv "$BACKUP" "$DIST"; then
            echo "ERROR: release rollback failed; previous output remains at $BACKUP" >&2
        fi
    fi
    rm -rf -- "$BUILD_ROOT"
    exit "$status"
}
trap cleanup EXIT
trap 'exit 129' HUP
trap 'exit 130' INT
trap 'exit 143' TERM

STAGE="$BUILD_TMP/opencode-theme-$VERSION"
OUT="$BUILD_TMP/out"
mkdir -p "$STAGE" "$OUT"

for command_name in node tar gzip zip unzip sha256sum cmp find sort awk; do
    if ! command -v "$command_name" >/dev/null 2>&1; then
        echo "ERROR: required command not found: $command_name" >&2
        exit 1
    fi
done

node "$ROOT/scripts/validate-theme.mjs"

copy_tree() {
    local source="$1" destination="$2"
    mkdir -p "$destination"
    cp -a "$source/." "$destination/"
}

for directory in \
    alacritty assets colors desktoptheme konsole lookandfeel splash starship terminals vscode wallpaper; do
    copy_tree "$ROOT/$directory" "$STAGE/$directory"
done

mkdir -p "$STAGE/scripts"
cp "$ROOT/install.sh" "$ROOT/uninstall.sh" "$STAGE/"
cp "$ROOT/scripts/generate-preview.sh" "$ROOT/scripts/generate-wallpaper.sh" \
    "$ROOT/scripts/validate-theme.mjs" "$STAGE/scripts/"
cp "$ROOT/README.md" "$ROOT/LICENSE" "$ROOT/VERSION" "$STAGE/"
if [[ -f "$ROOT/THIRD_PARTY_NOTICES.md" ]]; then
    cp "$ROOT/THIRD_PARTY_NOTICES.md" "$STAGE/"
fi

for variant in dark light; do
    package="$STAGE/lookandfeel/com.kim.opencode-$variant"
    copy_tree "$ROOT/wallpaper/OpenCode" "$package/contents/wallpapers/OpenCode"
done

SOURCE_SYMLINK="$(find "$STAGE" -type l -print -quit)"
if [[ -n "$SOURCE_SYMLINK" ]]; then
    echo "ERROR: release source contains a symlink: $SOURCE_SYMLINK" >&2
    exit 1
fi

VSIX_STAGE="$BUILD_TMP/vsix"
mkdir -p "$VSIX_STAGE/extension/themes"
cp "$ROOT/vscode/extension.vsixmanifest" "$VSIX_STAGE/"
cp "$ROOT/vscode/[Content_Types].xml" "$VSIX_STAGE/"
cp "$ROOT/vscode/package.json" "$VSIX_STAGE/extension/"
cp "$ROOT/vscode/themes/"*.json "$VSIX_STAGE/extension/themes/"
find "$VSIX_STAGE" -exec touch -t 198001010000 {} +
(
    cd "$VSIX_STAGE"
    find . -type f -printf '%P\n' | LC_ALL=C sort | \
        zip -X -q "$OUT/opencode-theme-$VERSION.vsix" -@
)
cp "$OUT/opencode-theme-$VERSION.vsix" "$STAGE/vscode/"

create_tarball() {
    local parent="$1" entry="$2" output="$3"
    tar --sort=name --mtime='@0' --owner=0 --group=0 --numeric-owner \
        -C "$parent" -cf - "$entry" | gzip -n > "$output"
}

create_tarball "$STAGE/lookandfeel" "com.kim.opencode-dark" \
    "$OUT/opencode-lookandfeel-dark-$VERSION.tar.gz"
create_tarball "$STAGE/lookandfeel" "com.kim.opencode-light" \
    "$OUT/opencode-lookandfeel-light-$VERSION.tar.gz"
create_tarball "$STAGE/wallpaper" "OpenCode" \
    "$OUT/opencode-wallpaper-$VERSION.tar.gz"
create_tarball "$BUILD_TMP" "opencode-theme-$VERSION" \
    "$OUT/opencode-theme-$VERSION.tar.gz"

VSIX_CHECK="$BUILD_TMP/vsix-check"
mkdir -p "$VSIX_CHECK"
unzip -q "$OUT/opencode-theme-$VERSION.vsix" -d "$VSIX_CHECK"
cmp "$ROOT/vscode/package.json" "$VSIX_CHECK/extension/package.json"
cmp "$ROOT/vscode/themes/opencode-dark.json" "$VSIX_CHECK/extension/themes/opencode-dark.json"
cmp "$ROOT/vscode/themes/opencode-light.json" "$VSIX_CHECK/extension/themes/opencode-light.json"

(
    cd "$OUT"
    sha256sum opencode-*.tar.gz opencode-theme-*.vsix > SHA256SUMS
    sha256sum -c SHA256SUMS >/dev/null
)

for archive in "$OUT"/*.tar.gz; do
    if tar -tvf "$archive" | awk '$1 ~ /^l/ { found=1 } END { exit !found }'; then
        echo "ERROR: release archive contains a symlink: $archive" >&2
        exit 1
    fi
done

FULL_CHECK="$BUILD_TMP/full-check"
mkdir -p "$FULL_CHECK"
tar -xzf "$OUT/opencode-theme-$VERSION.tar.gz" -C "$FULL_CHECK"
BUNDLE_CHECK="$FULL_CHECK/opencode-theme-$VERSION"
for required_path in \
    desktoptheme/opencode-dark/metadata.json \
    desktoptheme/opencode-light/metadata.json \
    wallpaper/OpenCode/metadata.json \
    splash/com.kim.opencode-splash/contents/splash/images/wordmark-light.png \
    terminals/ghostty/opencode-dark \
    vscode/themes/opencode-dark.json \
    "vscode/opencode-theme-$VERSION.vsix" \
    install.sh uninstall.sh THIRD_PARTY_NOTICES.md; do
    if [[ ! -e "$BUNDLE_CHECK/$required_path" ]]; then
        echo "ERROR: complete release is missing $required_path" >&2
        exit 1
    fi
done

if command -v kpackagetool6 >/dev/null 2>&1; then
    KDE_DATA="$BUILD_TMP/kde-data"
    mkdir -p "$KDE_DATA"
    XDG_DATA_HOME="$KDE_DATA" kpackagetool6 --type Plasma/LookAndFeel \
        --install "$STAGE/lookandfeel/com.kim.opencode-dark" >/dev/null
    XDG_DATA_HOME="$KDE_DATA" kpackagetool6 --type Plasma/LookAndFeel \
        --install "$STAGE/lookandfeel/com.kim.opencode-light" >/dev/null
    XDG_DATA_HOME="$KDE_DATA" kpackagetool6 --type Plasma/LookAndFeel \
        --install "$STAGE/splash/com.kim.opencode-splash" >/dev/null
    XDG_DATA_HOME="$KDE_DATA" kpackagetool6 --type Wallpaper/Images \
        --install "$STAGE/wallpaper/OpenCode" >/dev/null
else
    echo "WARNING: kpackagetool6 unavailable; skipped KDE package smoke checks" >&2
fi

if [[ -e "$BACKUP" ]]; then
    echo "ERROR: unexpected release backup already exists: $BACKUP" >&2
    exit 1
fi
PUBLISHING=true
if [[ -e "$DIST" ]]; then
    mv "$DIST" "$BACKUP"
    OLD_MOVED=true
fi
if [[ "${OPENCODE_BUILD_FAILPOINT:-}" == "after-backup" ]]; then
    echo "ERROR: requested test failpoint after backup" >&2
    exit 99
fi
if mv "$OUT" "$DIST"; then
    PUBLISHED=true
    [[ ! -e "$BACKUP" ]] || rm -rf -- "$BACKUP"
else
    [[ ! -e "$BACKUP" ]] || mv "$BACKUP" "$DIST"
    echo "ERROR: unable to publish release output" >&2
    exit 1
fi

echo "Release $VERSION written to $DIST"
