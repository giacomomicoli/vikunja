# Current production

Verified on 2026-09-08. DNS and application cutover completed on 2026-09-08.
The old application is stopped; VM retirement is pending.

## Retired application source

- SSH alias: `vikunja-server`, user ubuntu, IP 83.228.225.233.
- Hostname: `opencloud-server`.
- `ssh opencloud` points to 91.99.20.92, an unrelated blog server.
- Swarm service `vikunja_app`, image `vikunja/vikunja:2.3.0`.
- SQLite: `/opt/stacks/vikunja/db/vikunja.db`, including live WAL.
- Attachments: `/opt/stacks/vikunja/files`.
- Source service scaled to zero before final snapshot; do not restart it.
- Public DNS now points to 84.234.30.76.
- Registration disabled; SMTP and email reminders enabled.
- This differs from the PostgreSQL 2.2.2 templates in this repository.

## Target and authoritative operations

The live application runs on 84.234.30.76 (`ssh mcp-gateway`).
Data is stored at `/opt/mcp-gateway/vikunja/{db,files}`.
Production configuration and migration scripts belong to
[mcp-gateway](https://github.com/giacomomicoli/mcp-gateway).
Read its [migration runbook](https://github.com/giacomomicoli/mcp-gateway/blob/main/docs/vikunja-migration.md)
and [ADR](https://github.com/giacomomicoli/mcp-gateway/blob/main/docs/decisions/001-cohost-vikunja.md).

The target is 84.234.30.76 with one Compose stack, Caddy, the existing
MCP stdio adapter, and a pinned Vikunja 2.3.0 application using SQLite.
No PostgreSQL conversion is part of this migration.

## Deployment ownership

Pushing this repository runs validation only. The old Deploy workflow is
manual-only and its job requires `ENABLE_LEGACY_SWARM_DEPLOY=true`.
Leave this variable unset for the migrated production instance.

Local PostgreSQL development and configuration validation remain available.
Legacy backup and restore commands using pg_dump do not back up live SQLite.
Use the gateway runbook for consistent SQLite plus attachment snapshots.

## Retirement

Do not remove the source until final integrity, HTTPS, DNS and MCP checks pass
and a verified backup exists elsewhere. Never retire the unrelated opencloud
alias or netdata-parent as part of this migration.
