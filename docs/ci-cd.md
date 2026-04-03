# CI/CD

## Purpose

This repo validates configuration changes on every active branch push and deploys production from `main`.

## Relevant Files

- `.github/workflows/ci.yml`
- `.github/workflows/deploy.yml`
- `.env.example`
- `docker/deploy.sh`

## CI Workflow

Trigger scope:

- pushes to `dev`, `release`, and `main`
- pull requests targeting `dev`, `release`, and `main`

Current jobs:

- `compose-config` renders the dev and prod Compose configs
- `shellcheck` lints `docker/deploy.sh`

Current CI scope:

- validates configuration syntax
- validates the deploy script with `shellcheck`
- does not start containers or run live HTTP or CalDAV smoke tests

## Deploy Workflow

Trigger scope:

- pushes to `main`

Flow:

1. Check out the repo.
2. Read `VIKUNJA_VERSION` from `.env.example`.
3. Log in to `ghcr.io`.
4. Mirror `vikunja/vikunja:${VIKUNJA_VERSION}` to GHCR tags `latest`, `${VIKUNJA_VERSION}`, and `${GITHUB_SHA}`.
5. SSH to the remote deployment host.
6. Log in to `ghcr.io` on the server.
7. Reset the server checkout to `origin/main`.
8. Export `VIKUNJA_IMAGE=ghcr.io/<owner>/vikunja:${GITHUB_SHA}`.
9. Run `bash docker/deploy.sh`.

## Required GitHub Secrets

- `VPS_HOST`
- `VPS_USER`
- `VPS_SSH_KEY`

Optional repository variables:

- `DEPLOY_PATH` for the remote checkout location used by the deploy workflow

`GITHUB_TOKEN` is provided by GitHub Actions and is used for GHCR authentication.

## Operational Notes

- production deploys are tied to the same repo commit that triggered the workflow
- manual production deploys are still possible with `make prod-deploy`
- the deploy workflow hard-resets the server checkout before deploying
- manual rollbacks can override `VIKUNJA_IMAGE` and reuse the same deploy script

## Related Docs

- `docs/architecture.md`
- `docs/production-deployment.md`
- `docs/backups-restore-rollback.md`
