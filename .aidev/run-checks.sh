#!/usr/bin/env bash
# The checks AIDEV's verification slots run (.aidev/project.yaml), as one junit
# report per suite: each named step is a test case, its log the failure body.
#
#   .aidev/run-checks.sh <suite> <step>...     steps: lint format build typecheck
#
#   lint       ESLint with --max-warnings 0 (package.json `lint:ci`, CI's lint job)
#   format     Prettier --check (package.json `format:ci`, CI's lint job)
#   build      what `pnpm build` (CI's build job) runs after its `prebuild`:
#              every workspace package's `vite build`, then the root bundle;
#              then the files the root and each package's `main` / `types` /
#              `exports` name must exist in dist/. `prebuild` (ls-engines,
#              husky) is left out: ls-engines downloads
#              nodejs.org/dist/index.json, and the suites run without network
#   typecheck  `tsc --noEmit` per workspace package. Packages import each other
#              through their built declarations, so it builds first when
#              packages/internal/dist is missing
set -uo pipefail
cd "$(dirname "$0")/.."

suite="${1:?usage: $0 <suite> <step>...}"; shift
out="test-results/$suite"
rm -rf "$out"; mkdir -p "$out"
cases="$out/cases.tsv"; : > "$cases"

# shellcheck source=pnpm-deps.sh
if ! source .aidev/pnpm-deps.sh; then
    printf 'case\tinstall\tfail\t0\tpnpm install --offline failed\n' >> "$cases"
    source .aidev/junit-helpers.sh; junit_write_cases "$out/junit.xml" "$suite" "$cases"
    exit 1
fi
source .aidev/junit-helpers.sh

status=0
step() {
    local name="$1"; shift
    local log="$out/$name.log" t0=$SECONDS rc=0
    echo "== $name" >&2
    "$@" > "$log" 2>&1 < /dev/null || rc=$?
    if [ "$rc" -eq 0 ]; then
        printf 'case\t%s\tpass\t%s\t\n' "$name" "$((SECONDS - t0))" >> "$cases"
    else
        status=1; tail -40 "$log" >&2
        printf 'case\t%s\tfail\t%s\texit %s\t%s\n' "$name" "$((SECONDS - t0))" "$rc" "$log" >> "$cases"
    fi
    return "$rc"
}

# The files the root package's and every workspace package's package.json
# `main` / `types` / `exports` name.
check_dist() {
    node -e '
const fs = require("fs");
const path = require("path");
const missing = [];
const found = [];
for (const root of [".", ...fs.readdirSync("packages").map((dir) => path.join("packages", dir))]) {
  const pkg = JSON.parse(fs.readFileSync(path.join(root, "package.json"), "utf8"));
  const want = [pkg.main, pkg.types, ...Object.values(pkg.exports || {}).flatMap((e) => typeof e === "string" ? [e] : Object.values(e))];
  for (const f of new Set(want.filter(Boolean).map((f) => path.join(root, f)))) (fs.existsSync(f) ? found : missing).push(f);
}
if (missing.length) { console.error("missing from the build:", missing.join(", ")); process.exit(1); }
console.log("dist provides", found.join(", "));'
}

typecheck() {
    local p rc=0
    for p in packages/*/; do
        echo "-- tsc --noEmit -p $p"
        pnpm exec tsc --noEmit -p "$p" || rc=1
    done
    return "$rc"
}

built=0
build() {
    [ "$built" -eq 0 ] || return 0
    step build bash -c 'pnpm -r run build && pnpm exec vite build' && built=1 && step dist-exports check_dist
}

for s in "$@"; do
    case "$s" in
        lint) step lint pnpm run lint:ci ;;
        format) step format pnpm run format:ci ;;
        build) build ;;
        typecheck)
            if [ "$built" -eq 0 ] && [ ! -f packages/internal/dist/index.d.ts ]; then build; fi
            step typecheck typecheck ;;
        *) echo "unknown step: $s" >&2; exit 2 ;;
    esac
done
junit_write_cases "$out/junit.xml" "$suite" "$cases"
exit "$status"
