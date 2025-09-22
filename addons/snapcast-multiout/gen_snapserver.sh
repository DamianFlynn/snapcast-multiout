#!/usr/bin/env bash
set -euo pipefail

CONF="/etc/snapserver.conf"
TMP="$(mktemp)"

echo "[INFO] Generating snapserver configuration..."
echo "[INFO] Config file: $CONF"

cat > "$TMP" <<'EOF'
[http]
enabled = true
doc_root = /usr/share/snapserver/snapweb
bind_to_address = 0.0.0.0
port = 1780

[tcp]
enabled = true
bind_to_address = 0.0.0.0
port = 1705
EOF

echo "[INFO] Reading stream configurations from /data/options.json..."
STREAM_COUNT=0
jq -r '.streams[].name' /data/options.json | while read -r name; do
  echo "[INFO] Adding stream: $name"
  # Create a proper display name by capitalizing and replacing underscores
  display_name="$(echo "$name" | sed 's/_/ /g' | sed 's/\b\(.\)/\u\1/g')"
  # URL-encode the display name for safe inclusion in query string
  encoded_display_name=$(jq -rn --arg s "$display_name" '$s|@uri')
  echo "[INFO] Display name: $display_name"
  cat >> "$TMP" <<EOF
[stream.${name}]
source = pipe:///tmp/${name}?name=${encoded_display_name}&codec=flac&sampleformat=48000:16:2
EOF
  STREAM_COUNT=$((STREAM_COUNT + 1))
done

mv "$TMP" "$CONF"
echo "[INFO] Configuration generated successfully"
echo "[INFO] Snapserver config:"
cat "$CONF"
