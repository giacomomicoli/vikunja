# Backups, Restore, And Rollback

## Purpose

Vikunja stores operational data in PostgreSQL and the files mount. Recovery planning needs both.

## Relevant Files

- `Makefile`
- `docker/deploy.sh`
- `docker/docker-compose.dev.yml`
- `docker/docker-compose.prod.yml`

## What Must Be Backed Up

- the PostgreSQL database `vikunja`
- the attachments and avatars stored in `files/`

## Local Backup Commands

- `make backup-db`
- `make backup-files`
- `make backup-all`

## Production Backup Commands

```bash
set -a && source .env && set +a
mkdir -p "$VIKUNJA_BACKUPS_PATH"
docker exec "$(docker ps -q -f label=com.docker.swarm.service.name=vikunja_vikunja-db)" \
  pg_dump -U vikunja vikunja | gzip > "$VIKUNJA_BACKUPS_PATH/vikunja_$(date +%Y%m%d_%H%M%S).sql.gz"

tar czf "$VIKUNJA_BACKUPS_PATH/vikunja_files_$(date +%Y%m%d_%H%M%S).tar.gz" -C "$(dirname "$VIKUNJA_FILES_PATH")" "$(basename "$VIKUNJA_FILES_PATH")"
```

## Restore Principles

- treat restore as a maintenance operation
- take a fresh backup of the current state before overwriting anything
- restore the database and files from the same point in time
- validate login, projects, attachments, and CalDAV after recovery

## Production Restore Runbook

1. Take a fresh backup of the current production state.
2. Scale the app down with `docker service scale vikunja_vikunja=0`.
3. Capture the database container id with `DB_CONTAINER="$(docker ps -q -f label=com.docker.swarm.service.name=vikunja_vikunja-db)"`.
4. Recreate the database and import the dump:

```bash
docker exec "$DB_CONTAINER" dropdb -U vikunja --if-exists vikunja
docker exec "$DB_CONTAINER" createdb -U vikunja vikunja
gunzip -c "$VIKUNJA_BACKUPS_PATH/vikunja_YYYYMMDD_HHMMSS.sql.gz" | \
  docker exec -i "$DB_CONTAINER" psql -U vikunja -d vikunja
```

5. Inspect the matching file archive with `tar tzf` and extract it back to the original parent path.
6. Scale the app back up with `docker service scale vikunja_vikunja=1`.
7. Run the checks from `docs/production-deployment.md`.

## Rollback Runbook

1. Identify a known-good GHCR tag, ideally a previous commit SHA tag from the deploy workflow.
2. Export `VIKUNJA_IMAGE=ghcr.io/<owner>/vikunja:<known-good-tag>` in the deployment shell.
3. Run `bash docker/deploy.sh`.
4. Verify the stack, HTTPS routing, login, and attachments.
5. Remove the temporary image override when you are ready to return to the default image selection.

## Rollback Guardrails

- image rollback does not roll back user data on its own
- database compatibility must be considered before rolling back across versions
- if the older image is not schema-compatible, restore matching database and files backups too

## Related Docs

- `docs/production-deployment.md`
- `docs/ci-cd.md`
- `docs/secrets-and-configuration.md`
