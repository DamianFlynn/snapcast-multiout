#!/bin/bash
# Script to update version to current date-based format
# Usage: ./update-version.sh [build_number]
# If build_number is not provided, defaults to 1

set -euo pipefail

BUILD_NUM=${1:-1}
TODAY=$(date +%Y.%m.%d)
NEW_VERSION="${TODAY}.${BUILD_NUM}"

echo "Updating version to: $NEW_VERSION"

# Update config.yaml
sed -i.bak "s/^version: .*/version: \"$NEW_VERSION\"/" addons/snapcast-multiout/config.yaml

# Update Dockerfile
sed -i.bak "s/ENV ADDON_VERSION=.*/ENV ADDON_VERSION=\"$NEW_VERSION\"/" addons/snapcast-multiout/Dockerfile
sed -i.bak "s/ENV BUILD_DATE=.*/ENV BUILD_DATE=\"$(date +%Y-%m-%d)\"/" addons/snapcast-multiout/Dockerfile

# Update run.sh
sed -i.bak "s/echo \"\[INFO\] Addon Git Version: .*/echo \"[INFO] Addon Git Version: $NEW_VERSION\"/" addons/snapcast-multiout/run.sh

# Remove backup files
rm -f addons/snapcast-multiout/config.yaml.bak
rm -f addons/snapcast-multiout/Dockerfile.bak
rm -f addons/snapcast-multiout/run.sh.bak

echo "Version updated successfully to $NEW_VERSION"
echo "Files updated:"
echo "  - addons/snapcast-multiout/config.yaml"
echo "  - addons/snapcast-multiout/Dockerfile" 
echo "  - addons/snapcast-multiout/run.sh"