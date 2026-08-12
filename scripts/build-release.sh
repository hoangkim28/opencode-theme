#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION="$(tr -d '[:space:]' < "$ROOT/VERSION")"
BUILD_TMP="$(mktemp -d)"
trap 'rm -rf -- "$BUILD_TMP"' EXIT
STAGE="$BUILD_TMP/opencode-theme-$VERSION"
OUT="$BUILD_TMP/out"
mkdir -p "$STAGE" "$OUT"

for command_name in node tar gzip zip unzip sha256sum cmp find sort; do
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

DIST="$ROOT/dist"
BACKUP="$ROOT/.dist-backup-$$"
if [[ -e "$BACKUP" ]]; then
    echo "ERROR: unexpected release backup already exists: $BACKUP" >&2
    exit 1
fi
if [[ -e "$DIST" ]]; then
    mv "$DIST" "$BACKUP"
fi
if mv "$OUT" "$DIST"; then
    [[ ! -e "$BACKUP" ]] || rm -rf -- "$BACKUP"
else
    [[ ! -e "$BACKUP" ]] || mv "$BACKUP" "$DIST"
    echo "ERROR: unable to publish release output" >&2
    exit 1
fi

echo "Release $VERSION written to $DIST"
