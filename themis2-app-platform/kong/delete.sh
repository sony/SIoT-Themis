#!/bin/bash
set -u

# Check arguments
if [ "$#" -ne 1 ]; then
  echo "Command: bash $0 <kong-gateway-admin-endpoint>"
  exit 1
fi
KONG_ADMIN_ENDPOINT=$1

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

# delete route for data-controller-api
curl -s $KONG_ADMIN_ENDPOINT/services/data-controller-api/routes | jq -r 'select(.data != null) | .data[]?.id' | while read DATA_CONTROLLER_API_ID; do
if [ -n "$DATA_CONTROLLER_API_ID" ]; then
  curl -iX DELETE $KONG_ADMIN_ENDPOINT/services/data-controller-api/routes/$DATA_CONTROLLER_API_ID
  echo "deleted data-controller-api-id:$DATA_CONTROLLER_API_ID"
else
  echo "DATA_CONTROLLER_API_ID does not exist"
fi
done
# delete route for realtime-notification-api
curl -s $KONG_ADMIN_ENDPOINT/services/realtime-notification-api/routes | jq -r 'select(.data != null) | .data[]?.id' | while read REALTIME_NOTIFICATION_API_ID; do
if [ -n "$REALTIME_NOTIFICATION_API_ID" ]; then
  curl -iX DELETE $KONG_ADMIN_ENDPOINT/services/realtime-notification-api/routes/$REALTIME_NOTIFICATION_API_ID
  echo "deleted realtime-notification-api-id:$REALTIME_NOTIFICATION_API_ID"
else
  echo "REALTME_NOTIFICATION_API_ID does not exist"
fi
done
# delete route for iot-agent
curl -s $KONG_ADMIN_ENDPOINT/services/iot-agent/routes | jq -r 'select(.data != null) | .data[]?.id' | while read IOT_AGENT_ID; do
if [ -n "$IOT_AGENT_ID" ]; then
  curl -iX DELETE $KONG_ADMIN_ENDPOINT/services/iot-agent/routes/$IOT_AGENT_ID
  echo "deleted iot-agent-id:$IOT_AGENT_ID"
else
  echo "IOT_AGENT_ID does not exist"
fi
done
# delete service for data-controller-api
data_controller_api_service_id=$(curl -s $KONG_ADMIN_ENDPOINT/services | jq -r 'select(.data != null) | .data[]? | select(.name == "data-controller-api") | .id')
if [ -n "$data_controller_api_service_id" ]; then
  curl -iX DELETE $KONG_ADMIN_ENDPOINT/services/$data_controller_api_service_id
  echo "deleted data-controller-api-service-id:$data_controller_api_service_id"
else
  echo "data_controller_api_service_id does not exist"
fi
# delete service for realtime-notification-api
realtime_notification_api_service_id=$(curl -s $KONG_ADMIN_ENDPOINT/services | jq -r 'select(.data != null) | .data[]? | select(.name == "realtime-notification-api") | .id')
if [ -n "$realtime_notification_api_service_id" ]; then
  curl -iX DELETE $KONG_ADMIN_ENDPOINT/services/$realtime_notification_api_service_id
  echo "deleted realtime-notification-api-service-id:$realtime_notification_api_service_id"
else
  echo "realtime_notification_api_service_id does not exist"
fi
# delete service for iot-agent
iot_agent_service_id=$(curl -s $KONG_ADMIN_ENDPOINT/services | jq -r 'select(.data != null) | .data[]? | select(.name == "iot-agent") | .id')
if [ -n "$iot_agent_service_id" ]; then
  curl -iX DELETE $KONG_ADMIN_ENDPOINT/services/$iot_agent_service_id
  echo "deleted iot-agent-service-id:$iot_agent_service_id"
else
  echo "iot_agent_service_id does not exist"
fi
# delete realtime-notification-api plugin
realtime_notification_api_plugin_ids=$(curl -s $KONG_ADMIN_ENDPOINT/services/realtime-notification-api/plugins | jq -r '.data[].id')
if [ -n "$realtime_notification_api_plugin_ids" ]; then
  for id in $realtime_notification_api_plugin_ids; do
    curl -s -o /dev/null -w "deleted realtime-notification-api plugin-id:$id\n" -X DELETE $KONG_ADMIN_ENDPOINT/services/realtime-notification-api/plugins/$id
  done
else
  echo "no realtime-notification-api plugins exist"
fi
# delete data-controller-api plugin
data_controller_api_plugin_ids=$(curl -s $KONG_ADMIN_ENDPOINT/services/data-controller-api/plugins | jq -r '.data[].id')
if [ -n "$data_controller_api_plugin_ids" ]; then
  for id in $data_controller_api_plugin_ids; do
    curl -s -o /dev/null -w "deleted data-controller-api plugin-id:$id\n" -X DELETE $KONG_ADMIN_ENDPOINT/services/data-controller-api/plugins/$id
  done
else
  echo "no data-controller-api plugins exist"
fi
# delete kong plugin
kong_plugin_ids=$(curl -s $KONG_ADMIN_ENDPOINT/plugins | jq -r '.data[].id')
if [ -n "$kong_plugin_ids" ]; then
  for id in $kong_plugin_ids; do
    curl -s -o /dev/null -w "deleted kong plugin-id:$id\n" -X DELETE $KONG_ADMIN_ENDPOINT/plugins/$id
  done
else
  echo "no kong plugins exist"
fi
# delete iot-agent plugin
iot_agent_plugin_ids=$(curl -s $KONG_ADMIN_ENDPOINT/services/iot-agent/plugins | jq -r '.data[].id')
if [ -n "$iot_agent_plugin_ids" ]; then
  for id in $iot_agent_plugin_ids; do
    curl -s -o /dev/null -w "deleted iot-agent plugin-id:$id\n" -X DELETE $KONG_ADMIN_ENDPOINT/services/iot-agent/plugins/$id
  done
else
  echo "no iot-agent plugins exist"
fi
