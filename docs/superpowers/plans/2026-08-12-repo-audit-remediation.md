# Repository Audit Remediation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Resolve every audited correctness, accessibility, packaging, security, documentation, and release-engineering finding while preserving the OpenCode theme identity.

**Architecture:** Keep one canonical source for large wallpaper assets and build complete artifacts in an isolated release staging directory. Use dependency-free Node validation plus Bash integration tests to drive palette, installer, generator, KDE package, splash, VSIX, and documentation changes.

**Tech Stack:** Bash 5, Node.js built-in test runner, JSON/INI/TOML/Lua/QML configuration, ImageMagick 7, KDE Frameworks 6 `kpackagetool6`, `tar`, `zip`, GitHub Actions.

## Global Constraints

- Preserve the warm neutral OpenCode identity; this is remediation, not redesign.
- Normal-size text pairs covered by validation must meet WCAG AA contrast of at least 4.5:1.
- Keep `#D68C27` as the light brand accent for non-text decoration; use accessible semantic text colors separately.
- Keep one canonical wallpaper package at `wallpaper/OpenCode`; release staging materializes package copies.
- Do not add SDDM, GTK, Kvantum, icon, cursor, or panel-layout themes.
- Add no npm or runtime dependencies; validators use Node standard library only.
- Build output is created under a temporary directory and replaces `dist/` only after validation succeeds.
- The complete bundle is self-contained; individual LookAndFeel archives are documented as partial component artifacts.

---

## File Map

- `VERSION`: canonical component and release version.
- `scripts/validate-theme.mjs`: color grammar, contrast, palette, version, and source-integrity validator.
- `tests/theme-validator.test.mjs`: unit and source-level regression tests for the validator and palette.
- `tests/generators-integration.sh`: adversarial and smoke tests for image/screenshot scripts.
- `tests/installer-integration.sh`: isolated mode validation and install/uninstall tests.
- `tests/splash.test.mjs`: static adaptive-splash contract tests.
- `tests/release-integration.sh`: release contents, VSIX parity, KDE validation, checksums, and source-deduplication tests.
- `scripts/test.sh`: one local/CI test entry point.
- `scripts/build-release.sh`: atomic release staging and artifact builder.
- `.github/workflows/ci.yml`: required Debian/KDE validation on pushes and pull requests.
- `THIRD_PARTY_NOTICES.md`: upstream OpenCode wordmark provenance and MIT notice.

### Task 1: Accessible Palette, Version Contract, and Theme Validator

**Files:**
- Create: `VERSION`
- Create: `scripts/validate-theme.mjs`
- Create: `tests/theme-validator.test.mjs`
- Modify: `vscode/themes/opencode-dark.json:21`
- Modify: `vscode/themes/opencode-light.json:5-469`
- Modify: `colors/OpenCodeLight.colors:21-149`
- Modify: `desktoptheme/opencode-light/colors:21-149`
- Modify: `lookandfeel/com.kim.opencode-light/contents/colorschemes/OpenCodeLight.colors:21-149`
- Modify: `konsole/OpenCodeLight.colorscheme:10-65`
- Modify: `alacritty/opencode-light.toml:13-39`
- Modify: `terminals/ghostty/opencode-dark:5-6`
- Modify: `terminals/ghostty/opencode-light:5-26`
- Modify: `terminals/kitty/opencode-light.conf:4-26`
- Modify: `terminals/wezterm/opencode-light.lua:7-33`
- Modify: `starship/opencode-light.toml:6-69`

**Interfaces:**
- Produces: `contrastRatio(foreground: string, background: string): number`.
- Produces: `assertContrast(label: string, foreground: string, background: string, minimum?: number): void`.
- Produces: `validateHex(value: string): boolean` for `#RRGGBB`, `RRGGBB`, or `0xRRGGBB`.
- Produces: CLI `node scripts/validate-theme.mjs`, returning zero only when all source contracts pass.
- Consumes: repository root inferred from `import.meta.url`; no current-working-directory assumption.

- [ ] **Step 1: Write validator tests that describe the accessible palette**

Create `tests/theme-validator.test.mjs` with Node's built-in test runner. Include these exact behavioral assertions:

```js
import assert from "node:assert/strict";
import { execFileSync } from "node:child_process";
import { test } from "node:test";
import { contrastRatio, validateHex } from "../scripts/validate-theme.mjs";

const editor = "#FBF9F8";
const lightSurface = "#F1ECEC";
const accessibleLight = [
  "#8A5200", // amber text
  "#7651B5", // purple
  "#2968C3", // blue
  "#257A3E", // green
  "#7A5B00", // yellow
  "#1E6E79", // cyan
  "#B52A30", // red
];

test("accessible light syntax colors meet AA", () => {
  for (const color of accessibleLight) {
    assert.ok(contrastRatio(color, editor) >= 4.5, color);
    assert.ok(contrastRatio(color, lightSurface) >= 4.5, color);
  }
});

test("Ghostty colors are six-digit hex", () => {
  assert.equal(validateHex("cfc ecd"), false);
  assert.equal(validateHex("CFCECD"), true);
});

test("repository theme validation passes", () => {
  execFileSync(process.execPath, ["scripts/validate-theme.mjs"], {
    cwd: new URL("..", import.meta.url),
    stdio: "pipe",
  });
});
```

- [ ] **Step 2: Run the tests to verify the red state**

Run: `node --test tests/theme-validator.test.mjs`

Expected: FAIL with `ERR_MODULE_NOT_FOUND` for `scripts/validate-theme.mjs`.

- [ ] **Step 3: Add the canonical version and minimal validator module**

Create `VERSION` containing exactly `1.0.0` plus a trailing newline. Implement the exported functions in `scripts/validate-theme.mjs`:

```js
export function validateHex(value) {
  return /^(?:#|0x)?[0-9a-f]{6}$/i.test(value);
}

function luminance(value) {
  const hex = value.replace(/^#/, "").slice(0, 6);
  const channels = [0, 2, 4].map((offset) =>
    Number.parseInt(hex.slice(offset, offset + 2), 16) / 255
  ).map((channel) => channel <= 0.04045
    ? channel / 12.92
    : ((channel + 0.055) / 1.055) ** 2.4);
  return 0.2126 * channels[0] + 0.7152 * channels[1] + 0.0722 * channels[2];
}

export function contrastRatio(foreground, background) {
  const a = luminance(foreground);
  const b = luminance(background);
  return (Math.max(a, b) + 0.05) / (Math.min(a, b) + 0.05);
}

export function assertContrast(label, foreground, background, minimum = 4.5) {
  const ratio = contrastRatio(foreground, background);
  if (ratio < minimum) {
    throw new Error(`${label}: ${ratio.toFixed(2)}:1 is below ${minimum}:1`);
  }
}
```

The CLI must read the two VS Code JSON files, direct-color terminal files, `VERSION`, and component metadata. Declare explicit foreground/background pairs rather than inferring backgrounds from key names. Exclude only documented inactive/disabled roles and transparent decoration colors.

- [ ] **Step 4: Update the source palettes and Ghostty typo**

Apply these role values consistently to every light terminal palette and VS Code syntax token:

```text
background/surface: #F1ECEC / editor #FBF9F8
foreground:         #211E1E
muted text:         #6B6666
amber text:         #8A5200
red:                #B52A30
green:              #257A3E
yellow:             #7A5B00
blue:               #2968C3
purple:             #7651B5
cyan:               #1E6E79
```

Keep decorative accent/cursor values `#D68C27`, but change selection/cursor text on amber to `#211E1E`. Use `#F1ECEC` on darkened purple `#7651B5` and darkened red `#B52A30` status backgrounds. Set VS Code light line numbers to `#6B6666`; set dark line numbers to `#8A8585`. Fix Ghostty dark foreground to `foreground = cfcecd`.

- [ ] **Step 5: Extend source-level validation**

Add checks for:

```js
const requiredVersion = readFileSync(join(root, "VERSION"), "utf8").trim();
assert.equal(vscodePackage.version, requiredVersion);

for (const token of ghosttyText.matchAll(/^\s*(?:foreground|background|cursor-color|selection-(?:foreground|background)|palette)\s*=\s*(.+)$/gm)) {
  const color = token[1].includes("=") ? token[1].split("=").at(-1) : token[1];
  assert.ok(validateHex(color.trim()), `${file}: invalid color ${color}`);
}
```

Validate the actual VS Code `tokenColors`, editor line numbers, badge/status pairs, and explicit terminal selection/copy/quick-select pairs using `assertContrast`.

- [ ] **Step 6: Run focused tests and validator**

Run: `node --test tests/theme-validator.test.mjs && node scripts/validate-theme.mjs`

Expected: PASS; output ends with a count of validated files and contrast pairs.

- [ ] **Step 7: Commit the palette and validator**

```bash
git add VERSION scripts/validate-theme.mjs tests/theme-validator.test.mjs \
  vscode/themes colors desktoptheme/opencode-light/colors \
  lookandfeel/com.kim.opencode-light/contents/colorschemes \
  konsole/OpenCodeLight.colorscheme alacritty/opencode-light.toml \
  terminals starship/opencode-light.toml
git commit -m "fix: make theme palettes accessible and validated"
```

### Task 2: Harden Image and Screenshot Scripts

**Files:**
- Create: `tests/generators-integration.sh`
- Modify: `scripts/generate-preview.sh:1-65`
- Modify: `scripts/generate-wallpaper.sh:1-40`
- Modify: `scripts/capture-screenshots.sh:6-16`

**Interfaces:**
- Produces: both generator CLIs accepting only `WIDTHxHEIGHT` with positive integers.
- Produces: screenshot CLI accepting only `dark`, `light`, or `all` before checking KDE session state.
- Consumes: ImageMagick `magick`; preview generator optionally consumes `fc-match`.

- [ ] **Step 1: Write adversarial integration tests**

Create `tests/generators-integration.sh` in strict mode. The test must use `mktemp -d`, a cleanup trap, and these cases:

```bash
expect_failure() {
    if "$@" >/dev/null 2>&1; then
        echo "expected failure: $*" >&2
        exit 1
    fi
}

expect_failure scripts/generate-preview.sh "$TEST_TMP/preview" 640X360
expect_failure scripts/generate-wallpaper.sh "$TEST_TMP/wallpaper" 0x360
expect_failure scripts/capture-screenshots.sh invalid

INJECTION_MARKER="$TEST_TMP/injected"
ODD_OUT="$TEST_TMP/out'; touch '$INJECTION_MARKER'; echo '"
scripts/generate-preview.sh "$ODD_OUT" 640x360
test -f "$ODD_OUT/preview-dark.png"
test -f "$ODD_OUT/preview-light.png"
test ! -e "$INJECTION_MARKER"
```

Also create the nested wallpaper output directories, generate a `320x180` pair, and assert both output files have exactly those dimensions using `magick identify -format '%wx%h'`.

- [ ] **Step 2: Run the test to verify existing failures**

Run: `bash tests/generators-integration.sh`

Expected: FAIL because invalid modes/sizes are not rejected or because the apostrophe path breaks the `eval` command.

- [ ] **Step 3: Replace `eval` with command arrays**

In `generate-preview.sh`, represent optional font arguments and all draw operations as arrays:

```bash
FONT_ARGS=()
FONT_BOLD_ARGS=()
[ -n "$FONT_FILE" ] && FONT_ARGS=(-font "$FONT_FILE")
[ -n "$FONT_BOLD_FILE" ] && FONT_BOLD_ARGS=(-font "$FONT_BOLD_FILE")

SWATCH_ARGS=()
LABEL_ARGS=()
SWATCH_ARGS+=(-fill "$hex" -draw "roundrectangle $x,$sy $((x+size)),$((sy+size)) 12,12")
LABEL_ARGS+=(-fill "$LABELCOL" -annotate "+${x}+$((sy+size+26))" "$lab")
```

Invoke `magick` directly with `"${ARRAY[@]}"`. Do not retain any executable `eval` in repository scripts.

- [ ] **Step 4: Add shared hardening patterns to both generators**

Validate size before arithmetic:

```bash
if [[ ! "$SIZE" =~ ^([1-9][0-9]*)x([1-9][0-9]*)$ ]]; then
    echo "ERROR: size must be WIDTHxHEIGHT using positive integers" >&2
    exit 2
fi
W="${BASH_REMATCH[1]}"
H="${BASH_REMATCH[2]}"
```

Create required output directories, track temporary files in an array, and remove them from a single `trap cleanup EXIT`. Use `set -euo pipefail` in all three scripts.

- [ ] **Step 5: Validate screenshot mode before environment checks**

Add a `case "$MODE"` immediately after argument parsing:

```bash
case "$MODE" in
    dark|light|all) ;;
    *) echo "Usage: $0 [dark|light|all]" >&2; exit 2 ;;
esac
```

- [ ] **Step 6: Run focused tests**

Run: `bash -n scripts/*.sh tests/generators-integration.sh && bash tests/generators-integration.sh`

Expected: PASS with no injection marker and four correctly sized generated images.

- [ ] **Step 7: Commit hardened generators**

```bash
git add scripts/generate-preview.sh scripts/generate-wallpaper.sh \
  scripts/capture-screenshots.sh tests/generators-integration.sh
git commit -m "fix: harden theme generation scripts"
```

### Task 3: Installer Reliability and KDE Metadata

**Files:**
- Create: `tests/installer-integration.sh`
- Modify: `install.sh:1-106`
- Modify: `uninstall.sh:1-31`
- Modify: `wallpaper/OpenCode/metadata.json:1-15`
- Modify: `lookandfeel/com.kim.opencode-dark/metadata.json:15`
- Modify: `lookandfeel/com.kim.opencode-light/metadata.json:15`
- Modify: `desktoptheme/opencode-dark/metadata.json:14`
- Modify: `desktoptheme/opencode-light/metadata.json:14`
- Modify: `splash/com.kim.opencode-splash/metadata.json:15`

**Interfaces:**
- Produces: `./install.sh [dark|light|noapply]`, with invalid mode exit 2 before writes.
- Produces: apply summary distinguishing warnings from failures and non-zero exit for failed available core commands.
- Produces: static wallpaper package accepted as `Wallpaper/Images`.

- [ ] **Step 1: Write isolated installer tests**

Create `tests/installer-integration.sh` with strict mode and a temp XDG root. Assert:

```bash
INVALID_DATA="$TEST_TMP/invalid-data"
INVALID_CONFIG="$TEST_TMP/invalid-config"
if XDG_DATA_HOME="$INVALID_DATA" XDG_CONFIG_HOME="$INVALID_CONFIG" ./install.sh typo; then
    echo "invalid mode unexpectedly succeeded" >&2
    exit 1
fi
test ! -e "$INVALID_DATA"
test ! -e "$INVALID_CONFIG"

XDG_DATA_HOME="$DATA" XDG_CONFIG_HOME="$CONFIG" ./install.sh noapply
test -f "$DATA/color-schemes/OpenCodeDark.colors"
test -f "$CONFIG/ghostty/themes/opencode-dark"
XDG_DATA_HOME="$DATA" XDG_CONFIG_HOME="$CONFIG" ./uninstall.sh
test "$(find "$DATA" "$CONFIG" -type f | wc -l)" -eq 0
```

When `kpackagetool6` exists, install LookAndFeel packages under an isolated `XDG_DATA_HOME` and install the wallpaper with `--type Wallpaper/Images`. Assert the same package fails under the wrong `Plasma/Wallpaper` type.

- [ ] **Step 2: Run the test to verify the red state**

Run: `bash tests/installer-integration.sh`

Expected: FAIL because `typo` falls through to a dark live apply and wallpaper metadata declares the wrong type.

- [ ] **Step 3: Validate mode before any filesystem mutation**

Use this exact argument contract near the top of `install.sh`:

```bash
MODE="${1:-dark}"
case "$MODE" in
    dark|light|noapply) ;;
    *) echo "Usage: $0 [dark|light|noapply]" >&2; exit 2 ;;
esac
```

Upgrade installer/uninstaller to `set -euo pipefail`. Keep every destructive target namespaced and quoted.

- [ ] **Step 4: Replace hidden apply failures with an accumulator**

Implement:

```bash
APPLY_FAILURES=0
run_apply() {
    local label="$1"
    shift
    if ! "$@"; then
        echo "ERROR: failed to apply $label" >&2
        APPLY_FAILURES=$((APPLY_FAILURES + 1))
    fi
}
```

Call `run_apply` for every available core Plasma command. Print `WARNING` for a missing command and continue because files were installed successfully. Return non-zero after the summary if `APPLY_FAILURES` is non-zero. Keep DBus reconfigure best-effort but report a warning instead of silently discarding stderr.

- [ ] **Step 5: Correct metadata and version checks**

Set `"KPackageStructure": "Wallpaper/Images"` in canonical wallpaper metadata and add `"Version": "1.0.0"` under its `KPlugin`. Ensure all other component metadata versions equal `VERSION`; extend `scripts/validate-theme.mjs` to enforce them.

- [ ] **Step 6: Run focused tests**

Run: `bash -n install.sh uninstall.sh tests/installer-integration.sh && bash tests/installer-integration.sh && node scripts/validate-theme.mjs`

Expected: PASS, invalid mode creates no XDG root, uninstall leaves zero files, and KDE accepts the wallpaper under `Wallpaper/Images`.

- [ ] **Step 7: Commit installer and metadata fixes**

```bash
git add install.sh uninstall.sh tests/installer-integration.sh \
  wallpaper/OpenCode/metadata.json lookandfeel/*/metadata.json \
  desktoptheme/*/metadata.json splash/com.kim.opencode-splash/metadata.json \
  scripts/validate-theme.mjs
git commit -m "fix: validate installs and KDE package metadata"
```

### Task 4: Adaptive Plasma Splash

**Files:**
- Create: `tests/splash.test.mjs`
- Create: `splash/com.kim.opencode-splash/contents/splash/images/wordmark-light.png`
- Modify: `splash/com.kim.opencode-splash/contents/splash/Splash.qml:4-61`

**Interfaces:**
- Produces: one splash package that follows `Kirigami.Theme.backgroundColor` and `Kirigami.Theme.highlightColor`.
- Produces: `darkBackground: bool` selecting white `wordmark.png` or black `wordmark-light.png`.
- Consumes: existing canonical black wordmark `assets/opencode-wordmark-simple-light.png` copied byte-for-byte.

- [ ] **Step 1: Write static adaptive-splash tests**

Create `tests/splash.test.mjs` that reads QML and asserts:

```js
test("splash follows active Plasma colors", () => {
  assert.match(qml, /Kirigami\.Theme\.backgroundColor/);
  assert.match(qml, /Kirigami\.Theme\.highlightColor/);
  assert.doesNotMatch(qml, /#211E1E|#FAB283/);
});

test("splash selects both wordmark variants and clamps progress", () => {
  assert.match(qml, /images\/wordmark\.png/);
  assert.match(qml, /images\/wordmark-light\.png/);
  assert.match(qml, /Math\.max\(0, Math\.min\(root\.stage, 5\)\)/);
  assert.ok(existsSync(lightWordmark));
});
```

- [ ] **Step 2: Run the test to verify the red state**

Run: `node --test tests/splash.test.mjs`

Expected: FAIL on hard-coded splash colors and missing light wordmark.

- [ ] **Step 3: Add the light wordmark asset**

Copy `assets/opencode-wordmark-simple-light.png` byte-for-byte to `splash/com.kim.opencode-splash/contents/splash/images/wordmark-light.png`. Confirm with `cmp`.

- [ ] **Step 4: Make QML adaptive**

Add these root properties and replace hard-coded colors:

```qml
color: Kirigami.Theme.backgroundColor

readonly property bool darkBackground: {
    const c = Kirigami.Theme.backgroundColor;
    return 0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b < 0.5;
}
```

Set the image source to `root.darkBackground ? "images/wordmark.png" : "images/wordmark-light.png"`. Set the progress track to a low-alpha version of `Kirigami.Theme.textColor`, fill to `Kirigami.Theme.highlightColor`, and width to:

```qml
width: parent.width * (Math.max(0, Math.min(root.stage, 5)) / 5)
```

- [ ] **Step 5: Run focused tests and package validation**

Run: `node --test tests/splash.test.mjs && XDG_DATA_HOME="$(mktemp -d)" kpackagetool6 --type Plasma/LookAndFeel --install splash/com.kim.opencode-splash`

Expected: PASS and KDE reports successful installation.

- [ ] **Step 6: Commit adaptive splash**

```bash
git add tests/splash.test.mjs splash/com.kim.opencode-splash
git commit -m "fix: adapt splash colors to active theme"
```

### Task 5: Atomic Release Builder and Source Asset Deduplication

**Files:**
- Create: `scripts/build-release.sh`
- Create: `tests/release-integration.sh`
- Create: `vscode/extension.vsixmanifest`
- Create: `vscode/[Content_Types].xml`
- Delete: `vscode/opencode-theme-1.0.0.vsix`
- Delete: `lookandfeel/com.kim.opencode-dark/contents/wallpapers/OpenCode/**`
- Delete: `lookandfeel/com.kim.opencode-light/contents/wallpapers/OpenCode/**`

**Interfaces:**
- Produces: `scripts/build-release.sh` with no arguments, writing deterministic filenames under `dist/`.
- Produces: `dist/opencode-lookandfeel-{dark,light}-VERSION.tar.gz`, `opencode-wallpaper-VERSION.tar.gz`, `opencode-theme-VERSION.tar.gz`, `opencode-theme-VERSION.vsix`, and `SHA256SUMS`.
- Consumes: `VERSION`, canonical `wallpaper/OpenCode`, all source component directories, `tar`, `zip`, `unzip`, `sha256sum`, and Node validator.

- [ ] **Step 1: Write release integration tests**

Create `tests/release-integration.sh`. Before invoking the builder, assert source deduplication:

```bash
test "$(find wallpaper -type f -name '3840x2160.png' | wc -l)" -eq 2
test "$(find lookandfeel -type f -name '3840x2160.png' | wc -l)" -eq 0
if compgen -G 'vscode/*.vsix' >/dev/null; then
    echo "tracked/source VSIX must not exist" >&2
    exit 1
fi
```

Run the builder, assert the six deterministic outputs, verify `sha256sum -c SHA256SUMS`, inspect each archive for symlinks, and extract the full bundle. Assert both desktop themes, the canonical wallpaper, adaptive splash, terminal configs, install scripts, and source VS Code themes exist.

Extract the VSIX and compare `extension/package.json` and both theme JSON files byte-for-byte with source. When `kpackagetool6` exists, validate both staged LookAndFeel archives and the wallpaper archive under isolated XDG roots.

- [ ] **Step 2: Run the test to verify the red state**

Run: `bash tests/release-integration.sh`

Expected: FAIL because duplicate wallpaper payloads and checked-in VSIX still exist and no release builder is present.

- [ ] **Step 3: Add VSIX package sources**

Extract the existing `extension.vsixmanifest` and `[Content_Types].xml` into source before deleting the binary. Normalize XML indentation without changing manifest identity, version `1.0.0`, publisher, engine, description, categories, or assets. Extend version validation to compare manifest identity version and `vscode/package.json` against `VERSION`.

- [ ] **Step 4: Implement temporary staging**

Start `scripts/build-release.sh` with:

```bash
#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION="$(tr -d '[:space:]' < "$ROOT/VERSION")"
BUILD_TMP="$(mktemp -d)"
trap 'rm -rf "$BUILD_TMP"' EXIT
STAGE="$BUILD_TMP/opencode-theme-$VERSION"
OUT="$BUILD_TMP/out"
mkdir -p "$STAGE" "$OUT"
```

Validate required commands up front. Copy only the source files needed by `install.sh`, plus README, LICENSE, notice, and VERSION. Materialize `wallpaper/OpenCode` inside each staged LookAndFeel package with `cp -a`.

- [ ] **Step 5: Build deterministic artifacts**

Use sorted tar input and stable gzip headers where supported. Create the VSIX layout in a temporary directory with root `extension.vsixmanifest`, `[Content_Types].xml`, and `extension/{package.json,themes}`; run `zip` from inside that directory so paths match the VSIX contract.

Generate checksums from inside `OUT`:

```bash
(
  cd "$OUT"
  sha256sum opencode-*.tar.gz opencode-theme-*.vsix > SHA256SUMS
)
```

Run source validation and release smoke checks before publishing output.

- [ ] **Step 6: Implement atomic `dist/` replacement**

After every build and validation command succeeds, move the previous `dist/` to a process-specific backup, move the completed output into place, and restore the backup if the second move fails. Delete the backup only after the new `dist/` is present.

- [ ] **Step 7: Remove derived source artifacts**

Delete the checked-in VSIX and both nested LookAndFeel wallpaper directories. Do not remove canonical `wallpaper/OpenCode` or wordmark source assets.

- [ ] **Step 8: Run focused release tests**

Run: `bash -n scripts/build-release.sh tests/release-integration.sh && bash tests/release-integration.sh`

Expected: PASS; source contains two canonical 4K PNGs, staged LookAndFeel archives contain their materialized copies, all checksums pass, and VSIX files match source.

- [ ] **Step 9: Commit release pipeline and deduplication**

```bash
git add scripts/build-release.sh tests/release-integration.sh vscode \
  lookandfeel/com.kim.opencode-dark/contents/wallpapers \
  lookandfeel/com.kim.opencode-light/contents/wallpapers
git commit -m "build: generate complete release artifacts from canonical assets"
```

### Task 6: Accurate Documentation and Wordmark Provenance

**Files:**
- Create: `THIRD_PARTY_NOTICES.md`
- Modify: `README.md:1-212`

**Interfaces:**
- Produces: documentation matching source install, full release bundle, partial LookAndFeel artifacts, SDDM non-support, validation, and release commands.
- Consumes: upstream OpenCode MIT license and official assets at `packages/web/src/assets/logo-dark.svg` and `logo-light.svg`.

- [ ] **Step 1: Write documentation assertions**

Extend `tests/release-integration.sh` with static assertions:

```bash
if rg -n 'login screen (needs no setup|follows)|login/lock-screen look' README.md; then
    echo "README still claims SDDM support" >&2
    exit 1
fi
rg -q 'does not ship an SDDM' README.md
rg -q 'scripts/build-release.sh' README.md
rg -q 'opencode-theme-1.0.0.tar.gz' README.md
rg -q 'packages/web/src/assets/logo-dark.svg' THIRD_PARTY_NOTICES.md
rg -q 'Copyright (c) 2025 opencode' THIRD_PARTY_NOTICES.md
```

- [ ] **Step 2: Run the documentation assertions to verify the red state**

Run: `bash tests/release-integration.sh`

Expected: FAIL because README still claims automatic login-screen theming and the notice file is absent.

- [ ] **Step 3: Add the third-party notice**

Document that the PNG wordmarks are raster derivatives of the official upstream files:

- `https://github.com/anomalyco/opencode/blob/dev/packages/web/src/assets/logo-dark.svg`
- `https://github.com/anomalyco/opencode/blob/dev/packages/web/src/assets/logo-light.svg`

Include `Copyright (c) 2025 opencode` and the complete upstream MIT license text. State that OpenCode names and marks remain the property of their owners and preserve the existing unofficial-project disclaimer.

- [ ] **Step 4: Correct README behavior and installation claims**

Make these factual changes:

- Explain that Plasma lock screen follows the Plasma style, while SDDM is separate and not shipped/configured.
- Replace raw LookAndFeel commands as the recommended manual path with extracting `dist/opencode-theme-1.0.0.tar.gz` and running `./install.sh` from the bundle.
- Label individual LookAndFeel archives as partial component packages that do not install the desktop theme.
- Document `./scripts/test.sh` and `./scripts/build-release.sh`.
- Update the VSIX install example to use `dist/opencode-theme-1.0.0.vsix`.
- Replace “no third-party assets” with a link to `THIRD_PARTY_NOTICES.md`.
- Explain that source stores one wallpaper copy while release staging embeds required copies.

- [ ] **Step 5: Run documentation and release tests**

Run: `bash tests/release-integration.sh && node scripts/validate-theme.mjs`

Expected: PASS with no unsupported SDDM claims and complete notice/source links.

- [ ] **Step 6: Commit documentation corrections**

```bash
git add README.md THIRD_PARTY_NOTICES.md tests/release-integration.sh
git commit -m "docs: correct install scope and asset provenance"
```

### Task 7: Unified Test Entry Point and CI

**Files:**
- Create: `scripts/test.sh`
- Create: `.github/workflows/ci.yml`
- Modify: `.gitignore:1-3`

**Interfaces:**
- Produces: `scripts/test.sh [--require-kde]` running every unit and integration test.
- Produces: CI on push and pull request, requiring KDE package validation.
- Consumes: Bash, Node, jq, ImageMagick, zip/unzip, tar, and optional/required `kpackagetool6`.

- [ ] **Step 1: Write the unified runner**

Create `scripts/test.sh` with strict mode, repository-root discovery, and this sequence:

```bash
for file in install.sh uninstall.sh scripts/*.sh tests/*.sh; do
    bash -n "$file"
done

find . -type f -not -path './.git/*' -name '*.json' -print0 \
  | xargs -0 -n1 jq empty

node --test tests/*.test.mjs
node scripts/validate-theme.mjs
bash tests/generators-integration.sh
bash tests/installer-integration.sh
bash tests/release-integration.sh
git diff --check
```

If `--require-kde` is supplied, fail up front when `kpackagetool6` is missing. Otherwise print one explicit skip notice from KDE-specific tests.

- [ ] **Step 2: Run the complete suite locally**

Run: `scripts/test.sh --require-kde`

Expected: PASS with JSON count, Node test count, generator outputs, zero installer residue, KDE package success, release checksums, and clean diff check.

- [ ] **Step 3: Add CI workflow**

Create `.github/workflows/ci.yml`:

```yaml
name: CI

on:
  push:
  pull_request:

jobs:
  validate:
    runs-on: ubuntu-latest
    container: debian:trixie
    steps:
      - name: Install validators
        run: |
          apt-get update
          apt-get install -y --no-install-recommends \
            bash git imagemagick jq kpackagetool6 nodejs plasma-workspace \
            tar unzip zip
      - uses: actions/checkout@v4
      - name: Validate source and release artifacts
        run: ./scripts/test.sh --require-kde
```

Use Debian trixie because its official repository provides KDE Frameworks 6
`kpackagetool6`. Install `plasma-workspace` as well because it supplies the
`plasma_lookandfeel.so` and `wallpaper_images.so` package-structure plugins
required for these two package types.

- [ ] **Step 4: Keep generated and atomic staging outputs ignored**

Ensure `.gitignore` contains:

```gitignore
dist/
.dist.previous.*
.dist.next.*
```

Do not ignore release source templates, tests, or notices.

- [ ] **Step 5: Run fresh full verification**

Run: `scripts/test.sh --require-kde && git diff --check && git status --short`

Expected: all tests pass; status contains only the intended Task 7 files before commit.

- [ ] **Step 6: Commit CI and test orchestration**

```bash
git add scripts/test.sh .github/workflows/ci.yml .gitignore
git commit -m "ci: validate themes installers and release artifacts"
```

- [ ] **Step 7: Final acceptance audit**

Run:

```bash
scripts/test.sh --require-kde
node scripts/validate-theme.mjs
scripts/build-release.sh
(cd dist && sha256sum -c SHA256SUMS)
git diff --check
git status --short --branch
```

Expected: every command exits zero, release artifacts use version `1.0.0`, and the worktree is clean after all planned commits.
