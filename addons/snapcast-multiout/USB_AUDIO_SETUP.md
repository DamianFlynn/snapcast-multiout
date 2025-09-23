# USB Audio Device Setup Guide

## Supported USB Audio Interfaces

This addon is designed to work with multiple USB audio interfaces for multi-room audio:

### Current Setup
- **Kitchen**: Sound Blaster Play! 3 (hw:1,0)
- **Sitting Room**: UMC1820 (hw:2,0) - when purchased

### Future Expansion
- Additional UMC1820 or Sound Blaster devices for up to 8 stereo zones
- Each USB audio interface provides stereo output for one room/zone

## Device Configuration

Configure each room in `config.yaml`:

```yaml
streams:
  - name: kitchen
    device: hw:1,0  # Sound Blaster Play! 3
    description: "Kitchen - Sound Blaster Play! 3"
  - name: sitting_room
    device: hw:2,0  # UMC1820 or next USB audio device
    description: "Sitting Room - UMC1820"
  - name: bedroom
    device: hw:3,0  # Future device
    description: "Bedroom - Additional USB Audio"
```

## Hardware Requirements

1. **USB Audio Interfaces**: 
   - Creative Sound Blaster Play! 3 (tested)
   - Behringer UMC1820 (planned)
   - Any USB Audio Class compliant device

2. **Home Assistant Host**:
   - USB ports for each audio interface
   - Sufficient power (may need powered USB hub for multiple devices)

3. **Permissions**:
   - Container needs access to `/dev/snd` and `/dev/bus/usb`
   - Audio group permissions automatically configured

## Troubleshooting

### Device Not Detected
- Check `lsusb` output for device presence
- Verify device permissions in addon logs
- Ensure device is USB Audio Class compliant

### No Audio Output
- Check ALSA device accessibility in logs
- Verify correct hw:X,0 device number
- Test device manually with `aplay -D hw:X,0 test.wav`

### Device Assignment
- Kitchen should use the first detected USB audio device
- Additional devices assigned in order of detection
- Override with specific hw:X,0 values in config

## Device Mapping Reference

| Room | Device | ALSA Name | Description |
|------|--------|-----------|-------------|
| Kitchen | Sound Blaster Play! 3 | hw:1,0 | First USB audio device |
| Sitting Room | UMC1820 | hw:2,0 | Second USB audio device |
| Future Zone 1 | TBD | hw:3,0 | Third USB audio device |
| Future Zone 2 | TBD | hw:4,0 | Fourth USB audio device |

Note: Device numbers may vary based on detection order. Check logs for actual assignments.