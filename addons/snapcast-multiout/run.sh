#!/usr/bin/env bash
set -euo pipefail

OPTS=/data/options.json
LIST=$(jq -r '.list_devices_on_start' "$OPTS")

if [ "$LIST" = "true" ]; then
  echo "----- ALSA devices (cards) -----"
  cat /proc/asound/cards || true
  echo "----- ALSA PCMs (playback) -----"
  aplay -L || true
fi

echo "[INFO] writing snapserver.conf..."
/gen_snapserver.sh

echo "[INFO] starting snapserver..."
snapserver -c /etc/snapserver.conf &
SERVER_PID=$!
sleep 2

COUNT=$(jq '.streams | length' "$OPTS")
CLIENT_PIDS=()
for i in $(seq 0 $((COUNT-1))); do
  NAME=$(jq -r ".streams[$i].name" "$OPTS")
  DEV=$(jq -r ".streams[$i].device" "$OPTS")
  echo "[INFO] starting snapclient: stream='$NAME' device='$DEV'"
  snapclient --host 127.0.0.1 --player alsa --soundcard "$DEV" --instance $((i+1)) &
  CLIENT_PIDS+=($!)
done

# Function to cleanup and exit
cleanup() {
  echo "[INFO] Shutting down..."
  kill $SERVER_PID 2>/dev/null || true
  for pid in "${CLIENT_PIDS[@]}"; do
    kill $pid 2>/dev/null || true
  done
  exit 0
}

# Trap signals
trap cleanup SIGTERM SIGINT

# Wait for any process to exit
wait -n
echo "[INFO] A process exited, shutting down all processes..."
cleanup
