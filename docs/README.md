# Documentation

Detailed project documentation lives in `docs/` so each file stays focused, current, and easy to load into context.

`README.md` is the human-facing entrypoint for new users. The files in `docs/` are optimized for maintainers and coding agents.

Each document should cover one area of the project and stay below `250` Markdown lines. See `docs/documentation-guidelines.md` for the maintenance rules.

## Start Here

- `README.md` for the repo overview and quick start
- `docs/architecture.md` for the deployment model and system boundaries
- `docs/local-development.md` for local Compose usage and validation
- `docs/production-deployment.md` for the Swarm deployment flow and live checks
- `docs/ci-cd.md` for GitHub Actions and GHCR promotion
- `docs/secrets-and-configuration.md` for `.env`, Swarm secrets, and optional `config.yml`
- `docs/backups-restore-rollback.md` for backup, restore, and rollback runbooks
- `docs/documentation-guidelines.md` for the documentation policy

## Source Of Truth

- Real commands must match `Makefile`, `.github/workflows/*.yml`, `docker/*`, and `.env.example`
- If a document conflicts with implementation, update the document in the same change
- Root-level docs stay short and point to the focused documents in `docs/`
