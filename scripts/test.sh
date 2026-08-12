#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REQUIRE_KDE=false
case "${1:-}" in
    "") ;;
    --require-kde) REQUIRE_KDE=true ;;
    *)
        echo "Usage: $0 [--require-kde]" >&2
        exit 2
        ;;
esac

cd "$ROOT"

if ! command -v kpackagetool6 >/dev/null 2>&1; then
    if [[ "$REQUIRE_KDE" == true ]]; then
        echo "ERROR: kpackagetool6 is required for KDE package validation" >&2
        exit 1
    fi
    echo "SKIP: KDE package validation (kpackagetool6 not installed)" >&2
fi

for file in install.sh uninstall.sh scripts/*.sh tests/*.sh; do
    bash -n "$file"
done

JSON_COUNT=0
while IFS= read -r -d '' file; do
    jq empty "$file"
    JSON_COUNT=$((JSON_COUNT + 1))
done < <(find . -type f -not -path './.git/*' -name '*.json' -print0)
echo "Validated $JSON_COUNT JSON files"

# Running each test module directly retains node:test TAP output and also works
# in restricted sandboxes that disallow the test runner's worker processes.
for test_file in tests/*.test.mjs; do
    node "$test_file"
done

node scripts/validate-theme.mjs
bash tests/generators-integration.sh
bash tests/installer-integration.sh
bash tests/release-integration.sh
git diff --check

echo "All source, integration, KDE, and release checks passed"
