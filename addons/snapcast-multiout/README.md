# Snapcast Multi-Output

A Home Assistant add-on that provides synchronized multi-room audio using Snapcast with support for multiple audio output devices.

## About

This add-on runs both Snapserver and multiple Snapclient instances, allowing you to:

- Stream audio to multiple rooms/zones simultaneously  
- Maintain perfect synchronization across all outputs
- Support various audio devices (USB audio interfaces, sound cards)
- Integrate seamlessly with Music Assistant and other Home Assistant media players

Perfect for multi-room audio setups using USB audio interfaces like the Behringer UMC1820 or similar devices.

## Installation

1. Add this repository to your Home Assistant add-on store
2. Install the "Snapcast Multi-Output" add-on
3. Configure your audio streams (see Configuration section)
4. Start the add-on

## Configuration

### Basic Configuration

```yaml
list_devices_on_start: true
streams:
  - name: living_room
    device: hw:1,0
  - name: kitchen  
    device: hw:1,1
  - name: bedroom
    device: hw:2,0
```

### Configuration Options

- **list_devices_on_start** (boolean): Show available ALSA audio devices in the logs when starting
- **streams** (list): Array of audio streams/zones to create
  - **name** (string): Unique identifier for the room/zone
  - **device** (string): ALSA device name (use `hw:CARD,DEVICE` format)

### Understanding ALSA Device Names

Each `hw:X,Y` device represents a **stereo pair** (left + right channels):
- `hw:1,0` = Card 1, Device 0 (first stereo pair - channels 1+2)
- `hw:1,1` = Card 1, Device 1 (second stereo pair - channels 3+4)
- `hw:2,0` = Card 2, Device 0 (different USB interface)

### Multi-Device Stereo Setup Examples

#### Single Sound Blaster (2 stereo rooms)
```yaml
list_devices_on_start: true
streams:
  - name: kitchen
    device: hw:1,0      # Sound Blaster stereo pair 1
  - name: living_room
    device: hw:1,1      # Sound Blaster stereo pair 2
```

#### Sound Blaster + UMC1820 (6 stereo rooms)
```yaml
list_devices_on_start: true
streams:
  # Sound Blaster (2 stereo outputs)
  - name: kitchen
    device: hw:1,0
  - name: living_room
    device: hw:1,1
  
  # UMC1820 (4 stereo outputs)  
  - name: bedroom1
    device: hw:2,0      # UMC1820 outputs 1+2
  - name: bedroom2
    device: hw:2,1      # UMC1820 outputs 3+4
  - name: office
    device: hw:2,2      # UMC1820 outputs 5+6
  - name: dining_room
    device: hw:2,3      # UMC1820 outputs 7+8
```

#### Dual UMC1820 Setup (8 stereo rooms)
```yaml
list_devices_on_start: true
streams:
  # First UMC1820
  - name: kitchen
    device: hw:1,0
  - name: living_room
    device: hw:1,1
  - name: bedroom1
    device: hw:1,2
  - name: bedroom2
    device: hw:1,3
  
  # Second UMC1820
  - name: office
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