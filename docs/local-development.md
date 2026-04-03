# Local Development

## Purpose

Local Compose is the validation surface for config changes before production promotion.

## Relevant Files

- `docker/docker-compose.yml`
- `docker/docker-compose.dev.yml`
- `Makefile`
- `.env.example`

## First Run

1. Create `.env` from `.env.example`.
2. Review at least `VIKUNJA_PUBLIC_URL`, `VIKUNJA_SECRET`, and `VIKUNJA_DB_PASSWORD`.
3. Run `make dev`.
4. Open `http://localhost:3456/`.
5. Register the first user account from the login page. Vikunja has no default username or password.
6. Verify CalDAV at `http://localhost:3456/dav/`.
7. If SMTP is enabled locally, trigger a password reset to confirm mail delivery.

## What Local Mode Uses

- `docker compose`
- `bridge` networking for `vikunja-net`
- direct host port `3456:3456`
- repo-local `files/` bind mount
- direct environment variables from `.env`
- database health checks through `depends_on`

## Common Commands

- `make dev`
- `make dev-down`
- `make dev-recreate`
- `make dev-pull`
- `make logs`
- `make logs-app`
- `make logs-db`
- `make backup-db`
- `make backup-files`
- `make backup-all`
- `make config-dev`

## Local Validation Checklist

- `make config-dev` renders without errors
- the UI loads on `http://localhost:3456/`
- login works after account creation
- CalDAV responds at `/dav/`
- attachments can be uploaded into `files/`
- mail delivery works if the mailer is enabled
- app and db logs are clean enough for the change being tested

## When Local Validation Is Useful

- config changes in `docker/*`
- `.env.example` updates
- `Makefile` changes
- Vikunja version bumps that should be promoted through GHCR

## Related Docs

- `docs/architecture.md`
- `docs/production-deployment.md`
- `docs/ci-cd.md`
