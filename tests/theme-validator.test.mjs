import assert from "node:assert/strict";
import { test } from "node:test";

import {
  contrastRatio,
  validateHex,
  validateRepository,
} from "../scripts/validate-theme.mjs";

const editor = "#FBF9F8";
const lightSurface = "#F1ECEC";
const accessibleLight = [
  "#8A5200",
  "#7651B5",
  "#2968C3",
  "#257A3E",
  "#7A5B00",
  "#1E6E79",
  "#B52A30",
];

test("accessible light syntax colors meet AA on editor and terminal surfaces", () => {
  for (const color of accessibleLight) {
    assert.ok(contrastRatio(color, editor) >= 4.5, `${color} on ${editor}`);
    assert.ok(
      contrastRatio(color, lightSurface) >= 4.5,
      `${color} on ${lightSurface}`,
    );
  }
});

test("Ghostty colors accept six-digit hex and reject embedded whitespace", () => {
  assert.equal(validateHex("cfc ecd"), false);
  assert.equal(validateHex("CFCECD"), true);
  assert.equal(validateHex("#cfcecd"), true);
});

test("repository theme validation succeeds", () => {
  const result = validateRepository();
  assert.ok(result.files >= 18, "all canonical palette formats are validated");
  assert.ok(result.contrastPairs >= 170, "all visible text roles are validated");
});
