# Technical Documentation

This document contains detailed technical information about the Snapcast Multi-Output add-on implementation.

## Architecture Overview

Below is a complete **High-Level Design (HLD)** and **Low-Level Design (LLD)** for your new multi-room audio system powered by **Music Assistant + Snapcast**, using **Satellite1** devices (with XMOS AEC) in each room and **Xantech MRC88** for the in-ceiling speakers. I've also included a **custom HAOS add-on**that dynamically creates one Snapclient per "room/stream," so you can start with your **Sound Blaster USB** today and seamlessly move to the **UMC1820** when it arrives.

---

# High-Level Design (HLD)

## Objectives

- **Voice-first rooms**: Each room has a Satellite1 (Sat1) that acts as microphone/voice device and **local Snapclient** for AEC.
- **Central amplification**: In-ceiling speakers are driven by the **Xantech MRC88** in the rack.
- **Single control plane**: **Home Assistant (HAOS) + Music Assistant (MA)** on your NUC are the brains; **Snapserver** distributes audio.
- **Tidy UX**: MA shows **one target per room** (a Snapcast stream/group). The Sat1 in the room **and** the rack output (to Xantech) both subscribe to the *same* stream → perfect sync, AEC preserved, and no extra "devices" clutter.

## Key Principles

- **Keep Sat1 as a playback endpoint** (even at low volume if needed) so the **XMOS AEC** has the proper reference.
- **Use IP audio** for distribution; avoid long analog returns from rooms to rack.
- **ALSA direct** on the NUC for deterministic multi-output routing (best fit for HAOS add-on).
- **Scale by outputs**: Start with 1 stereo zone (Sound Blaster), then move to **UMC1820** (5 stereo zones). Add a second interface later if you want 8 stereo rooms from the rack.

## Logical Topology

- **Music sources**: Music Assistant (Spotify, radio, local library, etc.)
- **Distribution**: Snapserver (on NUC)
- **Room endpoints**:
    - Sat1 in each room (Snapclient → small local playback for AEC + voice)
    - Rack "per-room" Snapclients (in add-on) → ALSA → specific output pair on USB interface → **Xantech input** → in-ceiling speakers
- **Control**: HA dashboards + voice via Sat1

---

# Low-Level Design (LLD)

## Audio Device Configuration

### Stereo Pair Mapping

The add-on treats each ALSA device as a complete stereo pair:

- **Sound Blaster X-Fi**: 2 stereo outputs (4 channels total)
  - `hw:1,0` → Outputs 1+2 (L+R for room 1)
  - `hw:1,1` → Outputs 3+4 (L+R for room 2)

- **Behringer UMC1820**: 4 stereo outputs (8 channels total)
  - `hw:2,0` → Outputs 1+2 (L+R for room 1)
  - `hw:2,1` → Outputs 3+4 (L+R for room 2)
  - `hw:2,2` → Outputs 5+6 (L+R for room 3)
  - `hw:2,3` → Outputs 7+8 (L+R for room 4)

### Scaling Your Setup

#### Phase 1: Start with Sound Blaster (2 stereo rooms)
```yaml
streams:
  - name: kitchen
    device: hw:1,0
  - name: living_room
    device: hw:1,1
```

#### Phase 2: Add UMC1820 (6 total stereo rooms)
```yaml
streams:
  # Keep existing Sound Blaster rooms
  - name: kitchen
    device: hw:1,0
  - name: living_room
    device: hw:1,1
  
  # Add UMC1820 rooms
  - name: bedroom1
    device: hw:2,0
  - name: bedroom2
    device: hw:2,1
  - name: office
    device: hw:2,2
  - name: dining_room
    device: hw:2,3
```

#### Phase 3: Second UMC1820 (10 total stereo rooms)
```yaml
streams:
  # Sound Blaster (2 rooms)
  - name: kitchen
    device: hw:1,0
  - name: living_room
    device: hw:1,1
  
  # First UMC1820 (4 rooms)
  - name: bedroom1
    device: hw:2,0
  - name: bedroom2
    device: hw:2,1
  - name: office
    device: hw:2,2
  - name: dining_room
    device: hw:2,3
  
  # Second UMC1820 (4 more rooms)
  - name: basement
    device: hw:3,0
  - name: garage
    device: hw:3,1
  - name: guest_room
    device: hw:3,2
  - name: workshop
    device: hw:3,3
```

### Hardware Considerations

#### USB Bandwidth
- Sound Blaster: ~1MB/s (minimal impact)
- UMC1820: ~4MB/s per device
- Use separate USB controllers/hubs for multiple UMC1820s

#### Amplifier Connections
- Use **balanced TRS → unbalanced RCA** cables for UMC1820
- Sound Blaster outputs are typically unbalanced
- Keep cable runs short to minimize noise
- Set conservative output levels initially

#### Synchronization
- All outputs maintain perfect sync via Snapcast
- No additional timing configuration needed
- Latency is automatically managed across all devices

## Build Process

The add-on builds Snapcast from source using Alpine Linux, including:

- Compilation from GitHub source with necessary patches for Alpine compatibility
- Runtime library management for optimal image size
- ALSA integration for multi-channel audio device support

## Configuration Schema

The add-on supports the following configuration options:

```yaml
list_devices_on_start: bool  # Show available audio devices in logs
streams:                     # Array of audio streams/rooms
  - name: str               # Room/stream identifier
    device: str             # ALSA device name (e.g., hw:0,0)
```

## Process Management

The add-on runs:
- One Snapserver instance (centralized audio distribution)
- Multiple Snapclient instances (one per configured stream)
- Proper signal handling for graceful shutdown

## Port Usage

- **1704**: Snapcast audio stream port
- **1705**: Snapcast control port  
- **1780**: Snapcast web interface

## Troubleshooting

### Audio Device Issues
- Use `list_devices_on_start: true` to see available devices
- Check device permissions with `/dev/snd` mapping
- Verify ALSA device names with `aplay -L`
- Ensure USB interfaces are properly powered

### Stereo Audio Problems
- **Only one channel playing**: Check cable connections and amplifier settings
- **Mono audio**: Verify source is sending stereo and device supports stereo output
- **No audio**: Check device permissions and ALSA device names
- **Distorted audio**: Reduce output levels, check for USB power issues

### Multi-Device Setup
- **Devices not detected**: Check USB power and try different USB ports
- **Audio dropouts**: Use separate USB controllers for multiple interfaces
- **Sync issues**: Snapcast handles synchronization automatically - check network connectivity
- **Device numbering changes**: Use device names like `hw:UMC1820,0` instead of numbers

### Connection Issues
- Ensure ports 1704, 1705, 1780 are accessible
- Check network connectivity between clients and server
- Review logs for specific error messages
- Verify Home Assistant can access USB audio devices

### Performance Optimization
- Use powered USB hubs for multiple interfaces
- Keep USB cable lengths reasonable (<3 meters)
- Monitor CPU usage with multiple high-resolution streams
- Consider dedicated USB controllers for professional setups