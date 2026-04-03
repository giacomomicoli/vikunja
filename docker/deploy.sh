#!/usr/bin/env bash
set -euo pipefail

STACK_NAME="vikunja"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_ENV_FILE="$SCRIPT_DIR/../.env"
ENV_FILE="${VIKUNJA_ENV_FILE:-$DEFAULT_ENV_FILE}"

case "$ENV_FILE" in
  /*)
    ;;
  *)
    ENV_FILE="$SCRIPT_DIR/../$ENV_FILE"
    ;;
esac

if [ ! -f "$ENV_FILE" ]; then
  echo "Error: $ENV_FILE not found. The deploy workflow expects a prepared server-side env file."
  exit 1
fi

DEPLOY_ROOT="$(cd "$(dirname "$ENV_FILE")" && pwd)"
cd "$DEPLOY_ROOT"

set -a
# shellcheck disable=SC1090,SC1091
source "$ENV_FILE"
set +a

require_var() {
  local name="$1"

  if [ -z "${!name:-}" ]; then
    echo "Error: $name is required."
    exit 1
  fi
}

require_https_url() {
  local name="$1"
  local value="$2"

  case "$value" in
    https://*)
      ;;
    *)
      echo "Error: $name must use https:// in production."
      exit 1
      ;;
  esac
}

require_not_value() {
  local name="$1"
  local value="$2"
  local disallowed="$3"

  if [ "$value" = "$disallowed" ]; then
    echo "Error: $name still uses the example value '$disallowed'."
    exit 1
  fi
}

require_not_prefix() {
  local name="$1"
  local value="$2"
  local prefix="$3"

  case "$value" in
    "$prefix"*)
      echo "Error: $name still uses the example value prefix '$prefix'."
      exit 1
      ;;
  esac
}

is_true() {
  case "${1:-}" in
    1|true|TRUE|yes|YES|on|ON)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

secret_name_for() {
  local base="$1"
  local value="$2"
  local digest

  digest="$(printf '%s' "$value" | sha256sum | cut -c1-12)"
  printf '%s_%s' "$base" "$digest"
}

ensure_secret() {
  local base="$1"
  local value="$2"
  local name

  name="$(secret_name_for "$base" "$value")"

  if docker secret inspect "$name" >/dev/null 2>&1; then
    echo "  Reusing secret: $name" >&2
  else
    printf '%s' "$value" | docker secret create "$name" - >/dev/null
    echo "  Created secret: $name" >&2
  fi

  printf '%s' "$name"
}

require_var VIKUNJA_PUBLIC_URL
require_var VIKUNJA_DOMAIN
require_var VIKUNJA_SECRET
require_var VIKUNJA_DB_PASSWORD
require_var VIKUNJA_SERVER_PATH
require_var VIKUNJA_FILES_PATH
require_var VIKUNJA_BACKUPS_PATH
require_var TRAEFIK_PUBLIC_NETWORK
require_var TRAEFIK_PROXY_CIDR

require_https_url VIKUNJA_PUBLIC_URL "$VIKUNJA_PUBLIC_URL"
require_not_value VIKUNJA_DOMAIN "$VIKUNJA_DOMAIN" "vikunja.example.invalid"
require_not_prefix VIKUNJA_SECRET "$VIKUNJA_SECRET" "CHANGE_ME"
require_not_prefix VIKUNJA_DB_PASSWORD "$VIKUNJA_DB_PASSWORD" "CHANGE_ME"
require_not_value TRAEFIK_PROXY_CIDR "$TRAEFIK_PROXY_CIDR" "192.0.2.0/24"

if is_true "${VIKUNJA_MAILER_ENABLED:-false}"; then
  require_var VIKUNJA_MAILER_HOST
  require_var VIKUNJA_MAILER_USERNAME
  require_var VIKUNJA_MAILER_PASSWORD
fi

SERVER_PATH="$VIKUNJA_SERVER_PATH"
FILES_PATH="$VIKUNJA_FILES_PATH"
BACKUPS_PATH="$VIKUNJA_BACKUPS_PATH"
IMAGE_REF="${VIKUNJA_IMAGE:-vikunja/vikunja:${VIKUNJA_VERSION:-2.2.2}}"
MAILER_USERNAME_VALUE="${VIKUNJA_MAILER_USERNAME:-disabled}"
MAILER_PASSWORD_VALUE="${VIKUNJA_MAILER_PASSWORD:-disabled}"

require_not_prefix VIKUNJA_SERVER_PATH "$SERVER_PATH" "/path/to/"
require_not_prefix VIKUNJA_FILES_PATH "$FILES_PATH" "/path/to/"
require_not_prefix VIKUNJA_BACKUPS_PATH "$BACKUPS_PATH" "/path/to/"

mkdir -p "$FILES_PATH" "$BACKUPS_PATH"
chown 1000:1000 "$FILES_PATH" 2>/dev/null || true

echo "==> Ensuring Docker secrets exist..."
export VIKUNJA_SERVICE_SECRET_NAME
VIKUNJA_SERVICE_SECRET_NAME="$(ensure_secret "vikunja_service_secret" "$VIKUNJA_SECRET")"
export VIKUNJA_DB_PASSWORD_SECRET_NAME
VIKUNJA_DB_PASSWORD_SECRET_NAME="$(ensure_secret "vikunja_db_password" "$VIKUNJA_DB_PASSWORD")"
export VIKUNJA_MAILER_USERNAME_SECRET_NAME
VIKUNJA_MAILER_USERNAME_SECRET_NAME="$(ensure_secret "vikunja_mailer_username" "$MAILER_USERNAME_VALUE")"
export VIKUNJA_MAILER_PASSWORD_SECRET_NAME
VIKUNJA_MAILER_PASSWORD_SECRET_NAME="$(ensure_secret "vikunja_mailer_password" "$MAILER_PASSWORD_VALUE")"

echo
echo "==> Deploying $STACK_NAME"
echo "    Image: $IMAGE_REF"
echo "    Files: $FILES_PATH"
echo "    Domain: ${VIKUNJA_DOMAIN}"

export VIKUNJA_IMAGE="$IMAGE_REF"

docker stack deploy --with-registry-auth \
  -c docker/docker-compose.yml \
  -c docker/docker-compose.prod.yml \
  "$STACK_NAME"

echo
echo "Done. Check status with:"
echo "  docker stack services $STACK_NAME"
echo "  docker stack ps $STACK_NAME"
