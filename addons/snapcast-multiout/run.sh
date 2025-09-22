#!/usr/bin/env bash
set -euo pipefail

# Redirect all output to stdout for Home Assistant logging
exec > >(stdbuf -oL cat)
exec 2> >(stdbuf -oL cat >&2)

OPTS=/data/options.json
LIST=$(jq -r '.list_devices_on_start' "$OPTS")

# Get version from config.yaml (try multiple possible locations)
ADDON_VERSION="unknown"
for config_path in "/config.yaml" "/data/config.yaml" "/app/config.yaml" "$(dirname "$0")/config.yaml"; do
  if [ -f "$config_path" ]; then
    ADDON_VERSION=$(grep '^version:' "$config_path" | sed 's/version: *"\?\([^"]*\)"\?.*/\1/' 2>/dev/null || echo "unknown")
    break
  fi
done
# If still unknown, try to get it from build environment
if [ "$ADDON_VERSION" = "unknown" ] && [ -n "${BUILD_VERSION:-}" ]; then
  ADDON_VERSION="$BUILD_VERSION"
fi

echo "[INFO] ================================================="
echo "[INFO] Snapcast Multi-Output addon starting..."
echo "[INFO] Addon Version: $ADDON_VERSION"
echo "[INFO] Addon Git Version: 2025.09.22-1"
echo "[INFO] Configuration file: $OPTS"
echo "[INFO] ================================================="

# Function to detect USB audio devices and report configuration
detect_and_configure_audio() {
  echo "[INFO] Detecting USB audio devices..."
  
  # First, let's see what devices are available in the container
  echo "[DEBUG] === CONTAINER DEVICE ANALYSIS ==="
  echo "[DEBUG] /dev/snd/ contents:"
  ls -la /dev/snd/ 2>/dev/null || echo "[DEBUG] /dev/snd/ not accessible"
  
  echo "[DEBUG] Sound card directories:"
  ls -la /sys/class/sound/ 2>/dev/null || echo "[DEBUG] /sys/class/sound/ not accessible"
  
  echo "[DEBUG] Checking each card for details:"
  for card_dir in /sys/class/sound/card*; do
    if [ -d "$card_dir" ]; then
      CARD_NUM=$(basename "$card_dir" | sed 's/card//')
      echo "[DEBUG] === CARD $CARD_NUM ==="
      echo "[DEBUG] Card $CARD_NUM uevent:"
      cat "$card_dir/device/uevent" 2>/dev/null || echo "[DEBUG] No uevent file"
      echo "[DEBUG] Card $CARD_NUM PCM devices:"
      ls -la /dev/snd/pcmC${CARD_NUM}D* 2>/dev/null || echo "[DEBUG] No PCM devices"
    fi
  done
  echo "[DEBUG] === END ANALYSIS ==="
  
  USB_AUDIO_CARDS=()
  
  # Scan all control devices to find USB audio cards
  for control in /dev/snd/controlC*; do
    if [ -e "$control" ]; then
      CARD_NUM=$(basename "$control" | sed 's/controlC//')
      echo "[DEBUG] Checking card $CARD_NUM..."
      
      # Check if this card has playback devices
      if ls /dev/snd/pcmC${CARD_NUM}D*p 2>/dev/null; then
        echo "[DEBUG] Card $CARD_NUM has playback devices"
        
        # Check if this is a USB audio device
        if [ -f "/sys/class/sound/card$CARD_NUM/device/uevent" ]; then
          if grep -q "usb" "/sys/class/sound/card$CARD_NUM/device/uevent" 2>/dev/null; then
            USB_AUDIO_CARDS+=("$CARD_NUM")
            echo "[INFO] Found USB audio device: card $CARD_NUM"
            
            # List available PCM devices for this card
            echo "[DEBUG] Available PCM devices for card $CARD_NUM:"
            ls -la /dev/snd/pcmC${CARD_NUM}D* 2>/dev/null || echo "[DEBUG] No PCM devices found"
          fi
        fi
      else
        echo "[DEBUG] Card $CARD_NUM has no playback devices"
      fi
    fi
  done
  
  # Test ALSA accessibility for detected devices
  test_alsa_device() {
    local device="$1"
    echo "[DEBUG] Testing ALSA accessibility for $device"
    # Test if ALSA can access the device by checking card index
    if aplay -l 2>/dev/null | grep -q "card $(echo $device | sed 's/hw:\([0-9]*\),.*/\1/')"; then
      echo "[DEBUG] ALSA can access $device"
      return 0
    else
      echo "[DEBUG] ALSA cannot access $device"
      return 1
    fi
  }

  # Report the USB audio device found and determine the correct device
  if [ ${#USB_AUDIO_CARDS[@]} -gt 0 ]; then
    USB_CARD=${USB_AUDIO_CARDS[0]}
    echo "[INFO] Found USB audio card $USB_CARD, testing ALSA accessibility..."
    
    # Find the first available playback device for this card
    PCM_DEVICE=""
    for pcm in /dev/snd/pcmC${USB_CARD}D*p; do
      if [ -e "$pcm" ]; then
        DEVICE_NUM=$(basename "$pcm" | sed 's/pcmC'${USB_CARD}'D\([0-9]*\)p/\1/')
        PCM_DEVICE="hw:$USB_CARD,$DEVICE_NUM"
        echo "[INFO] Found USB playback device: $PCM_DEVICE"
        break
      fi
    done
    
    # Test if the USB device is accessible via ALSA
    if [ -n "$PCM_DEVICE" ] && test_alsa_device "$PCM_DEVICE"; then
      export DETECTED_USB_DEVICE="$PCM_DEVICE"
      echo "[INFO] Will use USB audio device: $DETECTED_USB_DEVICE"
    else
      echo "[WARN] USB card $USB_CARD found but ALSA cannot access it. Trying fallback devices..."
      PCM_DEVICE=""
      export DETECTED_USB_DEVICE=""
    fi
  fi

  # If no working USB device found, try fallback devices (card 2)
  if [ -z "$DETECTED_USB_DEVICE" ]; then
    echo "[INFO] Trying card 2 devices as fallback..."
    # We can see from debug that card 2 has multiple PCM devices: pcmC2D3p, pcmC2D7p, pcmC2D8p
    if [ -e "/dev/snd/controlC2" ]; then
      # Try each available device on card 2
      for device_num in 3 7 8; do
        if [ -e "/dev/snd/pcmC2D${device_num}p" ]; then
          PCM_DEVICE="hw:2,$device_num"
          echo "[INFO] Testing fallback device: $PCM_DEVICE"
          if test_alsa_device "$PCM_DEVICE"; then
            export DETECTED_USB_DEVICE="$PCM_DEVICE"
            echo "[INFO] Will use fallback device: $DETECTED_USB_DEVICE"
            break
          else
            echo "[DEBUG] Fallback device $PCM_DEVICE not accessible"
          fi
        fi
      done
    fi
    
    # If still no device, try card 0 as last resort
    if [ -z "$DETECTED_USB_DEVICE" ] && [ -e "/dev/snd/controlC0" ]; then
      echo "[INFO] Trying card 0 as last resort..."
      if [ -e "/dev/snd/pcmC0D0p" ]; then
        PCM_DEVICE="hw:0,0"
        if test_alsa_device "$PCM_DEVICE"; then
          export DETECTED_USB_DEVICE="$PCM_DEVICE"
          echo "[INFO] Will use card 0 device: $DETECTED_USB_DEVICE"
        fi
      fi
    fi
  fi

  # Final check
  if [ -z "$DETECTED_USB_DEVICE" ]; then
    echo "[ERROR] No accessible audio devices found, will use default configuration"
    export DETECTED_USB_DEVICE=""
  else
    echo "[INFO] Selected audio device: $DETECTED_USB_DEVICE"
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
  if [ -n "$DETECTED_USB_DEVICE" ] && [ "$DEV" = "default" ]; then
    DEV="$DETECTED_USB_DEVICE"
    echo "[INFO] Overriding device 'default' with detected USB device: $DEV"
  fi
  
  echo "[INFO] Starting snapclient $((i+1)): stream='$NAME' device='$DEV'"
  # Run snapclient with explicit logging to stdout/stderr
  # Use --stream to connect to the specific named stream
  snapclient --host 127.0.0.1 --player alsa --soundcard "$DEV" --instance $((i+1)) --stream "$NAME" 2>&1 &
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
