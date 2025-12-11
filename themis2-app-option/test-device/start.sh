#!/bin/bash
set -e

APIKEY=$1
DEVICE_ID=${2:-led1000}
ENTITY_NAME=${3:-led1000}
ENTITY_TYPE=${4:-LED}
REF_ROOM=${5:-urn:ngsi-ld:Room:002}
KONG_HOST=${6:-localhost}
KONG_PORT=${7:-8000}

# Check if API key is provided
if [ -z "$APIKEY" ]; then
  echo " No API key provided!"
  echo "Visit http://localhost:3000 to generate an API key."
  echo "To use the test device, you need to provide the generated API key as an argument when starting start.sh"
  exit 1
fi

# Determine paths to docker-compose files
ORION_INIT_DOCKER_COMPOSE_FILEPATH="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../themis2-app-platform" && pwd)"
IOT_AGENT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Start kong kong-init containers
docker compose -f "$ORION_INIT_DOCKER_COMPOSE_FILEPATH/docker-compose-prod.yml" up kong kong-init -d

sleep 10

# Start iot-agent
echo "Starting iot-agent using start.sh script"
bash "$IOT_AGENT_PATH/iotagent-json/start.sh"

echo -e "\n Logs from iotagent-json after start.sh:\n"
docker compose -f "$IOT_AGENT_PATH/docker-compose-prod.yml" logs --tail=50 iot-agent

echo "Starting test device container"
docker compose -f "$IOT_AGENT_PATH/docker-compose-prod.yml" up -d test-device

sleep 5

echo "Registering device '$DEVICE_ID' with IoT Agent via http://$KONG_HOST:$KONG_PORT"

curl -iX POST "http://$KONG_HOST:$KONG_PORT/iot-agent/iot/devices" \
  -H "Authorization: $APIKEY" \
  -H 'Content-Type: application/json' \
  -d "{
    \"devices\": [
      {
        \"device_id\": \"$DEVICE_ID\",
        \"entity_name\": \"$ENTITY_NAME\",
        \"entity_type\": \"$ENTITY_TYPE\",
        \"transport\": \"MQTT\",
        \"apikey\": \"5Qmtufl2POvbHgCTZAg1KowPP2ZHkEzP\",
        \"commands\": [
          {
            \"name\": \"send-data\",
            \"type\": \"command\"
          }
        ],
        \"static_attributes\": [
          {
            \"name\": \"refRoom\",
            \"type\": \"Relationship\",
            \"value\": \"$REF_ROOM\"
          }
        ]
      }
    ]
  }"

echo -e "\nDevice registered with API key $APIKEY"