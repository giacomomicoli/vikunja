# Vikunja

Deploy Vikunja locally with Docker Compose and remotely with Docker Swarm, using one repo for local validation, production deployment, and GitHub Actions automation.

## What This Repo Includes

- a local Compose workflow at `http://localhost:3456/`
- a production Swarm deployment with Traefik labels
- a deploy script used by the production workflow
- CI validation for Compose config rendering and the deploy script
- CD that mirrors the approved upstream image to GHCR and deploys it

## Requirements

Local:

- Docker Engine
- Docker Compose

Remote:

- Docker Swarm
- an external Traefik network that your reverse proxy uses
- a production `.env` on the server

Production CI/CD:

- a GitHub repository with Actions enabled
- `VPS_HOST`, `VPS_USER`, and `VPS_SSH_KEY` GitHub secrets
- `DEPLOY_PATH` GitHub secret pointing to the server `.env` path or its parent directory

## Local Setup

1. Copy `.env.example` to `.env`.
2. Replace the example secrets and any example values you want to customize.
3. Set `VIKUNJA_ENABLE_REGISTRATION=true` in your local `.env` if you want to create the first account through the web UI.
4. Run `make dev`.
5. Open `http://localhost:3456/`.
6. Register the first user account from the login page. Vikunja does not ship with default credentials.
7. Verify CalDAV at `http://localhost:3456/dav/`.

Useful local commands:

- `make dev`
- `make dev-down`
- `make logs`
- `make logs-app`
- `make logs-db`
- `make config-dev`
- `make backup-all`

## Remote Setup

The production deployment path uses Docker Swarm plus the settings in your server-side `.env`.

Example production values:

- `VIKUNJA_PUBLIC_URL=https://vikunja.example.com/`
- `VIKUNJA_DOMAIN=vikunja.example.com`
- `VIKUNJA_SERVER_PATH=/path/to/vikunja`
- `VIKUNJA_FILES_PATH=/path/to/vikunja/files`
- `VIKUNJA_BACKUPS_PATH=/path/to/vikunja/backups`
- `TRAEFIK_PUBLIC_NETWORK=traefik-public`
- `TRAEFIK_PROXY_CIDR=<your-traefik-network-cidr>`

Typical setup flow:

1. Create your production `.env` from `.env.example` and replace the example values.
2. Place that `.env` on the server in the directory you want GitHub Actions to manage.
3. Ensure the public Traefik network exists on the Swarm host.
4. Set the `DEPLOY_PATH` GitHub secret to that `.env` path or its parent directory.
5. Push to `main` to trigger the first deploy.
6. Create the first user account.
7. Choose one bootstrap method:
8. Option A: temporarily set `VIKUNJA_ENABLE_REGISTRATION=true` in the server `.env`, push to `main`, register the first user through the web UI, then set it back to `false` and push again.
9. Option B: keep registration disabled and create the first user from the Vikunja CLI inside the running container.

Example CLI bootstrap command:

```bash
docker exec -it "$(docker ps -q -f label=com.docker.swarm.service.name=vikunja_vikunja)" \
  /app/vikunja/vikunja user create --username <username> --email <email>
```

If you omit `--password`, Vikunja prompts for it interactively.

Useful production commands:

- `make config-prod`
- `docker stack services vikunja`
- `docker stack ps vikunja`
- `docker service inspect vikunja_vikunja`

There are no default Vikunja credentials. The first login requires a user you register or create yourself.

## Production CI/CD

- `.github/workflows/ci.yml` validates Compose rendering and lints `docker/deploy.sh`
- `.github/workflows/deploy.yml` triggers on pushes to `main` and supports `workflow_dispatch` with an `image_tag` input for rollback or re-deploy
- the deploy workflow mirrors the approved upstream image to GHCR, syncs the tracked deployment files to the server, and runs `bash docker/deploy.sh` against the server `.env`

## Maintainer Docs

The root `README.md` is the user-facing entrypoint. The detailed docs in `docs/` are organized for maintainers and coding agents.

- `docs/README.md`
- `docs/architecture.md`
- `docs/local-development.md`
- `docs/production-deployment.md`
- `docs/ci-cd.md`
- `docs/secrets-and-configuration.md`
- `docs/backups-restore-rollback.md`
- `docs/documentation-guidelines.md`
