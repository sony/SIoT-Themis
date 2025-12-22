#!/bin/bash
 
echo "[INFO] Send data Eltres to topic..."

MODE=${TEST_DEVICE_MODE:-send}
TEST_DEVICE_TOPIC=${TEST_DEVICE_TOPIC:-test-device-topic}

echo "[INFO] Available TEST_DEVICE_MODE values and their meanings:"
echo "  - send    : npm run send-data"
echo "  - receive : run receive-data"

# Print the mode used in the current run
echo "[INFO] TEST_DEVICE_MODE received: '$MODE'"

DATA='['
for i in $(seq 1 30); do
  LAT=$(echo "scale=8; 40.689217777 + ($i * 0.00001)" | bc)
  LON=$(echo "scale=8; -74.04456 + ($i * 0.00001)" | bc)
 
  ENTRY="{\"gnss\":63,\"latitude\":${LAT},\"longitude\":${LON},\"height\":100,\"speed\":40,\"course\":135,\"adc\":500,\"temperature\":$((25 + i % 5)),\"userdata\":80,\"sos\":$((i % 2))}"
 
  if [ $i -ne 30 ]; then
    DATA+="${ENTRY},"
  else
    DATA+="${ENTRY}"
  fi
done
DATA+=']'

if [ "$MODE" == "receive"]; then
  echo "[INFO] Runnning in receive mode ..."
  npm run receive-data -- \
    --data "${DATA}" \
    --topic "${TEST_DEVICE_TOPIC}" \
    --interval 5
else
  echo "[INFO] Runnning in send mode ..."
  npm run send-data -- \
    --data "${DATA}" \
    --topic "${TEST_DEVICE_TOPIC}" \
    --interval 5
fi