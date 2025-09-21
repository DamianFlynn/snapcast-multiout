#!/usr/bin/env bash
set -euo pipefail

# Redirect all output to stdout for Home Assistant logging
exec > >(stdbuf -oL cat)
exec 2> >(stdbuf -oL cat >&2)

OPTS=/data/options.json
LIST=$(jq -r '.list_devices_on_start' "$OPTS")

echo "[INFO] Snapcast Multi-Output addon starting..."
echo "[INFO] Configuration file: $OPTS"

# Function to detect USB audio devices and report configuration
detect_and_configure_audio() {
  echo "[INFO] ----- Detecting USB Audio Devices -----"
  
  # Check for USB audio devices in /dev/snd/
  USB_AUDIO_CARDS=()
  for control in /dev/snd/controlC*; do
    if [ -e "$control" ]; then
      CARD_NUM=$(basename "$control" | sed 's/controlC//')
      # Check if this is a USB audio device
      if [ -f "/sys/class/sound/card$CARD_NUM/device/uevent" ]; then
        if grep -q "usb" "/sys/class/sound/card$CARD_NUM/device/uevent" 2>/dev/null; then
          USB_AUDIO_CARDS+=("$CARD_NUM")
          echo "[INFO] Found USB audio device: card $CARD_NUM"
        fi
      fi
    fi
  done
  
  # Report the USB audio device found
  if [ ${#USB_AUDIO_CARDS[@]} -gt 0 ]; then
    USB_CARD=${USB_AUDIO_CARDS[0]}
    echo "[INFO] Will use USB audio card $USB_CARD (configured in asound.conf)"
    export DETECTED_USB_CARD="$USB_CARD"
  else
    echo "[WARN] No USB audio devices found, will use default configuration"
    export DETECTED_USB_CARD=""
  fi
}

# Detect and configure audio devices
detect_and_configure_audio

echo "[INFO] Snapcast Multi-Output addon starting..."
echo "[INFO] Configuration file: $OPTS"

if [ "$LIST" = "true" ]; then
  echo "[INFO] ----- USB Audio Devices -----"
  lsusb | grep -E "(Audio|Sound|Creative|Blaster)" || echo "No USB audio devices found"
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
  
  # If we detected a USB audio device and the config uses default, override with USB device
  if [ -n "$DETECTED_USB_CARD" ] && [ "$DEV" = "default" ]; then
    DEV="hw:$DETECTED_USB_CARD,0"
    echo "[INFO] Overriding device 'default' with detected USB device: $DEV"
  fi
  
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
