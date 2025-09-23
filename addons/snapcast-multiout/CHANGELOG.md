# Changelog

All notable changes to this add-on will be documented in this file.

## [2025.09.23-9] - 2025-09-23 🎉 **PRODUCTION READY**

### Added - USB Audio Interface Support
- **USB audio device permissions** - Privileged container access for USB audio
- **Advanced device testing** - Improved ALSA accessibility testing with timeout protection
- **Device descriptions** - Human-readable descriptions for each stream configuration
- **USB Audio documentation** - Comprehensive setup guide for USB audio interfaces

### Enhanced - Multi-Room Audio Configuration
- **Kitchen**: Configured for Sound Blaster Play! 3 (hw:1,0)
- **Sitting Room**: Pre-configured for UMC1820 (hw:2,0)
- **Scalable setup** - Support for multiple UMC1820s (8+ stereo zones)
- **Device fallback** - Automatic fallback to default if configured device unavailable

### Fixed - USB Audio Access
- **Permissions handling** - Automatic audio group permissions for USB devices
- **Device detection** - Improved USB audio device scanning and validation
- **Container privileges** - Added SYS_ADMIN for proper USB audio access

### Technical Improvements
- **Performance optimized** - Production-ready for 24/7 operation
- **USB bandwidth handling** - Support for multiple USB audio interfaces
- **Error recovery** - Better handling of device access failures

## [2025.09.23-8] - 2025-09-23

### Fixed - Stream Configuration & Management
- **Stream generation bug** - Fixed subshell issue preventing multiple streams from being created
- **Named pipe management** - Proper creation and cleanup of stream pipe files
- **Process cleanup** - Improved snapcast process management and port cleanup
- **Pipe cleanup** - Added pipe file cleanup in shutdown handler

### Enhanced - Audio Streaming
- **Multiple streams working** - Kitchen and sitting_room streams now properly separated
- **Music Assistant integration** - Fixed "No players available to form syncgroup" errors
- **Independent playback** - Each room can now play different content simultaneously

### Technical Details
- **Named pipes**: `/tmp/kitchen` and `/tmp/sitting_room` properly created
- **Stream separation**: Music Assistant can control each stream independently
- **Port management**: Better cleanup prevents "Address in use" errors

## [2025.09.23-7] - 2025-09-23

### Fixed - Client Configuration & Naming
- **Snapclient parameters** - Removed invalid `--stream` parameter causing Fatal errors
- **Client identification** - Added `--hostID` for proper client naming
- **Process cleanup** - Improved startup process cleanup
- **Port binding** - Better handling of port conflicts

### Enhanced - Reliability
- **Error elimination** - No more Fatal snapclient startup errors
- **Client naming** - Proper identification in Snapweb interface
- **Stability** - Improved runtime stability and error handling

## [2025.09.23-6] - 2025-09-23

### Added - Container Optimization & CI/CD
- **GitHub Container Registry** - Pre-built containers for faster deployment
- **Multi-architecture builds** - AMD64 and ARM64 support
- **Build caching** - GitHub Actions caching for faster builds (1h31m → <2m)
- **Date-based versioning** - YYYY.MM.DD-build format for better tracking

### Enhanced - Performance
- **Container caching** - Eliminates version caching issues
- **Build optimization** - Multi-stage Docker builds with layer caching
- **Deployment speed** - Significantly faster addon updates

### Technical Improvements
- **GitHub Actions workflow** - Automated multi-platform container builds
- **Container registry** - ghcr.io/damianflynn/snapcast-multiout
- **Version extraction** - Automated version management from config.yaml

## [0.31.0-2] - 2025-09-18

### Added - Initial Release
- **Snapcast Multi-Output** - Initial release with multi-room audio support
- **Snapserver/Snapclient v0.32.4** - Built from source with Alpine Linux 3.19
- **Multiple audio streams** - Dynamic stream and client creation
- **Web interface** - Snapweb at port 1780 for configuration
- **Music Assistant integration** - Seamless HA media control
- **USB audio support** - UMC1820 and similar device support
- **ALSA device enumeration** - Audio device discovery and listing

### Technical Foundation
- **FLAC compression** - High-quality audio streaming
- **Host network mode** - Optimal audio performance
- **Device mapping** - `/dev/snd` access for audio hardware
- **Signal handling** - Graceful shutdown and cleanup
- **Runtime optimization** - Smaller container image size

---

## Upgrade Path

### From any version to 2025.09.23-9:
1. **Stop the addon**
2. **Update configuration** - Add device descriptions if desired
3. **Restart addon** - New version will auto-pull from container registry
4. **Test USB audio** - Verify your Sound Blaster/UMC1820 is detected
5. **Configure Music Assistant** - Create room groups for independent playback

### Hardware Roadmap:
- **Current**: Sound Blaster Play! 3 (development/testing)
- **Next**: UMC1820 (4 stereo zones for production)
- **Future**: Multiple UMC1820s (8+ zones for large installations)