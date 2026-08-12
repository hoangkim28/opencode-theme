# Screenshots + README Expansion Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Capture real screenshots of the OpenCode KDE Plasma themes (dark + light) on the live desktop and expand the README into a complete user-facing guide.

**Architecture:** An interactive bash script (`scripts/capture-screenshots.sh`) applies each theme variant via `install.sh`, waits for the user to prepare a clean scene, captures fullscreen with `spectacle` under Wayland, and downsizes with ImageMagick into `screenshots/<variant>/`. The README is then restructured to embed those images plus new Quick Start, accent-customization, FAQ and Troubleshooting sections.

**Tech Stack:** bash, spectacle (Wayland fullscreen capture), ImageMagick 7 (`magick`), kdialog (optional), Git.

## Global Constraints

- Plasma 6 only; script must refuse to run outside a KDE session (`XDG_CURRENT_DESKTOP` contains `KDE`).
- Fullscreen capture only — `spectacle -w` window capture is unreliable under Wayland.
- Screenshots scaled down to max 1280px wide, never upscaled, PNG, named exactly: `desktop.png`, `konsole.png`, `vscode.png`, `system-settings.png` (optional).
- Captures must be privacy-safe: user closes windows / prepares each scene before capture.
- `install.sh` is invoked with no extra args (dark), `light`, `all` only — the live switch is required for authentic captures.
- README keeps all existing content (palette tables, what's included, install, uninstall, license, disclaimer) — only adds/reorders sections.
- Script style matches existing `scripts/generate-preview.sh` (bash, `set -e`, `HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"`).
- No comments in code unless asked; bash scripts in this repo are allowed a short header comment.

---
### Task 1: Write `scripts/capture-screenshots.sh`

**Files:**
- Create: `scripts/capture-screenshots.sh`

**Interfaces:**
- Consumes: `install.sh` (repo root) — invoked as `"$ROOT/install.sh"`, `"$ROOT/install.sh" light`; switches live theme and restores dark.
- Produces: `screenshots/<variant>/desktop.png|konsole.png|vscode.png|system-settings.png` consumed by Task 3's README gallery.

- [ ] **Step 1: Create the script**

```bash
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
    local variant="$1" outdir="$ROOT/screenshots/$variant"
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
```

- [ ] **Step 2: Syntax-check and make executable**

Run:
```bash
bash -n scripts/capture-screenshots.sh && chmod +x scripts/capture-screenshots.sh
```
Expected: no output, exit 0.

- [ ] **Step 3: Refuse-to-run check (session guard)**

Run:
```bash
env XDG_CURRENT_DESKTOP=GNOME bash scripts/capture-screenshots.sh
```
Expected: prints `ERROR: must run inside a KDE Plasma session` and exits non-zero without capturing anything.

- [ ] **Step 4: Commit**

```bash
git add scripts/capture-screenshots.sh
git commit -m "scripts: add interactive screenshot capture for both theme variants"
```

---
### Task 2: Run the capture script and inspect the screenshots

**Files:**
- Create: `screenshots/dark/desktop.png`, `screenshots/dark/konsole.png`, `screenshots/dark/vscode.png` (+ optional `system-settings.png`)
- Create: `screenshots/light/desktop.png`, `screenshots/light/konsole.png`, `screenshots/light/vscode.png` (+ optional `system-settings.png`)

**Interfaces:**
- Consumes: `scripts/capture-screenshots.sh` from Task 1.
- Produces: the PNG files Task 3 links from the README gallery (exact filenames above).

- [ ] **Step 1: Run the full capture**

Run (interactive — this drives the live desktop, ~5 minutes):
```bash
./scripts/capture-screenshots.sh all
```
Expected: applies dark, captures 3 scenes (+ optional settings), applies light, captures 3 scenes, restores dark, prints `Done. Screenshots in .../screenshots/{dark,light}/`.

- [ ] **Step 2: Verify the output files**

Run:
```bash
file screenshots/dark/*.png screenshots/light/*.png
identify screenshots/dark/desktop.png screenshots/light/desktop.png
```
Expected: all are PNG, 1280px wide, 4 files per variant in the worst case; dark theme screenshots visibly dark, light visibly light.

- [ ] **Step 3: Visual privacy + quality inspection**

Open each PNG (`xdg-open screenshots/dark/desktop.png`, ...). For every image verify: correct variant applied (panel/wallpaper colors), no private content visible (other windows, personal files, browser tabs), no artifacts. Re-run the capture for any scene that fails inspection (option `dark` or `light` only, to avoid re-capturing the good variant).

- [ ] **Step 4: Commit**

```bash
git add screenshots/
git commit -m "docs: add real screenshots of the OpenCode dark + light themes"
```

---
### Task 3: Restructure README.md

**Files:**
- Modify: `README.md`

**Interfaces:**
- Consumes: `previews/preview-dark.png`, `previews/preview-light.png` (existing) and `screenshots/<variant>/` PNGs from Task 2.
- Produces: the final user-facing README; no later task consumes it.

- [ ] **Step 1: Add hero images right after the intro paragraph (after the "⚠️ Unofficial community theme" blockquote, before `## Palette`)**

```markdown
<p align="center">
  <img src="previews/preview-dark.png" alt="OpenCode Dark" width="49%">
  <img src="previews/preview-light.png" alt="OpenCode Light" width="49%">
</p>
```

- [ ] **Step 2: Add the screenshot gallery between `## What's included` and `## Install`**

```markdown
## Screenshots

| OpenCode Dark | OpenCode Light |
| :-: | :-: |
| ![Desktop dark](screenshots/dark/desktop.png) | ![Desktop light](screenshots/light/desktop.png) |
| ![Konsole dark](screenshots/dark/konsole.png) | ![Konsole light](screenshots/light/konsole.png) |
| ![VS Code dark](screenshots/dark/vscode.png) | ![VS Code light](screenshots/light/vscode.png) |
```

Also add `screenshots/` to the `## What's included` fenced tree: a line `screenshots/     Real captures — desktop, Konsole, VS Code (dark + light)` inserted in the tree block.

- [ ] **Step 3: Add `## Quick Start` immediately before `## Install`**

```markdown
## Quick Start

1. **Get the theme** — `git clone https://github.com/<you>/opencode-theme && cd opencode-theme`
2. **Install** — `./install.sh` (adds `light` to install the light variant instead)
3. **Apply** — pick **OpenCode Dark** or **OpenCode Light** in *System Settings → Colors & Themes → Global Theme* (the script already applied one variant)
4. **Optional extras** — Konsole profile, Alacritty import, Starship, VS Code extension, ghostty/kitty/wezterm (see [Terminal prompts & editors](#terminal-prompts--editors))
5. **Done** — wallpaper, panel, lock screen and boot splash all follow the theme automatically
```

- [ ] **Step 4: Add `## Customizing the accent color` before `## Uninstall`**

```markdown
## Customizing the accent color

The accent lives in the **color scheme** — peach `#FAB283` on dark, amber `#D68C27` on light.

- **GUI:** *System Settings → Colors & Themes → Colors → Edit…*, change `Accent` for your variant, save as a new scheme.
- **Files:** edit `colors/OpenCodeDark.colors` (section `[Colors:Complementary]`, key `Accent`) or `colors/OpenCodeLight.colors`, then re-run `./install.sh`.

Note: the terminal themes (Konsole, Alacritty, ghostty/kitty/wezterm) and the VS Code extension hard-code their own accent values — if you change the Plasma accent you'll want to edit those files too (`konsole/*.colorscheme`, `alacritty/*.toml`, `terminals/`, `vscode/`), then reinstall.
```

- [ ] **Step 5: Add `## FAQ` before `## Uninstall` (after the accent section)**

```markdown
## FAQ

**How do I switch between dark and light?**
*System Settings → Colors & Themes → Global Theme → OpenCode Dark / OpenCode Light*, or re-run `./install.sh light` / `./install.sh`. The wallpaper switches variant automatically.

**Does the theme change my panel layout or desktop widgets?**
No. The theme only provides colors, wallpaper, splash and login/lock-screen look. Panel layouts were intentionally kept out.

**GTK apps (Firefox, Thunar, …) don't follow the theme?**
GTK apps need their own GTK theme — this project is Plasma-only, so GTK apps keep their default look.

**Does the login/lock screen pick it up automatically?**
Yes — the lock screen follows the color scheme and wallpaper; the login screen follows the color scheme, desktop theme and wallpaper.

**Which Plasma version do I need?**
Plasma 6 (uses `plasma-apply-*` tools and `kwriteconfig6`).

**Is this theme official?**
No — it's an unofficial community theme borrowing the opencode.ai palette (see disclaimer at the top).
```

- [ ] **Step 6: Add `## Troubleshooting` after `## FAQ`**

```markdown
## Troubleshooting

**Wallpaper doesn't switch between dark and light**
Re-run `./install.sh` — it clears the stale `usersWallpapers` override in `plasmarc` and points Plasma at the wallpaper *package*, which auto-selects the matching variant.

**Konsole profile doesn't show up**
Restart Konsole, or pick it manually: *Settings → Switch Profile → OpenCode Dark / OpenCode Light*.

**`code --install-extension` fails**
Install the .vsix manually: *Extensions → … → Install from VSIX…* → `~/.config/opencode-theme.vsix`.

**Theme applies but the panel still looks default**
Run `./install.sh` again (it applies the Plasma desktop theme `opencode-dark`/`opencode-light` explicitly), then re-login if it still doesn't change.

**Uninstall safely**
Switch to another Global Theme in System Settings first, then `./uninstall.sh`.

**`capture-screenshots.sh` says "must run inside a KDE Plasma session"**
The screenshot script captures your live desktop — it only works from a real KDE session, not over SSH or from a TTY.
```

- [ ] **Step 7: Verify the README renders and links resolve**

Run:
```bash
for img in previews/preview-dark.png previews/preview-light.png \
           screenshots/dark/desktop.png screenshots/light/desktop.png \
           screenshots/dark/konsole.png screenshots/light/konsole.png \
           screenshots/dark/vscode.png screenshots/light/vscode.png; do
    test -f "$img" || echo "MISSING: $img"
done
```
Expected: no `MISSING:` lines.

- [ ] **Step 8: Commit**

```bash
git add README.md
git commit -m "docs: expand README with screenshots, quick start, accent guide, FAQ and troubleshooting"
```
