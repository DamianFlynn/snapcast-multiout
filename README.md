Below is a complete **High-Level Design (HLD)** and **Low-Level Design (LLD)** for your new multi-room audio system powered by **Music Assistant + Snapcast**, using **Satellite1** devices (with XMOS AEC) in each room and **Xantech MRC88** for the in-ceiling speakers. I’ve also included a **custom HAOS add-on**that dynamically creates one Snapclient per “room/stream,” so you can start with your **Sound Blaster USB** today and seamlessly move to the **UMC1820** when it arrives.

---

# High-Level Design (HLD)

## Objectives

- **Voice-first rooms**: Each room has a Satellite1 (Sat1) that acts as microphone/voice device and **local Snapclient** for AEC.
- **Central amplification**: In-ceiling speakers are driven by the **Xantech MRC88** in the rack.
- **Single control plane**: **Home Assistant (HAOS) + Music Assistant (MA)** on your NUC are the brains; **Snapserver** distributes audio.
- **Tidy UX**: MA shows **one target per room** (a Snapcast stream/group). The Sat1 in the room **and** the rack output (to Xantech) both subscribe to the *same* stream → perfect sync, AEC preserved, and no extra “devices” clutter.

## Key Principles

- **Keep Sat1 as a playback endpoint** (even at low volume if needed) so the **XMOS AEC** has the proper reference.
- **Use IP audio** for distribution; avoid long analog returns from rooms to rack.
- **ALSA direct** on the NUC for deterministic multi-output routing (best fit for HAOS add-on).
- **Scale by outputs**: Start with 1 stereo zone (Sound Blaster), then move to **UMC1820** (5 stereo zones). Add a second interface later if you want 8 stereo rooms from the rack.

## Logical Topology

- **Music sources**: Music Assistant (Spotify, radio, local library, etc.)
- **Distribution**: Snapserver (on NUC)
- **Room endpoints**:
    - Sat1 in each room (Snapclient → small local playback for AEC + voice)
    - Rack “per-room” Snapclients (in add-on) → ALSA → specific output pair on USB interface → **Xantech input** → in-ceiling speakers
- **Control**: HA dashboards + voice via Sat1

---

# Low-Level Design (LLD)

## Naming & Mapping (example)

Use consistent, human-friendly room IDs. Example for 5 zones (initial with UMC1820):

- Streams (and MA players): `kitchen`, `living`, `bedroom1`, `bedroom2`, `office`
- UMC1820 output pairs:
    - `umc_out_12` → Xantech Source 1 → **kitchen**
    - `umc_out_34` → Xantech Source 2 → **living**
    - `umc_out_56` → Xantech Source 3 → **bedroom1**
    - `umc_out_78` → Xantech Source 4 → **bedroom2**
    - `umc_out_910` → Xantech Source 5 → **office**
- Each Sat1 joins the stream for its room (e.g., kitchen Sat1 → `kitchen`).

> When you expand beyond 5 stereo pairs, add another interface (or a bigger one) and define more devices/streams.
> 

## Timing & Sync

- Snapcast handles stream sync across Sat1 and rack clients.
- Keep Sat1 playing locally (even if quietly) to preserve AEC.
- Use Snapcast buffer defaults first; adjust only if you notice room/rack echo.

## Levels & Cabling

- **UMC1820 line-outs are balanced TRS**. Xantech inputs are unbalanced line-level (typically RCA).
- Use **TRS-to-RCA** cables/adapters. Keep runs short on the rack side. Start with conservative output levels; raise until Xantech inputs are healthy but not clipping.

## Security & Reliability

- Keep Snapserver and clients on your trusted LAN.
- Pin Snapcast version (0.31.x is solid for MA).
- Use **powered USB hub** if you later add many DACs.
- Back up your HAOS config (snapshots).

---

# Custom HAOS Add-on (dynamic multi-output Snapcast)

This add-on:

- Runs **Snapserver** and **N** Snapclients (one per stream) **inside one container**.
- Reads a list of **streams** and **ALSA device names** from the add-on options.
- Ships with **Sound Blaster** default (card `default`) so you can test today.
- When UMC1820 arrives, drop in the **ALSA mapping** and change each stream to point at `umc_out_XX`.

## Folder layout (in your HA `addons` share)

```
/addons/snapcast-multiout/
  ├── config.yaml
  ├── Dockerfile
  ├── run.sh
  ├── gen_snapserver.sh
  ├── asound.conf
  └── README.txt  (optional)

```

### `config.yaml`

```yaml
name: Snapcast Multi-Output
slug: snapcast-multiout
version: "0.31.0-1"
description: Snapserver + dynamic Snapclients for multi-output USB (UMC1820) with Music Assistant
arch:
  - amd64
startup: services
host_network: true
boot: auto
init: false
map:
  - share:rw
devices:
  - /dev/snd
options:
  # Define one entry per room/stream. "device" is an ALSA PCM name.
  streams:
    - name: kitchen
      device: default        # Sound Blaster now; later "umc_out_12"
    - name: living
      device: default        # change to "umc_out_34" later
schema:
  streams:
    - name: str
      device: str

```

### `Dockerfile`

```docker
FROM ghcr.io/badaix/snapcast:alpine-v0.31.0

# Tools we need in the container
RUN apk add --no-cache bash jq alsa-plugins alsa-utils

# Copy configs/scripts
COPY run.sh /run.sh
COPY gen_snapserver.sh /gen_snapserver.sh
COPY asound.conf /etc/asound.conf

RUN chmod +x /run.sh /gen_snapserver.sh

CMD ["/run.sh"]

```

### `gen_snapserver.sh`

Generates `snapserver.conf` from your add-on options.

```bash
#!/usr/bin/env bash
set -euo pipefail

CONF="/etc/snapserver.conf"
TMP="$(mktemp)"

cat > "$TMP" <<'EOF'
[http]
enabled = true
doc_root = /usr/share/snapserver/snapweb
EOF

# Read streams from options
# options.json path is standard in HA add-ons
jq -r '.streams[].name' /data/options.json | while read -r name; do
  # FLAC @ 48k/16/2 is a good default
  cat >> "$TMP" <<EOF
[stream.${name}]
source = pipe:///tmp/${name}?name=${name^}&codec=flac&sampleformat=48000:16:2
EOF
done

mv "$TMP" "$CONF"

```

### `run.sh`

Spins up Snapserver and one Snapclient per stream with its ALSA device.

```bash
#!/usr/bin/env bash
set -euo pipefail

echo "[INFO] Generating snapserver.conf from options..."
/gen_snapserver.sh

echo "[INFO] Starting Snapserver..."
snapserver -c /etc/snapserver.conf &
SERVER_PID=$!

sleep 2

# Start one snapclient per stream
STREAMS_JSON="/data/options.json"
COUNT=$(jq '.streams | length' "$STREAMS_JSON")

for i in $(seq 0 $((COUNT-1))); do
  NAME=$(jq -r ".streams[$i].name" "$STREAMS_JSON")
  DEV=$(jq -r ".streams[$i].device" "$STREAMS_JSON")

  echo "[INFO] Starting snapclient for stream '$NAME' on ALSA '$DEV'"
  snapclient \
    --host 127.0.0.1 \
    --stream "$NAME" \
    --player alsa \
    --soundcard "$DEV" \
    --name "rack-$NAME" &
done

# Keep foreground alive
wait $SERVER_PID

```

### `asound.conf`

- **Phase 1 (Sound Blaster)**: simple default.
- **Phase 2 (UMC1820)**: add per-pair PCMs.

```
# ---------- Phase 1: Sound Blaster (temporary) ----------
# Find the right card index with `aplay -l` in host logs if needed.
pcm.!default {
  type hw
  card 1
}
ctl.!default {
  type hw
  card 1
}

# ---------- Phase 2: UMC1820 mappings (uncomment when it arrives) ----------
# The UMC1820 presents 10 playback channels: 1-2 main, 3-10 line outs (4 stereo pairs).
# Name the raw device stably by card name:
# pcm.umc_raw {
#   type hw
#   card "UMC1820"
#   device 0
#   channels 10
# }
#
# pcm.umc_out_12 {
#   type route
#   slave.pcm "umc_raw"
#   slave.channels 10
#   ttable.0.0 1
#   ttable.1.1 1
# }
# pcm.umc_out_34 {
#   type route
#   slave.pcm "umc_raw"
#   slave.channels 10
#   ttable.0.2 1
#   ttable.1.3 1
# }
# pcm.umc_out_56 {
#   type route
#   slave.pcm "umc_raw"
#   slave.channels 10
#   ttable.0.4 1
#   ttable.1.5 1
# }
# pcm.umc_out_78 {
#   type route
#   slave.pcm "umc_raw"
#   slave.channels 10
#   ttable.0.6 1
#   ttable.1.7 1
# }
# pcm.umc_out_910 {
#   type route
#   slave.pcm "umc_raw"
#   slave.channels 10
#   ttable.0.8 1
#   ttable.1.9 1
# }

```

> After the UMC1820 is installed, edit the add-on Options to set:
> 
> - `kitchen.device: umc_out_12`
> - `living.device: umc_out_34`
> - `bedroom1.device: umc_out_56`
> - etc.

---

## Music Assistant Integration

1. **Enable External Snapserver** in Music Assistant and point to `127.0.0.1` (default Snapcast ports).
2. MA will show a **player per stream name** (Kitchen, Living…).
3. Configure each **Sat1** to join its matching stream.
4. Create a simple dashboard card with your 8 rooms (players).

---

## Home Assistant Automations (examples)

### TTS to the room that spoke

```yaml
alias: TTS - reply to invoking room
mode: parallel
trigger:
  - platform: event
    event_type: assist_satellite_triggered
    # You’ll emit this event with the room name from your Sat1 integration
    # or use whatever metadata your Sat1 exposes in HA.
action:
  - variables:
      room: "{{ trigger.event.data.room }}"
      player: "media_player.{{ room }}"   # MA player entity for the stream
  - service: tts.google_say
    target:
      entity_id: "{{ player }}"
    data:
      message: "Okay, playing your request in the {{ room }}."

```

### Mirror music to multiple rooms (grouping)

- In practice with Snapcast you **add the room’s rack client and Sat1 to the same stream**, so grouping is just “play to both” by using the stream.
- To play to *two* rooms, start a second stream and switch the second room’s clients to it, or temporarily add clients to the same stream (depending on how you prefer to manage).

---

## Commissioning Checklist

**Phase 0 (Sound Blaster test)**

1. Install add-on. Start with two streams: `kitchen`, `living` → `device: default`.
2. In MA, enable external Snapserver → confirm 2 players appear.
3. Wire Sound Blaster output → temporary amp/speaker (or loopback) and validate playback.
4. Point `kitchen` Sat1 to stream `kitchen`, say “play radio” → confirm Sat1 and rack output are in sync.

**Phase 1 (UMC1820 migration)**

1. Plug UMC1820 into NUC. Check HA logs for `aplay -l` (or attach a keyboard to confirm card name).
2. Replace `asound.conf` with UMC block (uncomment). Restart add-on.
3. In add-on Options, change `device` per stream to the correct `umc_out_*`.
4. TRS→RCA from each output pair to **Xantech** inputs 1..5. Set Xantech zones to those sources.
5. Validate per-room playback and volumes. Tweak levels to avoid clipping.

**Phase 2 (Scale up)**

- Add more streams to add-on Options (e.g., `bedroom2`, `office`).
- If you need more than 5 stereo zones from the rack, add a second interface and extend `asound.conf` with a second card (e.g., `umc2_out_12`, etc.).

---

## Future Options

- Replace/augment Xantech with a **modern IP matrix amp** later for simpler routing.
- Add **per-room DSP/EQ** (either in Sat1 or via Snapserver LADSPA if you want to get fancy).
- HA scripts for **night mode** (reduce volume after 22:00), **doorbell chimes** (play to specific streams), **TTS ducking**(lower music volume briefly during announcements).

---

## What you do next (quick start)

1. Create the **add-on folder** and paste the files above.
2. In HA → Settings → Add-ons → “Add from local” → install **Snapcast Multi-Output**.
3. Start with **Sound Blaster** (`device: default`) and 1–2 streams.
4. Point MA to the Snapserver and point Sat1 devices to the same streams.
5. Validate. Then swap to **UMC1820** and update `asound.conf` + add-on options.

If you want, tell me your exact **room list** and the **Xantech input numbers** you plan to use, and I’ll drop you a pre-filled add-on **Options** example plus the matching **asound.conf** with UMC1820 mappings for your first 5 rooms.

# Audio Flow

Awesome — here’s the end-to-end flow for **“Spotify Connect → Kitchen”** in your setup, plus the AirPlay variant. I’ll keep it super concrete so you can map it to entities and cables you’ll actually have.

# Spotify Connect → Kitchen (single room)

```
[Your Phone / Spotify App]
        │  (choose device: "Kitchen")
        ▼
[Music Assistant: Spotify Connect player "Kitchen"]
        │  (MA logs in to Spotify; pulls the stream as a receiver)
        ▼
[MA audio engine] ──► [Snapserver stream "kitchen" (pipe:///tmp/kitchen)]
        │                                  │
        │                                  ├────────► [Snapclient: Sat1-Kitchen] → tiny local Sat1 speaker (AEC ref)
        │                                  │
        │                                  └────────► [Snapclient: rack-kitchen] → ALSA "umc_out_12"
        │                                                                         │
        │                                                                         └──► TRS→RCA → [Xantech Input 1]
        │                                                                                                    │
        ▼                                                                                                    ▼
   MA UI state updates                                                                     [Ceiling speakers (Kitchen)]
      (track, artist, cover, timeline)

```

What’s happening:

- You pick **Kitchen** in the Spotify devices list.
- **Music Assistant (MA)** acts as the **Spotify Connect receiver** for that room.
- MA writes decoded PCM/FLAC into **Snapserver**’s `kitchen` stream (the pipe).
- Two **Snapclients** subscribed to `kitchen` play **in perfect sync**:
    - **Sat1-Kitchen** (local output) → gives the **XMOS AEC** a perfect reference for voice clarity.
    - **rack-kitchen** (running in your HA add-on) → routes via **UMC1820 out 1/2** → **Xantech Input 1** → in-ceiling speakers.

You still see just one target in your Spotify app (“Kitchen”), and one player in MA/HA (“Kitchen”). Clean.

---

# AirPlay → Living Room

Exactly the same shape, just swap Spotify Connect for AirPlay:

```
[iPhone / AirPlay menu]
        │  (choose "Living Room")
        ▼
[Music Assistant: AirPlay receiver "Living Room"]
        │
        ▼
[MA audio engine] ──► [Snapserver stream "living"]
                                       │
                                       ├──► [Snapclient: Sat1-Living]
                                       └──► [Snapclient: rack-living] → UMC1820 out 3/4 → Xantech Input 2 → Ceiling spk (Living)

```

---

# Controls & Where They Live

- **Select/Play/Pause/Seek**: Spotify app / AirPlay sender / MA UI — all reflected in MA state.
- **Per-room volume**:
    - In **MA**: the “Kitchen” player volume moves both clients together (Sat1 + rack).
    - On **Xantech**: you can still trim per-zone, but treat that as a “set and forget” gain; do daily volume via MA.
- **Voice/TTS**: Send TTS to the **same stream** that heard the command (e.g., Sat1-Kitchen) so replies come from Kitchen only (and in-ceiling speakers too if you want).

---

# Group Playback

Two common patterns:

1. **Temporary party group** (Kitchen + Living together)
- In MA, group “Kitchen” and “Living” → MA writes the same source into **both** Snapserver streams (or switches both clients to one stream, depending on how you prefer to manage).
- Result: Sat1-Kitchen + rack-Kitchen + Sat1-Living + rack-Living all play together, in sync.
1. **Permanent stereo pair in one room** (not your use case with ceiling speakers, but Sat1 supports it)
- Sat1 devices can be paired; still subscribe them to the room’s stream.

---

# Entity & Name Suggestions (HA/MA)

- **MA Players (become Spotify Connect / AirPlay targets):**
    - `media_player.kitchen` → Snapstream `kitchen`
    - `media_player.living` → Snapstream `living`
- **Sat1 Devices (internal to you; don’t expose as MA players):**
    - `sat1.kitchen` subscribes to `kitchen`
    - `sat1.living` subscribes to `living`
- **Rack Clients (add-on spawns them):**
    - `rack-kitchen` → `umc_out_12` → Xantech Input 1
    - `rack-living` → `umc_out_34` → Xantech Input 2

---

# TTS / Voice Automation Pattern

- When **Sat1-Kitchen** hears “what’s the weather,” your HA automation resolves `room = kitchen`, sets `player = media_player.kitchen`, then runs TTS service → plays only in **Kitchen** (Sat1 + rack speakers).
- If you want **ducking** (lower music briefly under TTS):
    - In automation: send `volume_set` to, say, 0.4, play TTS, then restore volume after a short delay.

---

# Latency & AEC Notes

- Keep **Sat1 playing locally** (even quietly) so the **XMOS** has a live reference to cancel.
- Snapcast syncs Sat1 and rack within a few milliseconds. If you hear “chorus” between Sat1 and ceiling speakers, lower Snapclient buffers slightly (rarely needed on wired LAN).
- Do **not** AirPlay/Spotify directly to the UMC/ALSAs; always route via **MA → Snapserver** so Sat1 gets the same stream for AEC.

---

# Troubleshooting Quicklist

- **Don’t see “Kitchen” in Spotify/AirPlay?**
    - Ensure MA’s Spotify/AirPlay providers are enabled and the **player for Kitchen** is active.
- **Music in ceiling speakers but not Sat1?**
    - Sat1 must be subscribed to the same **Snapcast stream name**. Check its firmware UI.
- **Echo on voice commands?**
    - Make sure Sat1 is actually outputting that stream (not muted/disabled) so the XMOS cancels it.
- **Drift or chorus between rooms?**
    - Check LAN stability; use wired where possible; keep Sat1 Wi-Fi solid; verify Snapserver/clients are on the same time base (Snapcast handles this, but network jitter can matter).

---

If you want, give me your **room list** and which **Xantech inputs** you plan to use, and I’ll plug those names straight into the add-on options and a ready-to-paste `asound.conf` for the UMC1820’s five stereo pairs.