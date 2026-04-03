# AGENTS.md

## Scope

This repository manages Vikunja deployment config, CI/CD, docs, and operational scripts. It does not contain a custom application build.

Make small, accurate changes to Docker Compose, Bash, GitHub Actions, env templates, and docs.

## Layout

- `Makefile`: primary command surface
- `.env.example`: canonical env template
- `docker/docker-compose.yml`: shared base config
- `docker/docker-compose.dev.yml`: local overrides
- `docker/docker-compose.prod.yml`: Swarm production overrides
- `docker/deploy.sh`: production deploy script
- `.github/workflows/ci.yml`: config validation and shell lint
- `.github/workflows/deploy.yml`: GHCR mirror and remote deploy
- `docs/`: maintainer and agent docs
- `config/config.yml.example`: optional nested config example

## Existing Rules

- No previous root `AGENTS.md` was present.
- No `.cursorrules` file was found.
- No `.cursor/rules/` directory was found.
- No `.github/copilot-instructions.md` file was found.
- Follow `docs/documentation-guidelines.md` as mandatory repo instruction.

## Source Of Truth

Trust these files in order:

1. `Makefile`
2. `docker/docker-compose*.yml`
3. `docker/deploy.sh`
4. `.github/workflows/*.yml`
5. `.env.example`
6. `docs/*.md`

If behavior changes, update docs in the same change.

## Build, Lint, And Test Commands

There is no application build step and no unit-test framework in this repo. Validation means Compose rendering, shell linting, and smoke checks.

### Main Commands

- Start local stack: `make dev`
- Stop local stack: `make dev-down`
- Recreate local stack: `make dev-recreate`
- Pull images: `make dev-pull`
- Render dev config: `make config-dev`
- Render prod config: `make config-prod`
- Tail all logs: `make logs`
- Tail app logs: `make logs-app`
- Tail db logs: `make logs-db`
- Backup db: `make backup-db`
- Backup files: `make backup-files`
- Backup both: `make backup-all`
- Remove Swarm stack: `make prod-down`

### CI Validation

- Dev Compose render:
  `docker compose --project-name vikunja --env-file .env.example -f docker/docker-compose.yml -f docker/docker-compose.dev.yml config >/dev/null`
- Prod Compose render:
  `VIKUNJA_IMAGE=ghcr.io/example/vikunja:test docker compose --project-name vikunja --env-file .env.example -f docker/docker-compose.yml -f docker/docker-compose.prod.yml config >/dev/null`
- Shell lint:
  `shellcheck docker/deploy.sh`

### Single-Test Guidance

There is no true single-test runner. Use the narrowest matching validation:

- Only dev Compose: `docker compose --project-name vikunja --env-file .env.example -f docker/docker-compose.yml -f docker/docker-compose.dev.yml config >/dev/null`
- Only prod Compose: `VIKUNJA_IMAGE=ghcr.io/example/vikunja:test docker compose --project-name vikunja --env-file .env.example -f docker/docker-compose.yml -f docker/docker-compose.prod.yml config >/dev/null`
- Only deploy script: `shellcheck docker/deploy.sh`

If a real test framework is added later, document both suite and single-test commands here.

## Validation Expectations

- For Compose changes, run at least `make config-dev`.
- For prod config or env handling changes, run `make config-prod` too.
- For `docker/deploy.sh` changes, run `shellcheck docker/deploy.sh`.
- For runtime-affecting local changes, run `make dev` and verify `http://localhost:3456/` and `/dav/`.

## Code Style

### General

- Prefer the smallest correct change.
- Preserve existing ordering and structure.
- Keep comments short and useful.
- Use ASCII unless the file already needs Unicode.
- Do not add new tooling without a clear need.

### Naming

- Env vars use uppercase snake case: `VIKUNJA_PUBLIC_URL`.
- Make targets use short hyphenated names: `dev-recreate`, `backup-all`.
- Docs filenames use lowercase hyphenated names.
- Service, network, volume, and secret names should stay explicit and stable.
- Prefer upstream Vikunja or Docker terminology over invented aliases.

### Imports And Dependencies

- There are no language-level import rules here.
- Prefer existing tools: `make`, `docker`, `docker compose`, `docker stack`, `shellcheck`.
- Do not introduce new CI dependencies or app frameworks unless repo scope changes.

### YAML

- Use two-space indentation.
- Keep related keys grouped logically.
- Keep shared settings in `docker/docker-compose.yml`.
- Put local-only behavior in `docker/docker-compose.dev.yml`.
- Put Swarm-only behavior in `docker/docker-compose.prod.yml`.
- Do not duplicate shared config into overlays unless needed.
- Preserve quoted string booleans where required, for example `"true"`.

### Bash

- Use `#!/usr/bin/env bash` and `set -euo pipefail`.
- Quote expansions unless unquoted behavior is intentional.
- Use small helper functions for repeated logic.
- Use `local` for function variables.
- Validate required env vars early.
- Print actionable error messages.
- Run `shellcheck` after edits.

### Markdown

- Keep docs short, focused, and operational.
- One topic per document.
- Files in `docs/` must stay below `250` Markdown lines.
- Prefer steps and concise bullets over long prose.
- Commands, paths, env vars, ports, and workflow names must exactly match the repo.

### Env And Config

- Keep example values obviously non-production.
- Never commit `.env` or `config/config.yml`.
- When adding a required env var, update `.env.example`, Compose usage, deploy logic, and docs together.
- Preserve the current content-hashed Docker secret rotation model in `docker/deploy.sh`.

## Contracts And Error Handling

- Be explicit with env-driven booleans and defaults.
- Preserve exact upstream env variable names expected by Vikunja.
- Keep names stable unless the rename is intentional and fully propagated.
- Fail early in scripts when required inputs are missing.
- Avoid silent fallbacks for security-sensitive settings.
- In docs, call out prerequisites and risks before destructive or production actions.

## Change Boundaries

- Keep `docker/docker-compose.yml` valid for both local and prod.
- Do not add local-only ports, bind mounts, or `depends_on` behavior to the shared base file.
- Do not add Swarm-only labels or secret-file wiring to the dev overlay.
- Do not casually change production assumptions around Traefik, `https`, `@swarm`, or disabled direct host ports.
- Production registration is usually disabled after bootstrap; preserve that model unless intentionally changing it.

## Documentation Rules

From `docs/documentation-guidelines.md`:

- `README.md` is the public entrypoint.
- Detailed docs live in `docs/`.
- Docs in `docs/` are for maintainers and coding agents.
- One topic or project area per document.
- Each document must stay below `250` Markdown lines.
- Prefer links to real source files over copying large config blocks.
- If docs conflict with implementation, update docs in the same change.

After any implementation or fix:

1. Identify what operator-visible behavior changed.
2. Search docs for affected commands, paths, env vars, ports, domains, workflow names, and filenames.
3. Update stale text in the same change.
4. Re-check examples against `Makefile`, `docker/*`, `.github/workflows/*`, and `.env.example`.
5. Confirm touched docs still stay focused and below `250` lines.

## Common Pitfalls

- Treating this as an app repo with a normal build/test pipeline.
- Changing docs without checking the exact command text in `Makefile` or workflows.
- Duplicating base Compose config into overlay files.
- Committing secrets, local config, backups, or generated artifacts.
- Renaming env vars in only one place.
- Assuming local Compose networking matches production Swarm behavior.

## Re-Check After Changes

- Compose changes: `Makefile`, overlay files, related docs
- Deploy changes: `docker/deploy.sh`, deploy/secrets docs, CI workflow
- Env changes: `.env.example`, Compose files, docs
- Workflow changes: `.github/workflows/*.yml`, `docs/ci-cd.md`
- Backup/restore changes: `docs/backups-restore-rollback.md`
