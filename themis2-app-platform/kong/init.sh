#!/bin/bash
set -u

DATA_CONTROLLER_API_NAME="data-controller-api"
REALTIME_NOTIFICATION_API_NAME="realtime-notification-api"
IOT_AGENT_NAME="iot-agent"

# Get environment variables
KONG_ADMIN_ENDPOINT=${KONG_ADMIN_ENDPOINT}
DATA_CONTROLLER_API_ENDPOINT=${DATA_CONTROLLER_API_ENDPOINT}
REALTIME_NOTIFICATION_API_ENDPOINT=${REALTIME_NOTIFICATION_API_ENDPOINT}
IOT_AGENT_ENDPOINT=${IOT_AGENT_ENDPOINT}

# Get execution directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Check required environment variables
if [ -z "$KONG_ADMIN_ENDPOINT" ]; then
  echo "Error: KONG_ADMIN_ENDPOINT is not set."
  exit 1
fi
if [ -z "$DATA_CONTROLLER_API_ENDPOINT" ]; then
  echo "Error: DATA_CONTROLLER_API_ENDPOINT is not set."
  exit 1
fi
if [ -z "$REALTIME_NOTIFICATION_API_ENDPOINT" ]; then
  echo "Error: REALTIME_NOTIFICATION_API_ENDPOINT is not set."
  exit 1
fi
if [ -z "$IOT_AGENT_ENDPOINT" ]; then
  echo "Error: IOT_AGENT_ENDPOINT is not set."
  exit 1
fi

# Check launch of kong
timeout 120 bash <<EOS
until curl -sf "$KONG_ADMIN_ENDPOINT/services" 1> /dev/null; do
  sleep 5
done
EOS

if [ $? -ne 0 ]; then
  echo -e "\nKong did not launch or respond. Check the first argument."
  exit 1
fi
echo -e "\nKong is ready. Checking API endpoints..."


# Check current services
services=$(curl -s "$KONG_ADMIN_ENDPOINT/services") || { echo "Failed to fetch services from Kong Admin API: GET $KONG_ADMIN_ENDPOINT/services"; exit 1; }
exists=$(echo "$services" | jq -r --arg name "$DATA_CONTROLLER_API_NAME" '.data[] | select(.name == $name) | .name') || { echo "Failed to parse JSON"; exit 1; }
if [[ "$exists" == "$DATA_CONTROLLER_API_NAME" ]]; then
  echo "Service for data-controller-api already exists. Skipping the request to create a new service."
  echo "Exist service: $(echo "$services" | jq --arg name "$DATA_CONTROLLER_API_NAME" '.data[] | select(.name == $name)')"
else
  # Add service of data-controller-api
  status_code=$(curl -s -o /dev/null -w "%{http_code}" -X POST \
    "$KONG_ADMIN_ENDPOINT/services/" \
    -d name=$DATA_CONTROLLER_API_NAME \
    -d url=$DATA_CONTROLLER_API_ENDPOINT
  )
  if [ "$status_code" -eq 201 ]; then
    echo "Service of data-controller-api is created."
  else
    echo "Failed to create service of data-controller-api. Status code: $status_code"
    exit 1
  fi
fi

exists=$(echo "$services" | jq -r --arg name "$REALTIME_NOTIFICATION_API_NAME" '.data[] | select(.name == $name) | .name')
if [[ "$exists" == "$REALTIME_NOTIFICATION_API_NAME" ]]; then
  echo "Service for realtime-notification-api already exists. Skipping the request to create a new service."
  echo "Exist service: $(echo "$services" | jq --arg name "$REALTIME_NOTIFICATION_API_NAME" '.data[] | select(.name == $name)')"
else
  # Add service of realtime-notification-api
  status_code=$(curl -s -o /dev/null -w "%{http_code}" -X POST \
    "$KONG_ADMIN_ENDPOINT/services/" \
    -d name=$REALTIME_NOTIFICATION_API_NAME \
    -d url=$REALTIME_NOTIFICATION_API_ENDPOINT
  )
  if [ "$status_code" -eq 201 ]; then
    echo "Service of realtime-notification-api is created."
  else
    echo "Failed to create service of realtime-notification-api. Status code: $status_code"
    exit 1
  fi
fi

exists=$(echo "$services" | jq -r --arg name "$IOT_AGENT_NAME" '.data[] | select(.name == $name) | .name')
if [[ "$exists" == "$IOT_AGENT_NAME" ]]; then
  echo "Service for iot-agent already exists. Skipping the request to create a new service."
  echo "Exist service: $(echo "$services" | jq --arg name "$IOT_AGENT_NAME" '.data[] | select(.name == $name)')"
else
  # Add service of iot-agent
  status_code=$(curl -s -o /dev/null -w "%{http_code}" -X POST \
    "$KONG_ADMIN_ENDPOINT/services/" \
    -d name=$IOT_AGENT_NAME \
    -d url=$IOT_AGENT_ENDPOINT
  )
  if [ "$status_code" -eq 201 ]; then
    echo "Service of iot-agent is created."
  else
    echo "Failed to create service of iot-agent. Status code: $status_code"
    exit 1
  fi
fi

# Check current route for data-controller-api
route_for_data_controller_api=$(curl -s "$KONG_ADMIN_ENDPOINT/services/$DATA_CONTROLLER_API_NAME/routes" | jq -r '.data') || { echo "Failed to parse JSON"; exit 1; }
if [[ "$route_for_data_controller_api" != "[]" ]]; then
  echo "Route for data-controller-api already exists. Skipping the request to create a new route."
  echo "Exist routes: $route_for_data_controller_api"
else
  # Add Route for data-controller-api
  status_code=$(curl -s -o /dev/null -w "%{http_code}" -X POST \
    "$KONG_ADMIN_ENDPOINT/services/$DATA_CONTROLLER_API_NAME/routes" \
    -d paths[]="/$DATA_CONTROLLER_API_NAME" \
    -d name=$DATA_CONTROLLER_API_NAME \
  )
  if [ "$status_code" -eq 201 ]; then
    echo "Route of data-controller-api is created."
  else
    echo "Failed to create route of data-controller-api. Status code: $status_code"
    exit 1
  fi
fi

# Check current route for realtime-notification-api
route_for_realtime_notification_api=$(curl -s "$KONG_ADMIN_ENDPOINT/services/$REALTIME_NOTIFICATION_API_NAME/routes" | jq -r '.data') || { echo "Failed to parse JSON"; exit 1; }
if [[ "$route_for_realtime_notification_api" != "[]" ]]; then
  echo "Route for realtime-notification-api already exists. Skipping the request to create a new route."
  echo "Exist routes: $route_for_realtime_notification_api"
else
  # Add Route for realtime-notification-api
  status_code=$(curl -s -o /dev/null -w "%{http_code}" -X POST \
    "$KONG_ADMIN_ENDPOINT/services/$REALTIME_NOTIFICATION_API_NAME/routes" \
    -d paths[]="/$REALTIME_NOTIFICATION_API_NAME" \
    -d name=$REALTIME_NOTIFICATION_API_NAME \
  )
  if [ "$status_code" -eq 201 ]; then
    echo "Route of realtime-notification-api is created."
  else
    echo "Failed to create route of realtime-notification-api. Status code: $status_code"
    exit 1
  fi
fi

# Check current route for iot-agent
route_for_iot_agent=$(curl -s "$KONG_ADMIN_ENDPOINT/services/$IOT_AGENT_NAME/routes" | jq -r '.data') || { echo "Failed to parse JSON"; exit 1; }
if [[ "$route_for_iot_agent" != "[]" ]]; then
  echo "Route for iot-agent already exists. Skipping the request to create a new route."
  echo "Exist routes: $route_for_iot_agent"
else
  # Add Route for iot-agenti
  status_code=$(curl -s -o /dev/null -w "%{http_code}" -X POST \
    "$KONG_ADMIN_ENDPOINT/services/$IOT_AGENT_NAME/routes" \
    -d paths[]="/$IOT_AGENT_NAME" \
    -d name=$IOT_AGENT_NAME \
  )
  if [ "$status_code" -eq 201 ]; then
    echo "Route of iot-agent is created."
  else
    echo "Failed to create route of iot-agent. Status code: $status_code"
    exit 1
  fi
fi

# Check current plugins
plugins=$(curl -s "$KONG_ADMIN_ENDPOINT/plugins" | jq -r '.data') || { echo "Failed to parse JSON"; exit 1; }
if [[ "$plugins" != "[]" ]]; then
  echo "Plugins already exist. Skipping the request to create new plugins."
  echo "Exist plugins: $plugins"
else
  # Add plugins
  kong_status_code=$(curl -s -o /dev/null -w "%{http_code}" -X POST \
    "$KONG_ADMIN_ENDPOINT/plugins" \
    -d name="key-auth" \
    -d config.key_names="Authorization" \
    -d config.key_in_query=false)
  if [ "$kong_status_code" -eq 201 ]; then
    echo "Kong plugin is created."
  else
    echo "Failed to create Kong plugin. Status code: $kong_status_code"
    exit 1
  fi
  # Add iot-agent plugins
  iota_status_code=$(curl -s -o /dev/null -w "%{http_code}" \
    -X POST "$KONG_ADMIN_ENDPOINT/services/iot-agent/plugins" \
    -d "name=post-function" \
    --data-urlencode config.access@${SCRIPT_DIR}/fiware_header_plugin.lua)
  if [ "$iota_status_code" -eq 201 ]; then
    echo "iot-agent plugin is created."
  else
    echo "Failed to create iot-agent plugin. Status code: $iota_status_code"
    exit 1
  fi
  # Add realtime-notification-api plugins
  realtime_notification_api_status_code=$(curl -s -o /dev/null -w "%{http_code}" \
    -X POST "$KONG_ADMIN_ENDPOINT/services/realtime-notification-api/plugins" \
    -d "name=post-function" \
    --data-urlencode config.access@${SCRIPT_DIR}/fiware_header_plugin.lua
  )

  if [ "$realtime_notification_api_status_code" -eq 201 ]; then
    echo "realtime-notification-api plugin is created."
  else
    echo "Failed to create realtime-notification-api plugin. Status code: $realtime_notification_api_status_code"
    exit 1
  fi
  # Add data-controller-api plugins
  data_controller_api_status_code=$(curl -s -o /dev/null -w "%{http_code}" \
    -X POST "$KONG_ADMIN_ENDPOINT/services/data-controller-api/plugins" \
    -d "name=post-function" \
    --data-urlencode config.access@${SCRIPT_DIR}/collection_plugin.lua)
  if [ "$data_controller_api_status_code" -eq 201 ]; then
    echo "data-controller-api plugin is created."
  else
    echo "Failed to create data-controller-api plugin. Status code: $data_controller_api_status_code"
    exit 1
  fi
fi

echo "Kong initialization is done."