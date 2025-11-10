#!/bin/bash

set -e

# Determine the current directory (eltres-console/)
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

# Determine the path to themis2-app-platform (assumed to be one level up)
PLATFORM_DIR="$(cd "$ROOT_DIR/../themis2-app-platform" && pwd)"

echo "Starting dependent services from themis2-app-platform..."

# Start the dependent containers from docker-compose-prod.yml
docker compose -f "$PLATFORM_DIR/docker-compose-prod.yml" up -d postgres keycloak keycloak-init

# Wait up to 20 seconds for .env.local to be created
echo "Waiting for .env.local to be generated..."
for i in {1..20}; do
    if [ -f "$PLATFORM_DIR/keycloak/.env.local" ]; then
        echo ".env.local found!"
        break
    fi
    echo -n "."
    sleep 1
done

if [ ! -f "$PLATFORM_DIR/keycloak/.env.local" ]; then
    echo
    echo ".env.local not found after 20 seconds. Aborting."
    exit 1
fi

echo "Starting eltres-console..."

# Start eltres-console using its own docker-compose-prod.yml
docker compose -f "$ROOT_DIR/docker-compose-prod.yml" up -d --build eltres-console
 