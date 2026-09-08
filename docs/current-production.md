# Current production

Verified on 2026-09-08. DNS and application cutover completed on 2026-09-08.
The old VM and obsolete traefik.fakejack.dev DNS record were deleted after
verification and explicit confirmation.

## Historical source (VM deleted)

- Historical SSH alias: `vikunja-server`, user ubuntu, IP 83.228.225.233.
  Do not use this alias for live operations.
- Hostname: `opencloud-server`.
- `ssh opencloud` points to 91.99.20.92, an unrelated blog server.
- Swarm service `vikunja_app`, image `vikunja/vikunja:2.3.0`.
- SQLite: `/opt/stacks/vikunja/db/vikunja.db`, including live WAL.
- Attachments: `/opt/stacks/vikunja/files`.
- Source was frozen before final snapshot, then the VM was deleted.
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

## Retirement and recovery

Source VM 61ed946c-4fe3-46c4-91bc-6ea13d98780b was deleted on 2026-09-08.
The shared opencloud_server keypair, netdata-parent, and unrelated opencloud
host were preserved. Recovery to another VM requires a new host and backup.

Final archive and integrity manifests are retained under
`/opt/mcp-gateway/backups` on the gateway and
`/home/jack/.local/share/mcp-gateway-backups` on the workstation.
See the gateway runbook for checksums and the full migration evidence.
