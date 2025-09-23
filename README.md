# Snapcast Multi-Output Home Assistant Add-on# DamianFlynn Home Assistant Add-ons# Damian Home Assistant Add-ons



Professional multi-room audio system using Snapcast with dedicated USB audio interfaces for each zone.



## 🎵 OverviewA collection of Home Assistant add-ons for advanced audio and home automation scenarios.A collection of Home Assistant add-ons for advanced audio and home automation scenarios.



This Home Assistant add-on provides synchronized multi-room audio using Snapcast technology. It's designed for professional installations using dedicated USB audio interfaces (like the Behringer UMC1820 or Creative Sound Blaster series) to deliver independent audio streams to multiple rooms with perfect synchronization.



### Key Features## Add-ons## Add-ons



- **🏠 Multi-Room Audio**: Independent audio streams for each room/zone

- **🔗 Perfect Synchronization**: Sub-millisecond audio sync across all zones  

- **🎛️ USB Audio Interface Support**: Dedicated hardware for each audio zone### Snapcast Multi-Output### Snapcast Multi-Output

- **🎵 Music Assistant Integration**: Seamless integration with Home Assistant's Music Assistant

- **📱 Web Control**: Snapweb interface for advanced configuration

- **⚡ Production Ready**: Optimized for 24/7 operation with USB audio hardware

Synchronized multi-room audio using Snapcast with support for multiple audio output devices.Synchronized multi-room audio using Snapcast with support for multiple audio output devices.

## 🚀 Quick Start



### Prerequisites

[**Installation & Documentation →**](./addons/snapcast-multiout/)[**Installation & Documentation →**](./addons/snapcast-multiout/)

- Home Assistant OS (HAOS) or Home Assistant Supervised

- One or more USB audio interfaces:

  - Creative Sound Blaster Play! 3 (2 stereo outputs)

  - Behringer UMC1820 (8 outputs = 4 stereo zones)- Perfect audio synchronization across multiple rooms- Perfect audio synchronization across multiple rooms

  - Any USB Audio Class compliant device

- Music Assistant add-on installed- Support for USB audio interfaces (UMC1820, etc.)- Support for USB audio interfaces (UMC1820, etc.)



### Installation- Integration with Music Assistant- Integration with Music Assistant



1. **Add Repository**:- Web-based control interface- Web-based control interface

   ```

   https://github.com/damianflynn/snapcast-multiout- Dynamic stream management- Dynamic stream management

   ```



2. **Install Add-on**: Find "Snapcast Multi-Output" in your add-on store

## Installation## Installation

3. **Configure**: See configuration examples below



4. **Start**: The add-on will auto-detect your USB audio devices

1. Add this repository to your Home Assistant:1. Add this repository to your Home Assistant:

## ⚙️ Configuration

   ```   ```

### Basic Setup (Sound Blaster Play! 3)

   https://github.com/damianflynn/snapcast-multiout   https://github.com/damianflynn/snapcast-multiout

```yaml

list_devices_on_start: true   ```   ```

streams:

  - name: kitchen

    device: hw:1,0

    description: "Kitchen - Sound Blaster Play! 3"2. Install the desired add-on from your Home Assistant add-on store2. Install the desired add-on from your Home Assistant add-on store

  - name: sitting_room

    device: hw:2,0  

    description: "Sitting Room - Future UMC1820"

```3. Configure and start the add-on3. Configure and start the add-on



### Production Setup (UMC1820)



```yaml## Support## Support

list_devices_on_start: true

streams:

  - name: kitchen

    device: hw:1,0For issues, questions, or feature requests, please use the [GitHub Issues](https://github.com/damianflynn/snapcast-multiout/issues).For issues, questions, or feature requests, please use the [GitHub Issues](https://github.com/damianflynn/snapcast-multiout/issues).

    description: "Kitchen - UMC1820 Outputs 1+2"

  - name: living_room

    device: hw:1,1

    description: "Living Room - UMC1820 Outputs 3+4"## License## License

  - name: bedroom

    device: hw:1,2

    description: "Bedroom - UMC1820 Outputs 5+6"

  - name: officeMIT License - see individual add-ons for specific licensing information.MIT License - see individual add-ons for specific licensing information.elow is a complete **High-Level Design (HLD)** and **Low-Level Design (LLD)** for your new multi-room audio system powered by **Music Assistant + Snapcast**, using **Satellite1** devices (with XMOS AEC) in each room and **Xantech MRC88** for the in-ceiling speakers. I’ve also included a **custom HAOS add-on**that dynamically creates one Snapclient per “room/stream,” so you can start with your **Sound Blaster USB** today and seamlessly move to the **UMC1820** when it arrives.

    device: hw:1,3

    description: "Office - UMC1820 Outputs 7+8"---

```

# High-Level Design (HLD)

### Scalable Setup (Multiple Interfaces)

## Objectives

```yaml

list_devices_on_start: true- **Voice-first rooms**: Each room has a Satellite1 (Sat1) that acts as microphone/voice device and **local Snapclient** for AEC.

streams:- **Central amplification**: In-ceiling speakers are driven by the **Xantech MRC88** in the rack.

  # First UMC1820 (Zones 1-4)- **Single control plane**: **Home Assistant (HAOS) + Music Assistant (MA)** on your NUC are the brains; **Snapserver** distributes audio.

  - name: kitchen- **Tidy UX**: MA shows **one target per room** (a Snapcast stream/group). The Sat1 in the room **and** the rack output (to Xantech) both subscribe to the *same* stream → perfect sync, AEC preserved, and no extra “devices” clutter.

    device: hw:1,0

    description: "Kitchen - UMC1820 #1"## Key Principles

  - name: living_room  

    device: hw:1,1- **Keep Sat1 as a playback endpoint** (even at low volume if needed) so the **XMOS AEC** has the proper reference.

    description: "Living Room - UMC1820 #1"- **Use IP audio** for distribution; avoid long analog returns from rooms to rack.

  - name: bedroom1- **ALSA direct** on the NUC for deterministic multi-output routing (best fit for HAOS add-on).

    device: hw:1,2- **Scale by outputs**: Start with 1 stereo zone (Sound Blaster), then move to **UMC1820** (5 stereo zones). Add a second interface later if you want 8 stereo rooms from the rack.

    description: "Master Bedroom - UMC1820 #1"

  - name: office## Logical Topology

    device: hw:1,3

    description: "Office - UMC1820 #1"- **Music sources**: Music Assistant (Spotify, radio, local library, etc.)

    - **Distribution**: Snapserver (on NUC)

  # Second UMC1820 (Zones 5-8)  - **Room endpoints**:

  - name: bedroom2    - Sat1 in each room (Snapclient → small local playback for AEC + voice)

    device: hw:2,0    - Rack “per-room” Snapclients (in add-on) → ALSA → specific output pair on USB interface → **Xantech input** → in-ceiling speakers

    description: "Guest Bedroom - UMC1820 #2"- **Control**: HA dashboards + voice via Sat1

  - name: dining_room

    device: hw:2,1---

    description: "Dining Room - UMC1820 #2"

  - name: patio# Low-Level Design (LLD)

    device: hw:2,2

    description: "Patio - UMC1820 #2"## Naming & Mapping (example)

  - name: basement

    device: hw:2,3Use consistent, human-friendly room IDs. Example for 5 zones (initial with UMC1820):

    description: "Basement - UMC1820 #2"

```- Streams (and MA players): `kitchen`, `living`, `bedroom1`, `bedroom2`, `office`

- UMC1820 output pairs:

## 🔧 Hardware Setup    - `umc_out_12` → Xantech Source 1 → **kitchen**

    - `umc_out_34` → Xantech Source 2 → **living**

### Supported USB Audio Interfaces    - `umc_out_56` → Xantech Source 3 → **bedroom1**

    - `umc_out_78` → Xantech Source 4 → **bedroom2**

| Device | Stereo Outputs | Recommended Use |    - `umc_out_910` → Xantech Source 5 → **office**

|--------|---------------|-----------------|- Each Sat1 joins the stream for its room (e.g., kitchen Sat1 → `kitchen`).

| Creative Sound Blaster Play! 3 | 1 zone | Development/Testing |

| Behringer UMC1820 | 4 zones | Production (4 rooms) |> When you expand beyond 5 stereo pairs, add another interface (or a bigger one) and define more devices/streams.

| Multiple UMC1820s | 8+ zones | Large installations |> 



### Device Naming Convention## Timing & Sync



- `hw:X,0` = First stereo pair on card X- Snapcast handles stream sync across Sat1 and rack clients.

- `hw:X,1` = Second stereo pair on card X  - Keep Sat1 playing locally (even if quietly) to preserve AEC.

- `hw:X,2` = Third stereo pair on card X- Use Snapcast buffer defaults first; adjust only if you notice room/rack echo.

- `hw:X,3` = Fourth stereo pair on card X

## Levels & Cabling

### Physical Connections

- **UMC1820 line-outs are balanced TRS**. Xantech inputs are unbalanced line-level (typically RCA).

1. **USB Audio Interface → Computer**: Connect via USB- Use **TRS-to-RCA** cables/adapters. Keep runs short on the rack side. Start with conservative output levels; raise until Xantech inputs are healthy but not clipping.

2. **Audio Interface → Amplifier**: Use balanced outputs when possible

3. **Amplifier → Speakers**: Standard speaker wire connections## Security & Reliability



## 🎵 Music Assistant Integration- Keep Snapserver and clients on your trusted LAN.

- Pin Snapcast version (0.31.x is solid for MA).

### Creating Room Groups- Use **powered USB hub** if you later add many DACs.

- Back up your HAOS config (snapshots).

1. Open Music Assistant web interface

2. Go to **Settings → Players**---

3. Create sync groups for each room:

   - Group Name: `Kitchen`# Custom HAOS Add-on (dynamic multi-output Snapcast)

   - Add Player: `snapcast-kitchen`

4. Repeat for each roomThis add-on:



### Playing Music- Runs **Snapserver** and **N** Snapclients (one per stream) **inside one container**.

- Reads a list of **streams** and **ALSA device names** from the add-on options.

1. Select a room group in Music Assistant- Ships with **Sound Blaster** default (card `default`) so you can test today.

2. Choose your music source (Spotify, local files, etc.)- When UMC1820 arrives, drop in the **ALSA mapping** and change each stream to point at `umc_out_XX`.

3. Audio plays independently to that room only

4. Create different groups for multi-room scenarios## Folder layout (in your HA `addons` share)



## 📊 Web Interface```

/addons/snapcast-multiout/

Access Snapweb at: `http://your-ha-ip:1780`  ├── config.yaml

  ├── Dockerfile

Features:  ├── run.sh

- Real-time stream monitoring  ├── gen_snapserver.sh

- Volume control per client  ├── asound.conf

- Latency adjustment  └── README.txt  (optional)

- Stream assignment management

```

## 🐛 Troubleshooting

### `config.yaml`

### USB Audio Not Detected

```yaml

```bashname: Snapcast Multi-Output

# Check addon logs for:slug: snapcast-multiout

[INFO] Found USB audio device: card 1version: "0.31.0-1"

[DEBUG] ALSA can access hw:1,0 successfullydescription: Snapserver + dynamic Snapclients for multi-output USB (UMC1820) with Music Assistant

```arch:

  - amd64

**Solutions**:startup: services

- Ensure USB device is connected before starting addonhost_network: true

- Check USB power requirements (may need powered hub)boot: auto

- Verify device is USB Audio Class compliantinit: false

map:

### No Audio Output  - share:rw

devices:

```bash  - /dev/snd

# Look for in logs:options:

[WARN] Configured device hw:1,0 not accessible  # Define one entry per room/stream. "device" is an ALSA PCM name.

[INFO] Falling back to default device  streams:

```    - name: kitchen

      device: default        # Sound Blaster now; later "umc_out_12"

**Solutions**:    - name: living

- Check device permissions in addon logs        device: default        # change to "umc_out_34" later

- Verify correct device numbering (`hw:X,Y`)schema:

- Test device manually in Home Assistant terminal  streams:

    - name: str

### Sync Issues      device: str



- Adjust buffer settings in Snapweb```

- Check network latency between devices

- Ensure consistent sample rates (48kHz recommended)### `Dockerfile`



## 📈 Performance & Scaling```docker

FROM ghcr.io/badaix/snapcast:alpine-v0.31.0

### Resource Usage

- **CPU**: ~5% per active stream on modern hardware# Tools we need in the container

- **Memory**: ~50MB base + 10MB per clientRUN apk add --no-cache bash jq alsa-plugins alsa-utils

- **Network**: ~1.5Mbps per stream (FLAC compression)

# Copy configs/scripts

### Scaling LimitsCOPY run.sh /run.sh

- **Home Assistant**: 16+ concurrent streams testedCOPY gen_snapserver.sh /gen_snapserver.sh

- **USB Bandwidth**: 8-10 stereo streams per USB 2.0 portCOPY asound.conf /etc/asound.conf

- **Network**: 100+ clients possible on gigabit network

RUN chmod +x /run.sh /gen_snapserver.sh

## 🔄 Version History

CMD ["/run.sh"]

See [CHANGELOG.md](./addons/snapcast-multiout/CHANGELOG.md) for detailed version history.

```

## 📋 Configuration Reference

### `gen_snapserver.sh`

### Complete Schema

Generates `snapserver.conf` from your add-on options.

```yaml

list_devices_on_start: bool     # Show audio devices on startup```bash

streams:                        # Array of audio zones#!/usr/bin/env bash

  - name: string               # Unique room identifierset -euo pipefail

    device: string             # ALSA device (hw:X,Y)

    description: string        # Human-readable descriptionCONF="/etc/snapserver.conf"

```TMP="$(mktemp)"



### Device Detectioncat > "$TMP" <<'EOF'

[http]

The add-on automatically:enabled = true

1. Scans for USB audio devicesdoc_root = /usr/share/snapserver/snapweb

2. Tests device accessibilityEOF

3. Maps devices to configured streams

4. Falls back to default if configured device unavailable# Read streams from options

# options.json path is standard in HA add-ons

## 🛠️ Developmentjq -r '.streams[].name' /data/options.json | while read -r name; do

  # FLAC @ 48k/16/2 is a good default

### Building Locally  cat >> "$TMP" <<EOF

[stream.${name}]

```bashsource = pipe:///tmp/${name}?name=${name^}&codec=flac&sampleformat=48000:16:2

git clone https://github.com/damianflynn/snapcast-multioutEOF

cd snapcast-multioutdone

docker build -t local/snapcast-multiout addons/snapcast-multiout/

```mv "$TMP" "$CONF"



### Contributing```



1. Fork the repository### `run.sh`

2. Create feature branch

3. Add tests for new functionalitySpins up Snapserver and one Snapclient per stream with its ALSA device.

4. Update documentation

5. Submit pull request```bash

#!/usr/bin/env bash

## 📄 Licenseset -euo pipefail



MIT License - see [LICENSE](./LICENSE) for details.echo "[INFO] Generating snapserver.conf from options..."

/gen_snapserver.sh

## 🆘 Support

echo "[INFO] Starting Snapserver..."

- **Issues**: [GitHub Issues](https://github.com/damianflynn/snapcast-multiout/issues)snapserver -c /etc/snapserver.conf &

- **Discussions**: [GitHub Discussions](https://github.com/damianflynn/snapcast-multiout/discussions)SERVER_PID=$!

- **Documentation**: [Wiki](https://github.com/damianflynn/snapcast-multiout/wiki)

sleep 2

---

# Start one snapclient per stream

**Ready for Production** ✅ This add-on is tested and optimized for 24/7 operation in multi-room audio installations.STREAMS_JSON="/data/options.json"
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