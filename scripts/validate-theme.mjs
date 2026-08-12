#!/usr/bin/env node

import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const root = dirname(dirname(fileURLToPath(import.meta.url)));

export function validateHex(value) {
  return /^(?:#|0x)?[0-9a-f]{6}$/i.test(value);
}

function luminance(value) {
  const hex = value.replace(/^#/, "").slice(0, 6);
  const channels = [0, 2, 4]
    .map((offset) => Number.parseInt(hex.slice(offset, offset + 2), 16) / 255)
    .map((channel) =>
      channel <= 0.04045
        ? channel / 12.92
        : ((channel + 0.055) / 1.055) ** 2.4,
    );
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
    throw new Error(
      `${label}: ${ratio.toFixed(2)}:1 is below ${minimum.toFixed(1)}:1`,
    );
  }
}

function readJson(relativePath) {
  return JSON.parse(readFileSync(join(root, relativePath), "utf8"));
}

function validateGhostty(relativePath) {
  const content = readFileSync(join(root, relativePath), "utf8");
  const colorLine = /^\s*(background|foreground|cursor-color|selection-(?:background|foreground)|palette)\s*=\s*(.+?)\s*$/gm;
  for (const match of content.matchAll(colorLine)) {
    const raw = match[1] === "palette" ? match[2].split("=").at(-1) : match[2];
    assert.ok(validateHex(raw.trim()), `${relativePath}: invalid color ${raw}`);
  }
  return content;
}

function validateVsCodeTheme(relativePath) {
  const theme = readJson(relativePath);
  const background = theme.colors["editor.background"];
  const pairs = [
    ["editor foreground", theme.colors["editor.foreground"], background],
    ["editor line number", theme.colors["editorLineNumber.foreground"], background],
    ["activity badge", theme.colors["activityBarBadge.foreground"], theme.colors["activityBarBadge.background"]],
    ["remote status", theme.colors["statusBarItem.remoteForeground"], theme.colors["statusBarItem.remoteBackground"]],
    ["prominent status", theme.colors["statusBarItem.prominentForeground"], theme.colors["statusBarItem.prominentBackground"]],
    ["debugging status", theme.colors["statusBar.debuggingForeground"], theme.colors["statusBar.debuggingBackground"]],
    ["input error", theme.colors["inputValidation.errorForeground"], theme.colors["inputValidation.errorBackground"]],
    ["input warning", theme.colors["inputValidation.warningForeground"], theme.colors["inputValidation.warningBackground"]],
    ["badge", theme.colors["badge.foreground"], theme.colors["badge.background"]],
  ];

  for (const [label, foreground, pairBackground] of pairs) {
    assertContrast(`${relativePath}: ${label}`, foreground, pairBackground);
  }
  for (const [index, token] of theme.tokenColors.entries()) {
    if (token.settings?.foreground) {
      assertContrast(
        `${relativePath}: tokenColors[${index}]`,
        token.settings.foreground,
        background,
      );
    }
  }
  return pairs.length + theme.tokenColors.filter((token) => token.settings?.foreground).length;
}

function parseSimpleAssignments(relativePath) {
  const content = readFileSync(join(root, relativePath), "utf8");
  const assignments = new Map();
  for (const line of content.split("\n")) {
    const match = line.match(/^\s*([a-zA-Z0-9_.-]+)\s*(?:=|\s)\s*["']?(?:0x|#)?([0-9a-f]{6})["']?\s*$/i);
    if (match) assignments.set(match[1], `#${match[2].toUpperCase()}`);
  }
  return assignments;
}

function validateTerminalSelections() {
  const alacritty = parseSimpleAssignments("alacritty/opencode-light.toml");
  assertContrast(
    "Alacritty light selection",
    alacritty.get("text"),
    alacritty.get("background"),
  );

  const kitty = parseSimpleAssignments("terminals/kitty/opencode-light.conf");
  assertContrast(
    "Kitty light selection",
    kitty.get("selection_foreground"),
    kitty.get("selection_background"),
  );

  const ghosttyContent = validateGhostty("terminals/ghostty/opencode-light");
  const selectionForeground = ghosttyContent.match(/^selection-foreground\s*=\s*([0-9a-f]{6})$/im)?.[1];
  const selectionBackground = ghosttyContent.match(/^selection-background\s*=\s*([0-9a-f]{6})$/im)?.[1];
  assertContrast(
    "Ghostty light selection",
    `#${selectionForeground}`,
    `#${selectionBackground}`,
  );
  return 3;
}

function colorsFromText(content) {
  return [...content.matchAll(/(?:#|0x)([0-9a-f]{6})/gi)].map(
    (match) => `#${match[1].toUpperCase()}`,
  );
}

function validateColorList(label, colors, background) {
  assert.ok(colors.length > 0, `${label}: no colors found`);
  for (const [index, color] of colors.entries()) {
    assertContrast(`${label}[${index}]`, color, background);
  }
  return colors.length;
}

function validateLightTerminalPalettes() {
  const background = "#F1ECEC";
  let pairs = 0;

  const alacritty = readFileSync(join(root, "alacritty/opencode-light.toml"), "utf8");
  const alacrittyTextColors = [...alacritty.matchAll(
    /^\s*(?:foreground|black|red|green|yellow|blue|magenta|cyan|white)\s*=\s*["'](0x[0-9a-f]{6})["']/gim,
  )].map((match) => match[1].replace(/^0x/i, "#"));
  pairs += validateColorList("Alacritty light palette", alacrittyTextColors, background);

  const ghostty = readFileSync(join(root, "terminals/ghostty/opencode-light"), "utf8");
  const ghosttyTextColors = [...ghostty.matchAll(
    /^\s*(?:foreground|palette)\s*=\s*(?:\d+=)?([0-9a-f]{6})\s*$/gim,
  )].map((match) => `#${match[1]}`);
  pairs += validateColorList("Ghostty light palette", ghosttyTextColors, background);

  const kitty = readFileSync(join(root, "terminals/kitty/opencode-light.conf"), "utf8");
  const kittyTextColors = [...kitty.matchAll(
    /^\s*(?:foreground|color\d+)\s+#([0-9a-f]{6})\s*$/gim,
  )].map((match) => `#${match[1]}`);
  pairs += validateColorList("Kitty light palette", kittyTextColors, background);

  const wezterm = readFileSync(join(root, "terminals/wezterm/opencode-light.lua"), "utf8");
  const weztermTextColors = [];
  for (const blockName of ["ansi", "brights"]) {
    const block = wezterm.match(new RegExp(`${blockName}\\s*=\\s*\\{([\\s\\S]*?)\\}`));
    assert.ok(block, `WezTerm light: missing ${blockName} block`);
    weztermTextColors.push(...colorsFromText(block[1]));
  }
  pairs += validateColorList("WezTerm light palette", weztermTextColors, background);

  const konsole = readFileSync(join(root, "konsole/OpenCodeLight.colorscheme"), "utf8");
  let section = "";
  const konsoleTextColors = [];
  for (const line of konsole.split("\n")) {
    const heading = line.match(/^\[([^\]]+)\]$/);
    if (heading) section = heading[1];
    const color = line.match(/^Color=(\d+),(\d+),(\d+)$/);
    if (color && (/^Color[0-7](?:Intense)?$/.test(section) || /^Foreground/.test(section))) {
      konsoleTextColors.push(
        `#${color.slice(1).map((channel) => Number(channel).toString(16).padStart(2, "0")).join("")}`,
      );
    }
  }
  pairs += validateColorList("Konsole light palette", konsoleTextColors, background);

  const starship = readFileSync(join(root, "starship/opencode-light.toml"), "utf8");
  const starshipTextColors = [];
  for (const line of starship.split("\n")) {
    if (/^(?:success_symbol|error_symbol|vimcmd_symbol|style(?:_user|_root)?)\s*=/.test(line.trim())) {
      starshipTextColors.push(...colorsFromText(line));
    }
  }
  pairs += validateColorList("Starship light palette", starshipTextColors, background);
  return { files: 6, pairs };
}

function parseKdeColorScheme(relativePath) {
  const content = readFileSync(join(root, relativePath), "utf8");
  const sections = new Map();
  let section;
  for (const line of content.split("\n")) {
    const heading = line.match(/^\[([^\]]+(?:\]\[[^\]]+)?)\]$/);
    if (heading) {
      section = heading[1];
      sections.set(section, new Map());
      continue;
    }
    const assignment = line.match(/^([^=]+)=(\d+),(\d+),(\d+)$/);
    if (section && assignment) {
      const hex = `#${assignment.slice(2).map((channel) => Number(channel).toString(16).padStart(2, "0")).join("")}`;
      sections.get(section).set(assignment[1], hex);
    }
  }
  return sections;
}

function validateKdeLightSchemes() {
  const files = [
    "colors/OpenCodeLight.colors",
    "desktoptheme/opencode-light/colors",
    "lookandfeel/com.kim.opencode-light/contents/colorschemes/OpenCodeLight.colors",
  ];
  const canonical = readFileSync(join(root, files[0]), "utf8");
  let pairs = 0;
  const foregroundRoles = [
    "ForegroundNormal",
    "ForegroundActive",
    "ForegroundLink",
    "ForegroundNegative",
    "ForegroundNeutral",
    "ForegroundPositive",
    "ForegroundVisited",
  ];
  for (const file of files) {
    assert.equal(readFileSync(join(root, file), "utf8"), canonical, `${file}: light KDE palette drift`);
    const sections = parseKdeColorScheme(file);
    for (const [name, values] of sections) {
      if (!name.startsWith("Colors:")) continue;
      const background = values.get("BackgroundNormal");
      assert.ok(background, `${file}: ${name} missing BackgroundNormal`);
      for (const role of foregroundRoles) {
        const foreground = values.get(role);
        assert.ok(foreground, `${file}: ${name} missing ${role}`);
        assertContrast(`${file}: ${name} ${role}`, foreground, background);
        pairs += 1;
      }
    }
  }
  return { files: files.length, pairs };
}

function validateComponentMetadata(requiredVersion) {
  const metadataFiles = [
    "wallpaper/OpenCode/metadata.json",
    "lookandfeel/com.kim.opencode-dark/metadata.json",
    "lookandfeel/com.kim.opencode-light/metadata.json",
    "desktoptheme/opencode-dark/metadata.json",
    "desktoptheme/opencode-light/metadata.json",
    "splash/com.kim.opencode-splash/metadata.json",
  ];
  for (const file of metadataFiles) {
    const metadata = readJson(file);
    assert.equal(
      metadata.KPlugin?.Version,
      requiredVersion,
      `${file}: version must match VERSION`,
    );
  }
  const wallpaper = readJson("wallpaper/OpenCode/metadata.json");
  assert.equal(
    wallpaper.KPackageStructure,
    "Wallpaper/Images",
    "wallpaper must use the static image package structure",
  );
  return metadataFiles.length;
}

export function validateRepository() {
  const requiredVersion = readFileSync(join(root, "VERSION"), "utf8").trim();
  const vscodePackage = readJson("vscode/package.json");
  assert.equal(vscodePackage.version, requiredVersion, "VS Code version must match VERSION");
  const vsixManifest = readFileSync(
    join(root, "vscode/extension.vsixmanifest"),
    "utf8",
  );
  const manifestIdentity = vsixManifest.match(
    /<Identity\s+[^>]*Id="([^"]+)"[^>]*Version="([^"]+)"[^>]*Publisher="([^"]+)"/,
  );
  assert.ok(manifestIdentity, "VSIX manifest Identity is missing or malformed");
  assert.equal(manifestIdentity[1], vscodePackage.name, "VSIX identity must match package name");
  assert.equal(manifestIdentity[2], requiredVersion, "VSIX version must match VERSION");
  assert.equal(manifestIdentity[3], vscodePackage.publisher, "VSIX publisher must match package");

  validateGhostty("terminals/ghostty/opencode-dark");
  const contrastPairs =
    validateVsCodeTheme("vscode/themes/opencode-dark.json") +
    validateVsCodeTheme("vscode/themes/opencode-light.json") +
    validateTerminalSelections();
  const terminalPalettes = validateLightTerminalPalettes();
  const kdeSchemes = validateKdeLightSchemes();
  const metadataFiles = validateComponentMetadata(requiredVersion);
  return {
    files: 6 + metadataFiles + terminalPalettes.files + kdeSchemes.files,
    contrastPairs: contrastPairs + terminalPalettes.pairs + kdeSchemes.pairs,
  };
}

if (process.argv[1] && fileURLToPath(import.meta.url) === process.argv[1]) {
  try {
    const result = validateRepository();
    console.log(
      `Theme validation passed: ${result.files} files, ${result.contrastPairs} contrast pairs`,
    );
  } catch (error) {
    console.error(`Theme validation failed: ${error.message}`);
    process.exitCode = 1;
  }
}
