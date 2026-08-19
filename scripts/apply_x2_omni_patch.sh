#!/bin/bash

# Home Assistant DEEBOT X2 OMNI patch installer
#
# Temporary workaround for applying X2 OMNI station support to the
# deebot-client package installed inside Home Assistant.
#
# Patch source:
#   bakernigel/client.py - x2-omni-station-support
#
# Run from the Home Assistant OS host:
#
#   sudo docker exec -it homeassistant \
#     /config/deebot_patch/apply_patch.sh
#
# Then restart Home Assistant Core:
#
#   sudo docker restart homeassistant

set -euo pipefail

REPO="bakernigel/client.py"
BRANCH="x2-omni-station-support"

BASE_URL="https://raw.githubusercontent.com/$REPO/$BRANCH"

WORK_DIR="/config/deebot_patch"
DOWNLOAD_DIR="$WORK_DIR/downloaded"

mkdir -p "$DOWNLOAD_DIR"

echo "========================================"
echo " DEEBOT X2 OMNI patch installer"
echo "========================================"
echo

echo "Downloading patch files from GitHub..."
echo

curl -fsSL \
  "$BASE_URL/deebot_client/hardware/e6ofmn.py" \
  -o "$DOWNLOAD_DIR/e6ofmn.py"

curl -fsSL \
  "$BASE_URL/deebot_client/commands/json/clean.py" \
  -o "$DOWNLOAD_DIR/clean.py"

curl -fsSL \
  "$BASE_URL/deebot_client/messages/json/station_state.py" \
  -o "$DOWNLOAD_DIR/station_state.py"

echo "Patch files downloaded successfully."
echo

SITE_DIR="$(
python - <<'PY'
import pathlib
import deebot_client

print(pathlib.Path(deebot_client.__file__).resolve().parent)
PY
)"

echo "Installed deebot_client:"
echo "  $SITE_DIR"
echo

echo "Installed deebot-client version:"
python - <<'PY'
from importlib.metadata import version, PackageNotFoundError

try:
    print(" ", version("deebot-client"))
except PackageNotFoundError:
    print("  unknown")
PY

echo

DEST_E6="$SITE_DIR/hardware/e6ofmn.py"
DEST_LF="$SITE_DIR/hardware/lf3bn4.py"
DEST_CLEAN="$SITE_DIR/commands/json/clean.py"
DEST_STATION="$SITE_DIR/messages/json/station_state.py"

DEST_FILES=(
  "$DEST_E6"
  "$DEST_LF"
  "$DEST_CLEAN"
  "$DEST_STATION"
)

for file in "${DEST_FILES[@]}"; do
  if [ ! -f "$file" ]; then
    echo "ERROR: Expected installed file not found:"
    echo "  $file"
    echo
    echo "The deebot-client package layout may have changed."
    echo "Patch NOT applied."
    exit 1
  fi
done

echo "Patch status:"
echo

PATCH_NEEDED=0

if cmp -s "$DOWNLOAD_DIR/e6ofmn.py" "$DEST_E6"; then
  echo "  e6ofmn.py        PATCHED"
else
  echo "  e6ofmn.py        NOT PATCHED"
  PATCH_NEEDED=1
fi

if cmp -s "$DOWNLOAD_DIR/e6ofmn.py" "$DEST_LF"; then
  echo "  lf3bn4.py        PATCHED"
else
  echo "  lf3bn4.py        NOT PATCHED"
  PATCH_NEEDED=1
fi

if cmp -s "$DOWNLOAD_DIR/clean.py" "$DEST_CLEAN"; then
  echo "  clean.py         PATCHED"
else
  echo "  clean.py         NOT PATCHED"
  PATCH_NEEDED=1
fi

if cmp -s "$DOWNLOAD_DIR/station_state.py" "$DEST_STATION"; then
  echo "  station_state.py PATCHED"
else
  echo "  station_state.py NOT PATCHED"
  PATCH_NEEDED=1
fi

echo

if [ "$PATCH_NEEDED" -eq 0 ]; then
  echo "Patch already installed. Nothing to do."
  echo "========================================"
  exit 0
fi

BACKUP_DIR="$WORK_DIR/backups/$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"

echo "Backing up current installed files to:"
echo "  $BACKUP_DIR"
echo

cp "$DEST_E6" \
   "$BACKUP_DIR/e6ofmn.py"

cp "$DEST_LF" \
   "$BACKUP_DIR/lf3bn4.py"

cp "$DEST_CLEAN" \
   "$BACKUP_DIR/clean.py"

cp "$DEST_STATION" \
   "$BACKUP_DIR/station_state.py"

echo "Applying patch..."

cp "$DOWNLOAD_DIR/e6ofmn.py" \
   "$DEST_E6"

cp "$DOWNLOAD_DIR/e6ofmn.py" \
   "$DEST_LF"

cp "$DOWNLOAD_DIR/clean.py" \
   "$DEST_CLEAN"

cp "$DOWNLOAD_DIR/station_state.py" \
   "$DEST_STATION"

echo "Removing Python bytecode caches..."

find "$SITE_DIR" \
  -type d \
  -name __pycache__ \
  -prune \
  -exec rm -rf {} +

echo
echo "Verifying installed files..."

VERIFY_FAILED=0

if ! cmp -s "$DOWNLOAD_DIR/e6ofmn.py" "$DEST_E6"; then
  echo "ERROR: e6ofmn.py verification failed"
  VERIFY_FAILED=1
fi

if ! cmp -s "$DOWNLOAD_DIR/e6ofmn.py" "$DEST_LF"; then
  echo "ERROR: lf3bn4.py verification failed"
  VERIFY_FAILED=1
fi

if ! cmp -s "$DOWNLOAD_DIR/clean.py" "$DEST_CLEAN"; then
  echo "ERROR: clean.py verification failed"
  VERIFY_FAILED=1
fi

if ! cmp -s "$DOWNLOAD_DIR/station_state.py" "$DEST_STATION"; then
  echo "ERROR: station_state.py verification failed"
  VERIFY_FAILED=1
fi

if [ "$VERIFY_FAILED" -ne 0 ]; then
  echo
  echo "Patch verification FAILED."
  exit 1
fi

echo "Checking expected patch markers..."

grep -q "CapabilityStation" "$DEST_E6" || {
  echo "ERROR: CapabilityStation marker not found"
  exit 1
}

grep -q "CLEAN_BASE" "$DEST_E6" || {
  echo "ERROR: CLEAN_BASE marker not found"
  exit 1
}

grep -q "WASHING_MOP" "$DEST_CLEAN" || {
  echo "ERROR: WASHING_MOP marker not found in clean.py"
  exit 1
}

grep -q "WASHING_MOP" "$DEST_STATION" || {
  echo "ERROR: WASHING_MOP marker not found in station_state.py"
  exit 1
}

echo
echo "Patch verification successful."
echo
echo "Patched:"
echo "  hardware/e6ofmn.py"
echo "  hardware/lf3bn4.py"
echo "  commands/json/clean.py"
echo "  messages/json/station_state.py"
echo
echo "Restart Home Assistant Core to load the new code."
echo "========================================"
