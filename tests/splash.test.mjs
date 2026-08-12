import assert from "node:assert/strict";
import { existsSync, readFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { test } from "node:test";

const root = dirname(dirname(fileURLToPath(import.meta.url)));
const splashRoot = join(root, "splash/com.kim.opencode-splash/contents/splash");
const qml = readFileSync(join(splashRoot, "Splash.qml"), "utf8");
const lightWordmark = join(splashRoot, "images/wordmark-light.png");

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
