#!/bin/bash

# Check arguments
if [ -z "$ORION_ENDPOINT" ] || [ -z "$CYGNUS_ENDPOINT" ]; then
  echo "Error: ORION_ENDPOINT and CYGNUS_ENDPOINT environment variables must be set"
  exit 1
fi

# Check launch of orion
timeout 30 bash <<EOS
until curl -sf "$ORION_ENDPOINT/v2/subscriptions" > /dev/null; do
  sleep 5
done
EOS

if [ $? -ne 0 ]; then
  echo "Orion did not launch or respond. Check the first argument."
  exit 1
fi
echo "Orion is ready. Checking subscriptions..."

# Check current subscriptions
subscriptions=$(curl -s "$ORION_ENDPOINT/v2/subscriptions")
if [[ "$subscriptions" != "[]" ]]; then
  echo "Subscription already exists. Skipping the request to create a new subscription for Cygnus."
  exit 0
fi

# Add subscription for cygnus
echo "Subscription does not exist. Sending the request to create a new subscription for Cygnus..."
status_code=$(curl -s -w "%{http_code}" -X POST \
  "$ORION_ENDPOINT/v2/subscriptions" \
  -H 'Content-Type: application/json' \
  -d '{
    "description": "Notify Cygnus of all changes",
    "subject": {
      "entities": [
        {
          "idPattern": ".*"
        }
      ]
    },
    "notification": {
      "http": {
        "url": "'"$CYGNUS_ENDPOINT"'/notify"
      }
    }
  }'
)

# Check status code
if [ "$status_code" -ne 201 ]; then
  echo "Failed to create a new subscription for Cygnus. Status code: $status_code"
  exit 1
fi

echo "Successfully created a new subscription for Cygnus."
