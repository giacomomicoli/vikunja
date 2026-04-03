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
- manual `workflow_dispatch` runs

Flow:

1. Check out the repo.
2. Read `VIKUNJA_VERSION` from `.env.example`.
3. Log in to `ghcr.io`.
4. Mirror `vikunja/vikunja:${VIKUNJA_VERSION}` to GHCR tags `latest`, `${VIKUNJA_VERSION}`, and `${GITHUB_SHA}`.
5. Derive the remote deploy root from the `DEPLOY_PATH` GitHub secret.
6. SSH to the remote deployment host and create the deploy directory.
7. Copy the tracked deployment files to the server.
8. Log in to `ghcr.io` on the server.
9. Write `VIKUNJA_IMAGE=ghcr.io/<owner>/vikunja:<deploy-tag>` into a temporary env file next to the server `.env`.
10. Run `bash docker/deploy.sh`.

`<deploy-tag>` is `${GITHUB_SHA}` for push-triggered deploys, or the optional `image_tag` workflow input for rollback and re-deploy operations.

## Required GitHub Secrets

- `VPS_HOST`
- `VPS_USER`
- `VPS_SSH_KEY`
- `DEPLOY_PATH` pointing to the server `.env` file or its parent directory

`GITHUB_TOKEN` is provided by GitHub Actions and is used for GHCR authentication.

## Operational Notes

- push-triggered production deploys are tied to the same repo commit that triggered the workflow
- the deploy workflow does not rely on a server-side git checkout
- the long-lived server `.env` stays on the host and is never copied back into the repo
- rollbacks should be handled by running `workflow_dispatch` with the `image_tag` input set to a known-good GHCR tag

## Related Docs

- `docs/architecture.md`
- `docs/production-deployment.md`
- `docs/backups-restore-rollback.md`
