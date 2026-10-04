# Claude Code - Hive Web Components

## Project Overview

Hive Components is a reusable Web Components library for the Hive blockchain. It provides embeddable UI components for displaying posts, comments, witnesses, accounts, and tags from the Hive network. Built with TypeScript and Lit, components are framework-agnostic and work in any web application.

**Repository:** gitlab.syncad.com/hive/web-components
**Package Scope:** @hiveio
**Main Branch:** `develop` (protected)

## Tech Stack

- **TypeScript 5.0** - Strict mode with full type safety
- **Lit 3.0** - Lightweight web components framework
- **pnpm 10.13** - Monorepo workspace management
- **Vite 5.0** - Build and dev server
- **Node.js >= 24** - Runtime requirement
- **ESLint 9.28** - Linting with TypeScript plugin
- **Prettier 3.0** - Code formatting (print width 120)
- **Vitest 1.0** - Testing framework
- **Husky + lint-staged** - Pre-commit hooks

## Directory Structure

```
web-components/
├── packages/                    # Workspace packages
│   ├── internal/               # Shared utilities, types, styles, API client
│   ├── component-post/         # Hive post (header, content, footer)
│   ├── component-witness/      # Witness info display
│   ├── component-comments/     # Threaded comments
│   ├── component-account/      # Account information
│   └── component-tag/          # Tag posts listing
├── catalog/                    # Dev catalog for component testing
├── example/                    # Example implementation
├── all.ts                      # Root bundle entry point
├── vite.config.ts             # Root Vite config
├── vite.config.common.ts      # Shared Vite utilities
├── tsconfig.json              # TypeScript config
├── eslint.config.mjs          # ESLint configuration
├── .prettierrc                # Prettier config
└── .gitlab-ci.yml             # CI/CD configuration
```

## Working in an AIDEV workflow

When AIDEV runs you on an issue, no one is there to answer questions. GitLab CI doesn't run for AIDEV branches; the checks below are the verification.

- **Check your change:** run `aidev test run --slot quick` once, after your last edit. It runs ESLint (`lint:ci`, `--max-warnings 0`), Prettier (`format:ci`), `pnpm build` (every package plus the root bundle; it checks that each package's `exports`/`types` files exist in `dist/`) and `tsc --noEmit` per package.
- **Iterate:** `.aidev/run-checks.sh dev lint` (or `format` / `build` / `typecheck`) runs one step. Run `pnpm format` before committing: the Prettier check covers every file, Markdown included.
- **No tests yet:** vitest is a devDependency but there are no test files. If you add tests, add a `test` step to `.aidev/run-checks.sh` that writes junit, and bind it into `quick`/`full`.
- **Network:** the suites run with `--network none`. Don't add a check that calls the Hive API.
- **Dependencies:** a change to `pnpm-lock.yaml`, `pnpm-workspace.yaml` or `packageManager` needs a new test image. Run `.aidev/runtime/build.sh --push` and put the printed reference in `.aidev/project.yaml` `environment.image` in the same commit (see `.aidev/README.md`).

## Development Commands

```bash
# Install dependencies
pnpm install

# Build all packages
pnpm build

# Run dev catalog
pnpm catalog

# Linting
pnpm lint          # ESLint with auto-fix
pnpm lint:ci       # Strict mode (CI)

# Formatting
pnpm format        # Prettier write mode
pnpm format:ci     # Check mode (CI)

# Clean build artifacts
pnpm clean
```

## Key Files

**Configuration:**

- `tsconfig.json` - TypeScript: ES2022, strict mode, experimental decorators
- `eslint.config.mjs` - ESLint rules with TypeScript plugin
- `.prettierrc` - Formatting: double quotes, 120 width, es5 trailing commas
- `pnpm-workspace.yaml` - Workspace packages definition
- `.lintstagedrc` - Pre-commit lint configuration

**Entry Points:**

- `all.ts` - Root bundle exporting all components
- `packages/internal/src/index.ts` - Shared utilities exports
- `packages/component-*/src/index.ts` - Individual component exports

**API:**

- `packages/internal/src/hive-api.ts` - HiveApiClient with failover endpoints
- `packages/internal/src/types.ts` - TypeScript interfaces (HivePost, HiveWitness, etc.)

## Coding Conventions

### Component Pattern

All components follow this structure:

```typescript
import { LitElement, html, css } from "lit";
import { customElement, property, state } from "lit/decorators.js";
import { withHiveTheme, baseStyles, themeStyles } from "@hiveio/component-internal";

@customElement("hive-example")
export class HiveExample extends withHiveTheme(LitElement) {
  static styles = [
    baseStyles,
    themeStyles,
    css`
      /* component styles */
    `,
  ];

  @property({ type: String }) account = "";
  @state() private _loading = false;

  // Lifecycle and render methods...
}

declare global {
  interface HTMLElementTagNameMap {
    "hive-example": HiveExample;
  }
}
```

### TypeScript Rules

- Strict mode enabled with `noUnusedParameters`, `noUncheckedIndexedAccess`, `exactOptionalPropertyTypes`
- No explicit `any` types (except rest args)
- Use Lit decorators: `@property`, `@state`, `@customElement`

### Style Rules

- 2-space indentation
- Double quotes for strings
- Max line width: 120 characters
- Trailing commas: es5
- Semicolons required

### Theming

Components support `light`, `dark`, and `auto` theme modes via the `theme` attribute. CSS custom properties:

- `--hive-primary` - Primary color (Hive red)
- `--hive-surface` - Background
- `--hive-on-surface` - Text color
- `--hive-border` - Border color

## CI/CD Notes

**GitLab CI** (`.gitlab-ci.yml`):

**Stages:**

1. `.pre` - Lint (ESLint + Prettier checks)
2. `build` - Build packages, generate version info, create artifacts
3. `deploy` - Publish to GitLab npm registry or npmjs.org

**Pipeline Behavior:**

- Auto-starts on push (do not run `glab ci run` after push)
- Develop and master branches are protected
- All jobs must pass before merge

**Artifacts:**

- Built packages in `dist/`
- Modified package.json with version info

**Publishing:**

- Dev packages → GitLab npm registry
- Production → npmjs.org (public access)

## Package Structure

Each component package follows this pattern:

```json
{
  "name": "@hiveio/component-*",
  "main": "./dist/index.js",
  "types": "./dist/index.d.ts",
  "dependencies": {
    "lit": "^3.0.0",
    "@hiveio/component-internal": "workspace:*"
  }
}
```

## Available Components

| Component           | Description                                 |
| ------------------- | ------------------------------------------- |
| `hive-post`         | Full post display (header, content, footer) |
| `hive-post-header`  | Author info, avatar, reputation, title      |
| `hive-post-content` | Post body with preview mode                 |
| `hive-post-footer`  | Voting stats, comments, payout, tags        |
| `hive-comments`     | Threaded comments with configurable depth   |
| `hive-witness`      | Witness info, votes, missed blocks          |
| `hive-account`      | Account information display                 |
| `hive-tag`          | Tag posts listing with pagination           |
