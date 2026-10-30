# web-components under AIDEV

AIDEV verifies changes to these web components through the slots in `project.yaml`, integrates them into
`aidev/integration`, and people merge that into `develop` through merge requests (as in hive/denser). GitLab CI doesn't
run for AIDEV branches; see `.gitlab-ci.yml` `workflow:`.

## Suites

`.aidev/run-checks.sh <suite> <step>...` runs the named steps and writes `test-results/<suite>/junit.xml`, one test case
per step, with the step's log tail as the failure body.

| Step           | What                                                                                                |
| -------------- | --------------------------------------------------------------------------------------------------- |
| `lint`         | ESLint, `--max-warnings 0` (package.json `lint:ci`, CI's `lint` job)                                |
| `format`       | `prettier --check .` (package.json `format:ci`, CI's `lint` job)                                    |
| `build`        | `pnpm -r run build && vite build`: every workspace package, then the root bundle (CI's `build` job) |
| `dist-exports` | (after `build`) the files each package's `main`/`types`/`exports` name, and `dist/index.js`, exist  |
| `typecheck`    | `tsc --noEmit -p packages/<name>` for each package (builds first: packages import built `.d.ts`)    |

| Slot                       | Steps                          |
| -------------------------- | ------------------------------ |
| quick, full, canary        | lint, format, build, typecheck |
| static                     | lint, format, typecheck        |
| baseline, coverage, system | build                          |

`build` leaves out `pnpm build`'s `prebuild` script (`ls-engines && husky`): ls-engines downloads
`nodejs.org/dist/index.json`, and the suites run without network.

The project has no tests yet (vitest is a devDependency with no test files), so `coverage` measures nothing. Adding tests
and a `test` step that writes junit is the first thing to bind into `quick`/`full`.

## Test runtime

The suites run in a container with `--network none` and your uid. `environment` in `project.yaml` is `kind: shared`
(aidev's `docs/operations/shared-test-images.md`): the suites run in common-ci-configuration's `node-test-tools:develop`
(the node and pnpm versions ccc's `docker-bake.hcl` sets, the same ones its emsdk CI image carries; without emscripten:
this project builds no wasm), which aidev pins to one digest per workflow, so a ccc update reaches this project without a
rebuild here. Packages come from a host-level pnpm store that aidev fills from `pnpm-lock.yaml` with the declared `fetch`
(with network), proves with the declared `install` (offline), and mounts read-only at `/opt/pnpm-store` for the suites.
`pnpm-deps.sh` installs `node_modules` offline from it. A change to `package.json` or `pnpm-lock.yaml` needs no image
build or re-pin for the shared route.

The shared image sets no environment for this project, so `pnpm-deps.sh` exports what the steps need:
`npm_config_store_dir=/opt/pnpm-store`, `HUSKY=0`, `DO_NOT_TRACK=1`, and `HOME=/tmp` when `HOME` is unset or not
writable.

Run a suite by hand the same way AIDEV does (`aidev-store` is a pnpm store filled with the declared `fetch`):

```bash
docker run --rm --network none --user "$(id -u):$(id -g)" \
  -v "$PWD":/work -w /work -v "$PWD/../aidev-store":/opt/pnpm-store:ro \
  registry.gitlab.syncad.com/hive/common-ci-configuration/node-test-tools:develop \
  .aidev/run-checks.sh quick lint format build typecheck
```

### Fallback (`runtime/`)

`environment.fallback` is the digest-pinned image `runtime/Dockerfile` builds: `node-test-tools` with a pnpm store baked
from `pnpm-lock.yaml` at the same `/opt/pnpm-store` (the fallback's store must be at `packages.store`). aidev runs it,
with a warning, only when the shared route cannot be had on a host (the tag does not resolve, the image cannot be
pulled, the store cannot be filled or proved).

The fallback is held to the lockstep rule: when `pnpm-lock.yaml`, `pnpm-workspace.yaml` or `runtime/Dockerfile` change,
either rebuild it and put the printed reference into `environment.fallback` **in the same commit**, or drop the
`fallback` line in that commit:

```bash
.aidev/runtime/build.sh --push   # registry digest if aidev-<input hash> exists, else build + push
# put the printed repo@sha256:<digest> into project.yaml environment.fallback
```

The fallback and `runtime/` are kept until the shared route has run on the hosts that serve this project; both are
dropped after that.
