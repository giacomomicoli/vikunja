SHELL := /bin/bash

COMPOSE_DEV = docker compose --project-name vikunja --env-file .env -f docker/docker-compose.yml -f docker/docker-compose.dev.yml
COMPOSE_PROD = docker compose --project-name vikunja -f docker/docker-compose.yml -f docker/docker-compose.prod.yml

.PHONY: dev dev-down dev-recreate dev-pull config-dev config-prod logs logs-app logs-db backup-db backup-files backup-all prod-deploy prod-down

dev:
	mkdir -p files backups
	$(COMPOSE_DEV) up -d

dev-down:
	$(COMPOSE_DEV) down

dev-recreate:
	$(COMPOSE_DEV) down
	$(COMPOSE_DEV) pull
	$(COMPOSE_DEV) up -d

dev-pull:
	$(COMPOSE_DEV) pull

config-dev:
	$(COMPOSE_DEV) config

config-prod:
	set -a && source .env && set +a && $(COMPOSE_PROD) config

logs:
	$(COMPOSE_DEV) logs -f

logs-app:
	$(COMPOSE_DEV) logs -f vikunja

logs-db:
	$(COMPOSE_DEV) logs -f vikunja-db

backup-db:
	mkdir -p backups
	$(COMPOSE_DEV) exec -T vikunja-db pg_dump -U vikunja vikunja | gzip > backups/vikunja_$$(date +%Y%m%d_%H%M%S).sql.gz

backup-files:
	mkdir -p backups
	tar czf backups/vikunja_files_$$(date +%Y%m%d_%H%M%S).tar.gz files/

backup-all: backup-db backup-files

prod-deploy:
	@printf '%s\n' 'Production deploys run via GitHub Actions only.'
	@exit 1

prod-down:
	docker stack rm vikunja
