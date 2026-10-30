# Sourced by the .aidev suite scripts: make node_modules match pnpm-lock.yaml,
# offline, from the pnpm store at /opt/pnpm-store. A marker records the lockfile
# and Node it was installed for; it is written only after an install that
# succeeded, and an install whose tools don't resolve is redone.
#
# The store is `environment.packages.store` in project.yaml: the host store
# mounted read-only on the shared route, baked into the fallback image. The
# shared image sets none of this environment, and the suites run with the
# caller's uid and no network, so it is exported here for every step.
export npm_config_store_dir=/opt/pnpm-store
export HUSKY=0
export DO_NOT_TRACK=1
if [ -z "${HOME:-}" ] || [ ! -d "$HOME" ] || [ ! -w "$HOME" ]; then
    export HOME=/tmp
fi
lock_id="$(sha256sum pnpm-lock.yaml | cut -d' ' -f1) $(node --version)"
marker=node_modules/.aidev-pnpm-lock
tools_present() {
    local t
    for t in vite tsc eslint prettier; do [ -x "node_modules/.bin/$t" ] || return 1; done
}
if [ "$(cat "$marker" 2>/dev/null)" != "$lock_id" ] || ! tools_present; then
    echo "node_modules is not current for pnpm-lock.yaml: pnpm install --offline" >&2
    pnpm install --offline --frozen-lockfile --store-dir "$npm_config_store_dir" < /dev/null || return 1
    tools_present || { echo "pnpm install left no vite/tsc/eslint/prettier" >&2; return 1; }
    printf '%s\n' "$lock_id" > "$marker.tmp" && mv "$marker.tmp" "$marker"
fi
