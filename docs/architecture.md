# Architecture

## Purpose

This repo deploys vendor-provided Vikunja with one shared configuration base across two runtimes:

- local validation with Docker Compose
- production deployment with Docker Swarm
- Traefik TLS termination on the external network named by `TRAEFIK_PUBLIC_NETWORK`
- GHCR as the promotion boundary for approved images

There is no custom application build in this repository. The repo owns configuration, promotion, and deployment.

## Relevant Files

- `docker/docker-compose.yml`
- `docker/docker-compose.dev.yml`
- `docker/docker-compose.prod.yml`
- `docker/deploy.sh`
- `.github/workflows/deploy.yml`

## Runtime Model

### Local

- runs with `docker compose`
- overrides `vikunja-net` to `bridge`
- publishes `3456:3456`
- mounts repo-local `files/`
- reads secrets directly from `.env`

### Production

- runs with `docker stack deploy`
- keeps `vikunja-net` as an internal overlay network
- attaches Vikunja to the external Traefik network
- exposes Traefik labels through `deploy.labels`
- publishes no direct host ports for Vikunja
- injects secrets through Docker Swarm secrets and `*_FILE` variables
- receives tracked deployment files from GitHub Actions instead of relying on a server-side git checkout

## Why The Base Compose File Stays Minimal

`docker/docker-compose.yml` contains only the settings that are valid in both local and production modes:

- shared image reference
- shared Vikunja and PostgreSQL settings
- the named database volume
- internal network wiring

It intentionally does not contain ports, bind mounts, local-only startup ordering, or Swarm-only Traefik labels.

## Networking

- `vikunja-net` keeps application and database traffic private
- local overrides `vikunja-net` to `bridge`
- production uses `vikunja-net` as `overlay` and `attachable`
- the external Traefik-facing network name comes from `TRAEFIK_PUBLIC_NETWORK`
- production sets `VIKUNJA_SERVICE_IPEXTRACTIONMETHOD=xff`
- production trusts `TRAEFIK_PROXY_CIDR`

## Storage

- database engine: PostgreSQL `16`
- database service: `vikunja-db`
- database volume: `vikunja-db-data`
- database path: `/var/lib/postgresql/data`
- local files path: `./files`
- production files path comes from `VIKUNJA_FILES_PATH`
- container files path: `/app/vikunja/files`

## Promotion Flow

1. Validate the repo configuration locally.
2. Push to `main`.
3. GitHub Actions mirrors `vikunja/vikunja:${VIKUNJA_VERSION}` to `ghcr.io/<owner>/vikunja`.
4. The deploy workflow derives the remote deploy root from the `DEPLOY_PATH` secret and syncs the tracked deployment files to that directory.
5. The deploy workflow writes `VIKUNJA_IMAGE=ghcr.io/<owner>/vikunja:${GITHUB_SHA}` into a temporary env file on the server.
6. `docker/deploy.sh` deploys that pinned image to Swarm.

## Operational Constraints

- production placement is constrained to `node.role == manager`
- the Traefik provider suffix is `@swarm`
- the Traefik entrypoint is `https`
- the Traefik certresolver is `http`
- production publishes no direct host ports for Vikunja
- production registration is usually disabled after bootstrap, and can be skipped entirely by creating the first user via the Vikunja CLI

## Related Docs

- `docs/local-development.md`
- `docs/production-deployment.md`
- `docs/ci-cd.md`
- `docs/secrets-and-configuration.md`
