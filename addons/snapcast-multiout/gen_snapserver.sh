#!/usr/bin/env bash
set -euo pipefail

CONF="/etc/snapserver.conf"
TMP="$(mktemp)"

cat > "$TMP" <<'EOF'
[http]
enabled = true
doc_root = /usr/share/snapserver/snapweb
EOF

jq -r '.streams[].name' /data/options.json | while read -r name; do
  cat >> "$TMP" <<EOF
[stream.${name}]
source = pipe:///tmp/${name}?name=${name^}&codec=flac&sampleformat=48000:16:2
EOF
done

mv "$TMP" "$CONF"
