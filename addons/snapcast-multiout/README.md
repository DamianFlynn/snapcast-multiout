# Snapcast Multi-Output

Professional multi-room audio system using Snapcast with dedicated USB audio interfaces.

## About

This add-on provides synchronized multi-room audio using Snapcast technology, designed for professional installations with USB audio interfaces like the Behringer UMC1820 or Creative Sound Blaster series.

**Key Features:**
- **🏠 Independent room streams** - Each room gets its own audio stream
- **🔗 Perfect synchronization** - Sub-millisecond timing across all zones
- **🎛️ USB audio interface support** - Dedicated hardware per zone
- **🎵 Music Assistant integration** - Seamless HA media control
- **📱 Web interface** - Advanced configuration via Snapweb
- **⚡ Production ready** - Optimized for 24/7 operation

## Installation

1. Add this repository to your Home Assistant add-on store:
   ```
   https://github.com/damianflynn/snapcast-multiout
   ```

2. Install the "Snapcast Multi-Output" add-on
3. Configure your streams (see examples below)
4. Start the add-on

## Configuration

### Current Setup (Sound Blaster Play! 3)

```yaml
list_devices_on_start: true
streams:
  - name: kitchen
    device: hw:1,0
    description: "Kitchen - Sound Blaster Play! 3"
  - name: sitting_room
    device: hw:2,0  
    description: "Sitting Room - Future UMC1820"
```

### Production Setup (UMC1820)

```yaml
list_devices_on_start: true
streams:
  - name: kitchen
    device: hw:1,0
    description: "Kitchen - UMC1820 Outputs 1+2"
  - name: living_room
    device: hw:1,1
    description: "Living Room - UMC1820 Outputs 3+4"
  - name: bedroom
    device: hw:1,2
    description: "Bedroom - UMC1820 Outputs 5+6"
  - name: office
    device: hw:1,3
    description: "Office - UMC1820 Outputs 7+8"
```

### Large Installation (Multiple UMC1820s)

```yaml
list_devices_on_start: true
streams:
  # First UMC1820 - Main Living Areas
  - name: kitchen
    device: hw:1,0
    description: "Kitchen - UMC1820 #1"
  - name: living_room
    device: hw:1,1
    description: "Living Room - UMC1820 #1"
  - name: dining_room
    device: hw:1,2
    description: "Dining Room - UMC1820 #1"
  - name: office
    device: hw:1,3
    description: "Office - UMC1820 #1"
    
  # Second UMC1820 - Bedrooms & Outdoor
  - name: master_bedroom
    device: hw:2,0
    description: "Master Bedroom - UMC1820 #2"
  - name: guest_bedroom
    device: hw:2,1
    description: "Guest Bedroom - UMC1820 #2"
  - name: patio
    device: hw:2,2
    description: "Patio - UMC1820 #2"
  - name: basement
    device: hw:2,3
    description: "Basement - UMC1820 #2"
```
    device: hw:2,0
  - name: dining_room
    device: hw:2,1
  - name: basement
    device: hw:2,2
  - name: garage
    device: hw:2,3
```

### Finding Audio Devices

1. Enable `list_devices_on_start: true`
2. Connect your USB audio interface(s)
3. Start the add-on
4. Check the logs to see available devices:

```
----- ALSA PCMs (playback) -----
hw:CARD=Creative,DEV=0
    Creative Sound Blaster, USB Audio
hw:CARD=UMC1820,DEV=0  
    Behringer UMC1820, USB Audio
hw:CARD=UMC1820,DEV=1
    Behringer UMC1820, USB Audio #1
```

5. Use the device names in your configuration (e.g., `hw:UMC1820,0` or `hw:1,0`)

### Stereo Audio Verification

Each configured stream should output **stereo audio**:
- Left channel audio → Left speaker in room
- Right channel audio → Right speaker in room
- Perfect synchronization across all rooms when grouped

If you hear mono audio or only one channel, check:
- ALSA device configuration
- Cable connections to amplifiers
- Source audio format (ensure stereo input)

## Usage

1. **Configure your streams** in the add-on configuration
2. **Start the add-on** - it will create one Snapclient per configured stream
3. **Access the web interface** at `http://your-home-assistant:1780`
4. **Use with Music Assistant** or other media players that support Snapcast

## Network Ports

The add-on uses these ports:
- **1704**: Snapcast audio streaming
- **1705**: Snapcast control protocol  
- **1780**: Web interface

## Integration with Music Assistant

This add-on works perfectly with Music Assistant:

1. Install and configure Music Assistant
2. Add Snapcast streams as playback targets
3. Group streams together for multi-room playback
4. Control everything through Home Assistant dashboards

## Hardware Requirements

- Home Assistant with audio device access (`/dev/snd`)
- USB audio interface or sound card with multiple outputs
- Network connectivity for Snapcast clients (if using external devices)

## Support

For issues, questions, or feature requests, please use the GitHub repository.

## Changelog

### Version 0.31.0-2
- Initial release
- Built from Snapcast source v0.32.4
- Support for multiple audio streams
- Web interface included
- ALSA device enumeration