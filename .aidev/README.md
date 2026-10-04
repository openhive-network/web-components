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

## The test runtime image (`runtime/`)

The suites run in a container with `--network none` and your uid. The image is built on CI's emsdk image `5.0.2-4` (the
one `.gitlab-ci.yml`'s common-ci-configuration ref names) and carries its Node 24.21.0, pnpm (from package.json
`packageManager`, through corepack) and a pnpm store filled with `pnpm fetch`. `pnpm-deps.sh` installs `node_modules`
offline from it.

When `pnpm-lock.yaml`, `pnpm-workspace.yaml`, `packageManager` or `runtime/Dockerfile` change, rebuild and re-pin **in
the same commit**:

```bash
.aidev/runtime/build.sh --push   # registry digest if aidev-<input hash> exists, else build + push
# put the printed repo@sha256:<digest> into project.yaml environment.image
```

Run a suite by hand the same way AIDEV does:

```bash
docker run --rm --network none --user "$(id -u):$(id -g)" -e HOME=/tmp \
  -v "$PWD":/work -w /work <environment.image> .aidev/run-checks.sh quick lint format build typecheck
```
