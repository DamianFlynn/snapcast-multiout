# Versioning Scheme

This project uses **date-based versioning** (datever) instead of semantic versioning.

## Format
```
YYYY.MM.DD.build
```

Where:
- `YYYY` = 4-digit year
- `MM` = 2-digit month (01-12)
- `DD` = 2-digit day (01-31)
- `build` = Build number for that day (starting at 1)

## Examples
- `2025.09.22.1` - First build on September 22, 2025
- `2025.09.22.2` - Second build on September 22, 2025
- `2025.12.01.1` - First build on December 1, 2025

## Benefits of Date-based Versioning
1. **Clear timeline**: Easy to see when a version was created
2. **No version conflicts**: Each day gets a unique version prefix
3. **Incremental builds**: Multiple builds per day are supported
4. **Cache busting**: Different versions force container rebuilds
5. **Simple automation**: Easy to generate automatically

## Updating Versions

### Manual Method
Edit these files and update the version string:
- `addons/snapcast-multiout/config.yaml` - line 3
- `addons/snapcast-multiout/Dockerfile` - ENV ADDON_VERSION
- `addons/snapcast-multiout/run.sh` - Addon Git Version line

### Automated Method
Use the provided script:
```bash
# For the first build of today
./update-version.sh

# For subsequent builds on the same day
./update-version.sh 2
./update-version.sh 3
```

## Container Registry Tags
When published to GitHub Container Registry, versions are tagged as:
- `ghcr.io/damianflynn/snapcast-multiout:2025.09.22.1`
- `ghcr.io/damianflynn/snapcast-multiout:latest` (latest build)

## Migration from Semantic Versioning
Previous versions used semantic versioning like `0.31.0-35`. The new date-based system:
- Is more predictable and automatic
- Eliminates version conflicts and caching issues
- Provides better traceability of when changes were made