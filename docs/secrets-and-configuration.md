# Secrets And Configuration

## Purpose

This document describes how configuration is split between `.env`, Docker Swarm secrets, and the optional `config/config.yml`.

## Relevant Files

- `.env.example`
- `config/config.yml.example`
- `docker/docker-compose.dev.yml`
- `docker/docker-compose.prod.yml`
- `docker/deploy.sh`

## Local Configuration

- local Compose reads values directly from `.env`
- `docker/docker-compose.dev.yml` passes `VIKUNJA_SERVICE_SECRET` and `VIKUNJA_DATABASE_PASSWORD` directly as environment variables
- optional mailer credentials also come directly from `.env` in local mode
- `.env` is git-ignored and should stay local to the machine

## Production Configuration

- the production `.env` lives on the server and is never committed
- the deploy workflow locates that env file from the `DEPLOY_PATH` GitHub secret
- `docker/deploy.sh` loads the server `.env`, validates required values, and creates external Swarm secrets
- `docker/docker-compose.prod.yml` consumes those secrets with `*_FILE` variables
- `VIKUNJA_IMAGE` stays in `.env` as the base image reference, and the deploy workflow overwrites it in a temporary env file on the server for each rollout

## Required Variables

- `VIKUNJA_PUBLIC_URL`
- `VIKUNJA_DOMAIN`
- `VIKUNJA_IMAGE`
- `VIKUNJA_SERVER_PATH`
- `VIKUNJA_FILES_PATH`
- `VIKUNJA_BACKUPS_PATH`
- `VIKUNJA_SECRET`
- `VIKUNJA_DB_PASSWORD`
- `TRAEFIK_PUBLIC_NETWORK`
- `TRAEFIK_PROXY_CIDR`

## Mailer Variables

- `VIKUNJA_MAILER_ENABLED`
- `VIKUNJA_MAILER_HOST`
- `VIKUNJA_MAILER_PORT`
- `VIKUNJA_MAILER_AUTHTYPE`
- `VIKUNJA_MAILER_USERNAME`
- `VIKUNJA_MAILER_PASSWORD`
- `VIKUNJA_MAILER_FROMEMAIL`

If `VIKUNJA_MAILER_ENABLED=true`, `docker/deploy.sh` requires the host, username, and password values.

## Secret Rotation Model

- secret names are derived from the content hash of the value
- unchanged values reuse existing Swarm secret objects
- changed values create new secret names without mutating in-use secrets
- examples include `vikunja_service_secret_<hash>` and `vikunja_db_password_<hash>`

## Paths And Networking Values

- `VIKUNJA_SERVER_PATH`
- `VIKUNJA_FILES_PATH`
- `VIKUNJA_BACKUPS_PATH`
- `TRAEFIK_PUBLIC_NETWORK`
- `TRAEFIK_PROXY_CIDR`

See `.env.example` for placeholder values.

## Optional `config.yml`

Use `config/config.yml.example` only when Vikunja needs nested configuration that is awkward or impossible to express cleanly with environment variables, such as OpenID Connect providers.

If you add a real `config/config.yml`, keep it out of git and mount it to `/etc/vikunja/config.yml`.

## Safety Rules

- never commit `.env`
- never commit `config/config.yml`
- keep placeholder values from `.env.example` out of the server `.env`; `docker/deploy.sh` rejects known example values
- if you use web signup for bootstrap, change `VIKUNJA_ENABLE_REGISTRATION` to `false` immediately after the first production user account exists
- if you use CLI bootstrap, keep `VIKUNJA_ENABLE_REGISTRATION=false` from the start
- keep docs in sync when env vars, secret names, or paths change

## Related Docs

- `docs/production-deployment.md`
- `docs/ci-cd.md`
- `docs/backups-restore-rollback.md`
