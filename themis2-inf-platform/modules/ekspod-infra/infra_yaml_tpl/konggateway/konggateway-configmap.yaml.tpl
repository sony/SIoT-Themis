apiVersion: v1
kind: ConfigMap
metadata:
  namespace: default
  name: init-kong
data:
  init-kong.sh: |
    #!/bin/bash

    DATA_CONTROLLER_API_NAME="data-controller-api"
    REALTIME_NOTIFICATION_API_NAME="realtime-notification-api"

    # Check arguments
    if [ "$#" -ne 3 ]; then
      echo "Command: bash $0 <kong-gateway-admin-endpoint> <data-controller-api-endpoint> <realtime-notification-api-endpoint>"
      exit 1
    fi
    KONG_ADMIN_ENDPOINT=$1
    DATA_CONTROLLER_API_ENDPOINT=$2
    REALTIME_NOTIFICATION_API_ENDPOINT=$3

    # Check launch of kong
    timeout 30 bash <<EOS
    until curl -sf "$KONG_ADMIN_ENDPOINT/services" > /dev/null; do
      sleep 5
    done
    EOS

    if [ $? -ne 0 ]; then
      echo "Kong did not launch or respond. Check the first argument."
      exit 1
    fi
    echo "Kong is ready. Checking API endpoints..."

    # Check current services
    services=$(curl -s "$KONG_ADMIN_ENDPOINT/services" | jq -r '.data')
    names=$(echo $services | jq -r '.[].name')
    if [[ "$names" == *"$DATA_CONTROLLER_API_NAME"* ]]; then
      echo "Service for data-controller-api already exists. Skipping the request to create a new service."
      echo "Exist service: $(echo "$services" | jq --arg name "$DATA_CONTROLLER_API_NAME" '.[] | select(.name == $name)')"
    else
      # Add service of data-controller-api
      status_code=$(curl -s -o /dev/null -w "%%{http_code}" -X POST \
        "$KONG_ADMIN_ENDPOINT/services/" \
        -d name=$DATA_CONTROLLER_API_NAME \
        -d url=$DATA_CONTROLLER_API_ENDPOINT
      )
      if [ "$status_code" -ne 201 ]; then
        echo "Failed to create service of data-controller-api. Status code: $status_code"
        exit 1
      else
        echo "Service of data-controller-api is created."
      fi
    fi

    if [[ "$names" == *"$REALTIME_NOTIFICATION_API_NAME"* ]]; then
      echo "Service for realtime-notification-api already exists. Skipping the request to create a new service."
      echo "Exist service: $(echo "$services" | jq --arg name "$REALTIME_NOTIFICATION_API_NAME" '.[] | select(.name == $name)')"
    else
      # Add service of realtime-notification-api
      status_code=$(curl -s -o /dev/null -w "%%{http_code}" -X POST \
        "$KONG_ADMIN_ENDPOINT/services/" \
        -d name=$REALTIME_NOTIFICATION_API_NAME \
        -d url=$REALTIME_NOTIFICATION_API_ENDPOINT
      )
      if [ "$status_code" -ne 201 ]; then
        echo "Failed to create service of realtime-notification-api. Status code: $status_code"
        exit 1
      else
        echo "Service of realtime-notification-api is created."
      fi
    fi

    # Check current route for data-controller-api
    route_for_data_controller_api=$(curl -s "$KONG_ADMIN_ENDPOINT/services/$DATA_CONTROLLER_API_NAME/routes" | jq -r '.data')
    if [[ "$route_for_data_controller_api" != "[]" ]]; then
      echo "Route for data-controller-api already exists. Skipping the request to create a new route."
      echo "Exist routes: $route_for_data_controller_api"
    else
      # Add Route for data-controller-api
      status_code=$(curl -s -o /dev/null -w "%%{http_code}" -X POST \
        "$KONG_ADMIN_ENDPOINT/services/$DATA_CONTROLLER_API_NAME/routes" \
        -d paths[]="/$DATA_CONTROLLER_API_NAME" \
        -d name=$DATA_CONTROLLER_API_NAME \
      )
      if [ "$status_code" -ne 201 ]; then
        echo "Failed to create route of data-controller-api. Status code: $status_code"
        exit 1
      else
        echo "Route of data-controller-api is created."
      fi
    fi

    # Check current route for realtime-notification-api
    route_for_realtime_notification_api=$(curl -s "$KONG_ADMIN_ENDPOINT/services/$REALTIME_NOTIFICATION_API_NAME/routes" | jq -r '.data')
    if [[ "$route_for_realtime_notification_api" != "[]" ]]; then
      echo "Route for realtime-notification-api already exists. Skipping the request to create a new route."
      echo "Exist routes: $route_for_realtime_notification_api"
    else
      # Add Route for realtime-notification-api
      status_code=$(curl -s -o /dev/null -w "%%{http_code}" -X POST \
        "$KONG_ADMIN_ENDPOINT/services/$REALTIME_NOTIFICATION_API_NAME/routes" \
        -d paths[]="/$REALTIME_NOTIFICATION_API_NAME" \
        -d name=$REALTIME_NOTIFICATION_API_NAME \
      )
      if [ "$status_code" -ne 201 ]; then
        echo "Failed to create route of realtime-notification-api. Status code: $status_code"
        exit 1
      else
        echo "Route of realtime-notification-api is created."
      fi
    fi

    # Check current plugins
    plugins=$(curl -s "$KONG_ADMIN_ENDPOINT/plugins" | jq -r '.data')
    if [[ "$plugins" != "[]" ]]; then
      echo "Plugins already exists. Skipping the request to create a new plugins."
      echo "Exist plugins: $plugins"
    else
      # Add plugins
      status_code=$(curl -s -o /dev/null -w "%%{http_code}" -X POST \
        "$KONG_ADMIN_ENDPOINT/plugins" \
        -d name="key-auth" \
        -d config.key_names="Authorization" \
        -d config.key_in_query=false \
      )
      if [ "$status_code" -ne 201 ]; then
        echo "Failed to create plugin. Status code: $status_code"
        exit 1
      else
        echo "Plugin is created."
      fi
    fi

    echo "Kong initialization is done."
