# Production Deployment

## Purpose

This document covers the Swarm deployment path implemented by `docker/deploy.sh` and `.github/workflows/deploy.yml`.

## Relevant Files

- `docker/docker-compose.yml`
- `docker/docker-compose.prod.yml`
- `docker/deploy.sh`
- `.env.example`
- `.github/workflows/deploy.yml`

## Deployment Inputs

- `VIKUNJA_PUBLIC_URL`
- `VIKUNJA_DOMAIN`
- `VIKUNJA_SERVER_PATH`
- `VIKUNJA_FILES_PATH`
- `VIKUNJA_BACKUPS_PATH`
- `TRAEFIK_PUBLIC_NETWORK`
- `TRAEFIK_PROXY_CIDR`

## Server Prerequisites

- Docker Swarm is initialized on the target host
- a production `.env` exists on the target host
- the network defined by `TRAEFIK_PUBLIC_NETWORK` exists on the Swarm host
- the host can pull from `ghcr.io`
- the `DEPLOY_PATH` GitHub secret points to that `.env` file or its parent directory

## Required `.env` Values

- `VIKUNJA_PUBLIC_URL=https://vikunja.example.com/`
- `VIKUNJA_DOMAIN=vikunja.example.com`
- `VIKUNJA_IMAGE=vikunja/vikunja:2.2.2`
- `VIKUNJA_SERVER_PATH=/path/to/vikunja`
- `VIKUNJA_FILES_PATH=/path/to/vikunja/files`
- `VIKUNJA_BACKUPS_PATH=/path/to/vikunja/backups`
- `VIKUNJA_SECRET=<openssl rand -hex 32>`
- `VIKUNJA_DB_PASSWORD=<openssl rand -hex 24>`
- `VIKUNJA_ENABLE_REGISTRATION=<true for web signup bootstrap, or false if you will create the first user via CLI>`
- `VIKUNJA_MAILER_*` values if SMTP is enabled
- `TRAEFIK_PUBLIC_NETWORK=<your-public-traefik-network>`
- `TRAEFIK_PROXY_CIDR=<your-traefik-network-cidr>`

## First Deploy

1. Create the production `.env` from `.env.example`.
2. Fill in production values and strong secrets.
3. Confirm the external Traefik network exists.
4. Store `DEPLOY_PATH` as a GitHub secret that points to the server `.env` file or its parent directory.
5. Push to `main` or run the deploy workflow manually.

## First User Bootstrap

Vikunja has no default username or password.

Choose one bootstrap path:

### Option A: Temporary Web Registration

1. Set `VIKUNJA_ENABLE_REGISTRATION=true` in the production `.env`.
2. Push to `main` or run the deploy workflow manually.
3. Open the public URL and register the first user account.
4. Set `VIKUNJA_ENABLE_REGISTRATION=false` in `.env`.
5. Push to `main` or run the deploy workflow manually again.

### Option B: CLI User Creation

1. Set `VIKUNJA_ENABLE_REGISTRATION=false` in the production `.env`.
2. Push to `main` or run the deploy workflow manually.
3. Create the first user inside the running container:

```bash
docker exec -it "$(docker ps -q -f label=com.docker.swarm.service.name=vikunja_vikunja)" \
  /app/vikunja/vikunja user create --username <username> --email <email>
```

If you omit `--password`, Vikunja prompts for it interactively.

Option B is safer on public deployments because it avoids opening registration to the internet, even temporarily.

## What `docker/deploy.sh` Does

- loads the server `.env` selected by the deploy workflow
- validates the required variables
- rejects example and placeholder production values
- creates `files/` and `backups/` paths if missing
- creates or reuses content-hashed Swarm secrets
- uses the pinned `VIKUNJA_IMAGE` written by the deploy workflow into a temporary env file
- deploys with `docker stack deploy --with-registry-auth`

## Useful Commands

- `make config-prod`
- `docker stack services vikunja`
- `docker stack ps vikunja`
- `docker service inspect vikunja_vikunja`
- `docker network inspect <your-traefik-public-network>`

## Post-Deploy Checks

- `docker stack services vikunja`
- `docker network inspect <your-traefik-public-network>`
- `docker service inspect vikunja_vikunja --format '{{json .Spec.Labels}}'`
- `curl -I https://<your-vikunja-domain>/`
- `docker inspect "$(docker ps -q -f label=com.docker.swarm.service.name=vikunja_vikunja)" --format '{{range $k, $v := .NetworkSettings.Networks}}{{$k}} {{end}}'`

## Expected Outcomes

- the `vikunja` service is attached to the Traefik public network
- Traefik labels resolve to `https`, resolver `http`, and service `vikunja`
- HTTPS responds with a valid certificate
- no direct host port is published by the Vikunja service in production

## Related Docs

- `docs/architecture.md`
- `docs/ci-cd.md`
- `docs/secrets-and-configuration.md`
- `docs/backups-restore-rollback.md`
