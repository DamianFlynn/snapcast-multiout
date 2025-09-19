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
EOF

echo "[INFO] Reading stream configurations from /data/options.json..."
STREAM_COUNT=0
jq -r '.streams[].name' /data/options.json | while read -r name; do
  echo "[INFO] Adding stream: $name"
  cat >> "$TMP" <<EOF
[stream.${name}]
source = pipe:///tmp/${name}?name=${name^}&codec=flac&sampleformat=48000:16:2
EOF
  STREAM_COUNT=$((STREAM_COUNT + 1))
done

mv "$TMP" "$CONF"
echo "[INFO] Configuration generated successfully"
echo "[INFO] Snapserver config:"
cat "$CONF"
