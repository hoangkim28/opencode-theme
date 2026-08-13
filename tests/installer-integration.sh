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

# --- VS Code extension auto-install (install.sh step 8) ---
VERSION="$(tr -d '[:space:]' < "$ROOT/VERSION")"
VSIX_PATH="$ROOT/dist/opencode-theme-$VERSION.vsix"
VSIX_SAVED="$TEST_TMP/vsix-saved"

# E. No .vsix anywhere -> hint only, no copy, install still exits 0
if [ -f "$VSIX_PATH" ]; then
    mv "$VSIX_PATH" "$VSIX_SAVED"
fi
NOTFOUND_LOG="$TEST_TMP/notfound.log"
XDG_DATA_HOME="$DATA" XDG_CONFIG_HOME="$CONFIG" ./install.sh noapply >"$NOTFOUND_LOG" 2>&1
grep -q "VSIX is generated at release build" "$NOTFOUND_LOG"
test ! -e "$CONFIG/opencode-theme.vsix"
if [ -f "$VSIX_SAVED" ]; then
    mv "$VSIX_SAVED" "$VSIX_PATH"
fi

# Stub .vsix in dist/ (gitignored) so install.sh finds it via the dist fallback
REAL_VSIX="$TEST_TMP/real-vsix"
if [ -f "$VSIX_PATH" ]; then
    mv "$VSIX_PATH" "$REAL_VSIX"
fi
mkdir -p "$ROOT/dist"
printf 'stub vsix\n' > "$VSIX_PATH"
cleanup_vsix() {
    rm -f -- "$VSIX_PATH"
    if [ -f "$REAL_VSIX" ]; then
        mv "$REAL_VSIX" "$VSIX_PATH"
    fi
}
trap 'cleanup_vsix; rm -rf -- "$TEST_TMP"' EXIT

FAKE_BIN="$TEST_TMP/fakebin"
CODE_LOG="$TEST_TMP/code-args.log"
mkdir -p "$FAKE_BIN"
for tool in env bash tr mkdir cp rm dirname; do
    ln -sf "$(command -v "$tool")" "$FAKE_BIN/$tool"
done

make_fake_code() {
    local status="$1"
    cat > "$FAKE_BIN/code" <<EOF
#!/usr/bin/env bash
printf '%s\\n' "\$@" >> "$CODE_LOG"
exit $status
EOF
    chmod +x "$FAKE_BIN/code"
}

# A. noapply: copies the vsix but does not auto-install
make_fake_code 0
rm -f -- "$CODE_LOG"
XDG_DATA_HOME="$DATA" XDG_CONFIG_HOME="$CONFIG" PATH="$FAKE_BIN:$PATH" ./install.sh noapply >/dev/null
test -f "$CONFIG/opencode-theme.vsix"
test ! -s "$CODE_LOG"

# B. dark: auto-installs via `code` when present
make_fake_code 0
rm -f -- "$CODE_LOG"
XDG_DATA_HOME="$DATA" XDG_CONFIG_HOME="$CONFIG" PATH="$FAKE_BIN" ./install.sh dark >/dev/null 2>&1
test "$(sed -n 1p "$CODE_LOG")" = "--install-extension"
test "$(sed -n 2p "$CODE_LOG")" = "$CONFIG/opencode-theme.vsix"
test "$(wc -l < "$CODE_LOG")" -eq 2
test -f "$CONFIG/opencode-theme.vsix"

# C. dark: a failing `code` is reported but the vsix is still copied
make_fake_code 42
rm -f -- "$CODE_LOG"
FAIL_LOG="$TEST_TMP/fail.log"
if XDG_DATA_HOME="$DATA" XDG_CONFIG_HOME="$CONFIG" PATH="$FAKE_BIN" ./install.sh dark >"$FAIL_LOG" 2>&1; then
    echo "install.sh unexpectedly succeeded with a failing code CLI" >&2
    exit 1
fi
grep -q "failed to apply" "$FAIL_LOG"
test -f "$CONFIG/opencode-theme.vsix"

# D. dark: no code/codium available -> warning, still exits 0
rm -f -- "$FAKE_BIN/code" "$CODE_LOG"
WARN_LOG="$TEST_TMP/warn.log"
XDG_DATA_HOME="$DATA" XDG_CONFIG_HOME="$CONFIG" PATH="$FAKE_BIN" ./install.sh dark >"$WARN_LOG" 2>&1
grep -q "neither code nor codium" "$WARN_LOG"
test -f "$CONFIG/opencode-theme.vsix"

cleanup_vsix

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
