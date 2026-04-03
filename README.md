# Vikunja

Deploy Vikunja locally with Docker Compose and remotely with Docker Swarm, using one repo for local validation, production deployment, and optional GitHub Actions automation.

## What This Repo Includes

- a local Compose workflow at `http://localhost:3456/`
- a production Swarm deployment with Traefik labels
- a deploy script for remote rollouts
- CI validation for Compose config rendering and the deploy script
- optional CD that mirrors the approved upstream image to GHCR and deploys it

## Requirements

Local:

- Docker Engine
- Docker Compose

Remote:

- Docker Swarm
- an external Traefik network that your reverse proxy uses
- a server checkout of this repo with a production `.env`

Optional CI/CD:

- a GitHub repository with Actions enabled
- `VPS_HOST`, `VPS_USER`, and `VPS_SSH_KEY` GitHub secrets
- optional `DEPLOY_PATH` GitHub repository variable if the server checkout is not at the default path used by the workflow

## Local Setup

1. Copy `.env.example` to `.env`.
2. Replace the example secrets and any example values you want to customize.
3. Run `make dev`.
4. Open `http://localhost:3456/`.
5. Register the first user account from the login page. Vikunja does not ship with default credentials.
6. Verify CalDAV at `http://localhost:3456/dav/`.

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
- `VIKUNJA_SERVER_PATH=/srv/vikunja`
- `TRAEFIK_PUBLIC_NETWORK=traefik-public`
- `TRAEFIK_PROXY_CIDR=<your-traefik-network-cidr>`

Typical setup flow:

1. Create your production `.env` from `.env.example` and replace the example values.
2. Copy the repo to your server checkout path.
3. Ensure the public Traefik network exists on the Swarm host.
4. Run `make prod-deploy` on the server.
5. Create the first user account.
6. Choose one bootstrap method:
7. Option A: temporarily keep `VIKUNJA_ENABLE_REGISTRATION=true`, register the first user through the web UI, then set it to `false` and deploy again.
8. Option B: keep registration disabled and create the first user from the Vikunja CLI inside the running container.

Example CLI bootstrap command:

```bash
docker exec -it "$(docker ps -q -f label=com.docker.swarm.service.name=vikunja_vikunja)" \
  /app/vikunja/vikunja user create --username <username> --email <email>
```

If you omit `--password`, Vikunja prompts for it interactively.

Useful production commands:

- `make prod-deploy`
- `make config-prod`
- `docker stack services vikunja`
- `docker stack ps vikunja`
- `docker service inspect vikunja_vikunja`

There are no default Vikunja credentials. The first login requires a user you register or create yourself.

## Optional CI/CD

- `.github/workflows/ci.yml` validates Compose rendering and lints `docker/deploy.sh`
- `.github/workflows/deploy.yml` triggers on pushes to `main`
- the deploy workflow mirrors the approved upstream image to GHCR and runs `bash docker/deploy.sh` on your server

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
