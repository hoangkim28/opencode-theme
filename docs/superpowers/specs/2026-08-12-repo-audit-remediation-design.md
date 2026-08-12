# Repository Audit Remediation Design

**Date:** 2026-08-12  
**Status:** Approved for planning  
**Scope:** Resolve all findings from the repository audit without changing the theme's warm OpenCode visual identity.

## Goals

- Make the light theme readable at WCAG AA contrast for normal text.
- Repair broken terminal configuration and harden shell tooling.
- Make every documented installation path complete and accurate.
- Replace committed duplicate wallpaper payloads with release-time staging.
- Add dependency-free validation, regression tests, and continuous integration.
- Preserve offline installation and self-contained KDE release artifacts.

## Non-goals

- Add an SDDM login theme.
- Add GTK, Kvantum, icon, cursor, or panel-layout themes.
- Redesign the established warm neutral visual identity.
- Generate wallpapers from scratch during every release.

## Source and Release Architecture

The repository will keep one canonical wallpaper package at
`wallpaper/OpenCode`. The duplicated 4K wallpaper files under each
`lookandfeel/*/contents/wallpapers` directory will be removed from source.

`scripts/build-release.sh` will build in a temporary staging directory and
write completed artifacts to `dist/` only after validation succeeds. It will:

1. Read the release version from a root `VERSION` file.
2. Validate source metadata and ensure component versions agree with `VERSION`.
3. Stage the dark and light LookAndFeel packages.
4. Copy the canonical wallpaper package into each staged LookAndFeel package.
5. Stage both Plasma desktop themes, the adaptive splash, terminal themes, and
   the standalone wallpaper package.
6. Build the VS Code VSIX from its source files without a checked-in VSIX
   binary.
7. Produce dark and light LookAndFeel archives, a standalone wallpaper
   archive, a complete install bundle, the VSIX, and SHA-256 checksums.
8. Reject symlinks and incomplete package contents.

The complete install bundle remains self-contained and suitable for offline
use. The individual LookAndFeel archives are explicitly partial component
artifacts. Git source no longer stores duplicate wallpaper payloads or a built
VSIX binary.

## Palette and Accessibility

The brand amber `#D68C27` remains available for non-text decoration such as
focus borders, cursor color, and accents. Text displayed on amber, purple, or
other colored fills will use a dark foreground such as `#211E1E`.

Light syntax colors will be replaced with darker role-equivalent variants.
Exact values are implementation details, but every normal-size text role
covered by validation must achieve at least 4.5:1 contrast against its actual
background. The validator will cover:

- VS Code editor text, syntax token roles, line numbers, badges, remote status,
  prominent status, and debugging status.
- Terminal foreground, ANSI colors, selection, cursor text, copy mode, and
  quick-select labels where foreground/background pairs are explicit.
- Plasma window, view, selection, tooltip, button, and complementary roles.

Disabled and inactive controls may retain lower contrast only where WCAG does
not require the normal-text threshold. They will be listed explicitly rather
than silently excluded.

## Adaptive Splash

The splash will remain a single package but stop hard-coding dark colors. QML
will derive background and accent colors from the active Plasma/Kirigami theme,
calculate whether the background is light or dark, and choose the black or
white canonical wordmark accordingly. Progress width will be clamped to the
valid stage range.

## Installer and Uninstaller

`install.sh` will accept exactly `dark`, `light`, or `noapply`. Any other value
will print usage, return exit code 2, and perform no writes.

Core apply commands will no longer hide failures with unconditional
`|| true`. Missing optional integration commands will produce warnings.
Failures from available core Plasma apply commands will be accumulated,
reported in a final summary, and cause a non-zero exit status. File-only mode
will remain usable without a live Plasma session.

Installer and uninstaller tests will run with isolated `XDG_DATA_HOME` and
`XDG_CONFIG_HOME` directories. A complete no-apply install followed by
uninstall must leave no managed files behind.

The installer will continue to overwrite only the project's namespaced theme
directories and files. User-owned primary application configuration files will
not be replaced.

## Script Hardening

`scripts/generate-preview.sh` will replace string-built commands and `eval`
with Bash arrays. Temporary files and staging directories will be cleaned with
`trap` handlers on normal exit and failure. Size parameters will be validated
before arithmetic expansion, and output directories will be created safely.

The same size validation and temporary-file cleanup rules will be applied to
`scripts/generate-wallpaper.sh`. Screenshot capture mode will accept only
`dark`, `light`, or `all`.

## KDE Packaging

The standalone static wallpaper metadata will use `Wallpaper/Images`, matching
the type accepted by `kpackagetool6`. Release validation will install packages
into an isolated XDG data root and require:

- both LookAndFeel packages to be accepted;
- both desktop themes to be present in the full bundle;
- the wallpaper package to be accepted as `Wallpaper/Images`;
- the staged LookAndFeel packages to contain their wallpaper payloads;
- no symlinks in any KDE package.

Manual installation documentation will target the complete release bundle.
Raw LookAndFeel-only installation will be described as partial and will not be
presented as installing the panel/desktop theme.

The release filenames will be deterministic:

- `opencode-lookandfeel-dark-VERSION.tar.gz`
- `opencode-lookandfeel-light-VERSION.tar.gz`
- `opencode-wallpaper-VERSION.tar.gz`
- `opencode-theme-VERSION.tar.gz` for the complete install bundle
- `opencode-theme-VERSION.vsix`
- `SHA256SUMS`

## Documentation and Asset Provenance

README claims will distinguish the lock screen from SDDM. The project will say
explicitly that it does not ship or configure an SDDM login theme.

The wordmark will be documented as derived from or sourced from the upstream
OpenCode project after its exact source is verified. A third-party notice will
preserve the upstream copyright and MIT license notice. The repository will no
longer claim that the generated wallpaper contains no third-party assets.

Install, uninstall, regeneration, validation, and release instructions will be
updated to match actual commands and artifacts.

## Validation and Continuous Integration

A dependency-free Node validator plus shell integration tests will check:

- Bash and JSON syntax;
- component version consistency;
- Ghostty direct-color and palette grammar;
- required WCAG contrast pairs;
- cross-format canonical palette roles;
- invalid installer and screenshot modes;
- isolated install/uninstall symmetry;
- preview output paths containing apostrophes without command injection;
- release contents, checksums, and absence of symlinks;
- KDE package acceptance when `kpackagetool6` is available;
- freshly built VSIX contents matching the current extension source.

GitHub Actions will run the same repository test entry point on pushes and pull
requests. CI will install only the external tools required for image generation
and KDE package validation. Local validation will report a clear skip only for
optional platform validators that are unavailable; CI will require them.

## Error Handling and Atomicity

Build output will be assembled under a `mktemp` directory. The script will use
strict shell mode, quote every path, validate prerequisites up front, and clean
temporary state through traps. Existing `dist/` will be replaced only after a
complete staged build passes validation. A failed build must leave the previous
release output intact.

Installer errors will identify the failed component and distinguish warnings
for unavailable optional tools from errors returned by available core tools.

## Acceptance Criteria

- All audited light-theme text pairs covered by the validator meet 4.5:1.
- Ghostty dark foreground is a valid six-digit hexadecimal color.
- No repository script contains executable `eval` command construction.
- Invalid modes fail before creating installation output.
- `install.sh noapply` followed by `uninstall.sh` leaves zero managed files.
- README makes no claim that the project installs or automatically themes SDDM.
- Static wallpaper metadata and validation use `Wallpaper/Images`.
- Canonical 4K wallpaper images occur once in tracked source.
- Release archives contain the required duplicated payloads and no symlinks.
- Source validation, integration tests, release smoke tests, and CI pass.
- The tracked source contains no built VSIX; the release VSIX matches the
  current extension source and declared version.
