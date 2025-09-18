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
    device: hw:0,0
  - name: kitchen  
    device: hw:0,1
  - name: bedroom
    device: hw:0,2
```

### Configuration Options

- **list_devices_on_start** (boolean): Show available ALSA audio devices in the logs when starting
- **streams** (list): Array of audio streams/zones to create
  - **name** (string): Unique identifier for the room/zone
  - **device** (string): ALSA device name (use `hw:CARD,DEVICE` format)

### Finding Audio Devices

Enable `list_devices_on_start: true` and check the add-on logs to see available audio devices on your system.

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