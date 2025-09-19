#!/usr/bin/env bash
set -euo pipefail

# Redirect all output to stdout for Home Assistant logging
exec > >(stdbuf -oL cat)
exec 2> >(stdbuf -oL cat >&2)

OPTS=/data/options.json
LIST=$(jq -r '.list_devices_on_start' "$OPTS")

echo "[INFO] Snapcast Multi-Output addon starting..."
echo "[INFO] Configuration file: $OPTS"

if [ "$LIST" = "true" ]; then
  echo "[INFO] ----- USB Audio Devices -----"
  lsusb | grep -i audio || echo "No USB audio devices found"
  echo "[INFO] ----- ALSA devices (cards) -----"
  cat /proc/asound/cards 2>/dev/null || echo "No ALSA cards found - audio subsystem may not be available"
  echo "[INFO] ----- ALSA PCMs (playback) -----"
  aplay -L 2>/dev/null || echo "No ALSA playback devices found"
  echo "[INFO] ----- Hardware detection -----"
  ls -la /dev/snd/ 2>/dev/null || echo "No /dev/snd devices found"
  echo "[INFO] ----- System audio modules -----"
  lsmod | grep -E "(snd|usb|audio)" || echo "No audio modules loaded"
fi

echo "[INFO] Writing snapserver.conf..."
/gen_snapserver.sh

echo "[INFO] Starting snapserver..."
# Run snapserver with explicit logging to stdout/stderr
snapserver -c /etc/snapserver.conf 2>&1 &
SERVER_PID=$!
echo "[INFO] Snapserver started with PID: $SERVER_PID"
sleep 2

COUNT=$(jq '.streams | length' "$OPTS")
echo "[INFO] Configuring $COUNT audio streams..."
CLIENT_PIDS=()
for i in $(seq 0 $((COUNT-1))); do
  NAME=$(jq -r ".streams[$i].name" "$OPTS")
  DEV=$(jq -r ".streams[$i].device" "$OPTS")
  echo "[INFO] Starting snapclient $((i+1)): stream='$NAME' device='$DEV'"
  # Run snapclient with explicit logging to stdout/stderr
  snapclient --host 127.0.0.1 --player alsa --soundcard "$DEV" --instance $((i+1)) 2>&1 &
  CLIENT_PIDS+=($!)
  echo "[INFO] Snapclient $((i+1)) started with PID: ${CLIENT_PIDS[$i]}"
done

echo "[INFO] All processes started successfully"
echo "[INFO] Server PID: $SERVER_PID"
echo "[INFO] Client PIDs: ${CLIENT_PIDS[*]}"

# Function to cleanup and exit
cleanup() {
  echo "[INFO] Received shutdown signal, cleaning up..."
  echo "[INFO] Stopping snapserver (PID: $SERVER_PID)..."
  kill $SERVER_PID 2>/dev/null || true
  echo "[INFO] Stopping snapclients..."
  for i in "${!CLIENT_PIDS[@]}"; do
    echo "[INFO] Stopping snapclient $((i+1)) (PID: ${CLIENT_PIDS[$i]})..."
    kill ${CLIENT_PIDS[$i]} 2>/dev/null || true
  done
  echo "[INFO] Cleanup complete, exiting"
  exit 0
}

# Trap signals
trap cleanup SIGTERM SIGINT

echo "[INFO] Addon running, monitoring processes..."
# Wait for any process to exit
wait -n
echo "[WARN] A process exited unexpectedly, shutting down all processes..."
cleanup
