#!/bin/bash

# Determine the paths to both docker-compose files
ORION_INIT_DOCKER_COMPOSE_FILEPATH="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../themis2-app-platform" && pwd)"
IOT_AGENT_DOCKER_COMPOSE_FILEPATH="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Start the orion-init container
docker compose -f $ORION_INIT_DOCKER_COMPOSE_FILEPATH/docker-compose-prod.yml up orion-init -d

# Check to see if the related containers have started correctly, and if so start IoT Agent
if [ "$(docker inspect --format='{{.State.Health.Status}}' themis2-app-platform-orion-1 2>/dev/null)" = "healthy" ] && \
   [ "$(docker inspect --format='{{.State.Running}}' cygnus 2>/dev/null)" = "true" ]; then
  # Start the iot-agent container
  docker compose -f $IOT_AGENT_DOCKER_COMPOSE_FILEPATH/docker-compose-prod.yml up iot-agent -d
fi