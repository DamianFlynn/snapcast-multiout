# Changelog

All notable changes to this add-on will be documented in this file.

## [0.31.0-2] - 2025-09-18

### Added
- Initial release of Snapcast Multi-Output add-on
- Built from Snapcast source v0.32.4
- Support for multiple simultaneous audio streams
- Dynamic Snapclient creation (one per configured stream)
- Web interface at port 1780
- ALSA device enumeration and listing
- Integration with Music Assistant
- Support for USB audio interfaces (UMC1820, etc.)
- Proper signal handling for graceful shutdown
- Runtime library optimization for smaller image size

### Technical Details
- Snapserver and Snapclient v0.32.4
- Alpine Linux 3.19 base image
- FLAC compression for audio streams
- Support for multiple audio device types
- Automatic stream configuration generation

### Configuration
- `list_devices_on_start`: Show available audio devices in logs
- `streams`: Array of room/device configurations
- Host network mode for optimal audio performance
- Device mapping for `/dev/snd` access