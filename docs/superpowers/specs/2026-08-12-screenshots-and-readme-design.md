# Design: Real Screenshots + README Expansion

Date: 2026-08-12

## Goal

Make the OpenCode KDE Plasma theme repo compelling for new users on GitHub/KDE Store by adding real screenshots of the themes and expanding the README into a complete guide (quick start, accent customization, FAQ, troubleshooting).

## Scope

1. New script `scripts/capture-screenshots.sh` that captures clean real screenshots for both variants (dark + light) on the user's live Plasma 6.7 Wayland desktop.
2. New `screenshots/` directory with the captured images, organized per variant.
3. Expanded `README.md` with hero preview pair, screenshot gallery, Quick Start, "Customizing the accent color", FAQ, and Troubleshooting sections.

Out of scope: docs/ directory per component, KDE Store publishing, GTK/Kvantum themes, SDDM theme, panel layouts (rejected earlier).

## Environment facts

- Plasma 6.7.4 on Wayland, single screen: eDP-1 1920x1200 @ scale 1.5 (logical 1280x800)
- `spectacle` available (`--background --fullscreen` works under Wayland; `-w` window capture is unreliable under Wayland → capture fullscreen only)
- Theme currently applied live: `com.kim.opencode-dark`; switching via `./install.sh light` / `./install.sh` (dark)
- ImageMagick available for post-processing (already used by generate-preview.sh)

## Design

### 1. `scripts/capture-screenshots.sh`

Interactive script, run from a terminal on the live desktop. Behavior:

- Takes one optional argument: `dark`, `light`, or `all` (default `all`).
- For each requested variant:
  1. Applies the theme variant via `./install.sh <variant>` (noapply is NOT used — the live switch is needed for authentic captures).
  2. Creates `screenshots/<variant>/`.
  3. For each scene, prints an instruction, optionally shows a `kdialog --passivepopup` notification, waits for Enter, then captures with:
     `spectacle --background --nonotify --fullscreen --output <out.png>`
  4. Scenes (4 per variant):
     - `desktop.png` — desktop with no open windows (wallpaper + panel only)
     - `konsole.png` — Konsole with the OpenCode profile + starship prompt showing
     - `vscode.png` — VS Code with the OpenCode theme applied
     - `system-settings.png` — System Settings → Colors & Themes → Global Theme page (optional scene; skipped if user declines)
  5. Post-process each capture with ImageMagick: scale to max width 1280px, output to `screenshots/<variant>/<scene>.png`.
- After all variants, restores the dark theme (`./install.sh`) and prints a summary.
- Uses `set -euo pipefail`, same shell style as existing scripts (`generate-preview.sh`).
- The script refuses to run if not on a KDE Plasma session (checks `XDG_CURRENT_DESKTOP` contains KDE).

### 2. `screenshots/` layout

```
screenshots/
  dark/
    desktop.png
    konsole.png
    vscode.png
    system-settings.png   (optional)
  light/
    desktop.png
    konsole.png
    vscode.png
    system-settings.png   (optional)
```

Images are scaled to max 1280px wide, PNG. Named consistently for README linking.

### 3. README.md restructure

Keeps existing content (palette tables, what's included, install, uninstall, license, warning disclaimer) and adds:

1. **Hero images** — right after the intro paragraph: the synthetic preview pair
   `[![]](previews/preview-dark.png)` and `[![]](previews/preview-light.png)`.
2. **Screenshots gallery** — a section with the real captures, dark and light
   side by side (GitHub-flavored table or adjacent images), covering desktop,
   Konsole, VS Code.
3. **Quick Start** — 5-step numbered guide for new users: clone, install,
   apply global theme, optional terminal/editor extras, done.
4. **Customizing the accent color** — how the accent is defined (peach #FAB283
   dark / amber #D68C27 light), where to change it (System Settings → Colors &
   Themes → Colors → Edit, or directly in `colors/OpenCodeDark.colors` and
   `colors/OpenCodeLight.colors`), and the knock-on effects: VS Code extension
   and terminal themes (konsole/alacritty/terminals/) have their own accent
   values that must be edited separately.
5. **FAQ** — ~6–8 questions:
   - How do I switch between dark and light?
   - Does the theme change my panel layout or desktop widgets? (No — panel
     layout support was removed by design.)
   - GTK apps (Firefox, Thunar...) don't follow the theme?
   - Does the login/lock screen pick the theme up automatically?
   - Which Plasma version is required? (Plasma 6)
   - Is this theme official? (No — community, see disclaimer.)
6. **Troubleshooting** — short entries:
   - Wallpaper doesn't switch when changing variant → check both variants
     installed, re-run `./install.sh`; stale `usersWallpapers` override cleared
     by install.sh.
   - Konsole profile not showing → restart Konsole, or import scheme manually.
   - `code --install-extension` fails → install the .vsix from
     `~/.config/opencode-theme.vsix` manually.
   - Uninstall safely → switch Global Theme first, then `./uninstall.sh`.
   - Screenshot script says not a Plasma session → must run inside a KDE session.

### Files touched

- New: `scripts/capture-screenshots.sh`
- New: `screenshots/` (dark/, light/, captured images)
- Edit: `README.md`

### Verification

- `./scripts/capture-screenshots.sh all` runs end to end, produces 6–8 PNGs, restores dark theme.
- Captured images are visually inspected (no privacy leaks, correct theme applied).
- README renders on GitHub (image links valid, relative paths correct).
- `git status` shows only intended new/modified files.
