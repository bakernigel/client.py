#!/bin/bash

# Home Assistant DEEBOT X2 OMNI patch installer
#
# Temporary workaround for applying X2 OMNI support to:
#
#   1. deebot-client installed inside Home Assistant
#   2. Home Assistant's built-in Ecovacs event and vacuum integration
#
# Sources:
#
#   deebot-client patches:
#     bakernigel/client.py - dev
#
#   Home Assistant Ecovacs patches:
#     bakernigel/client.py - dev
#     patches/homeassistant/ecovacs/event.py
#     patches/homeassistant/ecovacs/vacuum.py
#
# Run from the Home Assistant OS host:
#
#   sudo docker exec -it homeassistant \
#     /config/deebot_patch/apply_x2_omni_patch.sh
#
# If the script has Windows line endings:
#
#   sed -i 's/\r$//' /config/deebot_patch/apply_x2_omni_patch.sh
#   chmod +x /config/deebot_patch/apply_x2_omni_patch.sh
#
# Then restart Home Assistant Core:
#
#   sudo docker restart homeassistant

set -euo pipefail


# ---------------------------------------------------------------------------
# GitHub sources
# ---------------------------------------------------------------------------

REPO="bakernigel/client.py"

CLIENT_BRANCH="dev"
PATCH_BRANCH="dev"

CLIENT_BASE_URL="https://raw.githubusercontent.com/$REPO/$CLIENT_BRANCH"
PATCH_BASE_URL="https://raw.githubusercontent.com/$REPO/$PATCH_BRANCH"


# ---------------------------------------------------------------------------
# Working directories
# ---------------------------------------------------------------------------

WORK_DIR="/config/deebot_patch"
DOWNLOAD_DIR="$WORK_DIR/downloaded"

mkdir -p "$DOWNLOAD_DIR"


echo "========================================"
echo " DEEBOT X2 OMNI patch installer"
echo "========================================"
echo


# ---------------------------------------------------------------------------
# Download patch files
# ---------------------------------------------------------------------------

echo "Downloading patch files from GitHub..."
echo

curl -fsSL \
  "$CLIENT_BASE_URL/deebot_client/hardware/e6ofmn.py" \
  -o "$DOWNLOAD_DIR/e6ofmn.py"

curl -fsSL \
  "$CLIENT_BASE_URL/deebot_client/commands/json/clean.py" \
  -o "$DOWNLOAD_DIR/clean.py"

curl -fsSL \
  "$CLIENT_BASE_URL/deebot_client/messages/json/station_state.py" \
  -o "$DOWNLOAD_DIR/station_state.py"

curl -fsSL \
  "$CLIENT_BASE_URL/deebot_client/messages/json/stats.py" \
  -o "$DOWNLOAD_DIR/stats.py"

curl -fsSL \
  "$CLIENT_BASE_URL/deebot_client/messages/json/__init__.py" \
  -o "$DOWNLOAD_DIR/json_init.py"

curl -fsSL \
  "$CLIENT_BASE_URL/deebot_client/capabilities.py" \
  -o "$DOWNLOAD_DIR/capabilities.py"

curl -fsSL \
  "$CLIENT_BASE_URL/deebot_client/events/__init__.py" \
  -o "$DOWNLOAD_DIR/events_init.py"

curl -fsSL \
  "$PATCH_BASE_URL/patches/homeassistant/ecovacs/event.py" \
  -o "$DOWNLOAD_DIR/ha_ecovacs_event.py"

curl -fsSL \
  "$PATCH_BASE_URL/patches/homeassistant/ecovacs/vacuum.py" \
  -o "$DOWNLOAD_DIR/ha_ecovacs_vacuum.py"

echo "Patch files downloaded successfully."
echo


# ---------------------------------------------------------------------------
# Locate installed deebot-client
# ---------------------------------------------------------------------------

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


# ---------------------------------------------------------------------------
# Destination files
# ---------------------------------------------------------------------------

DEST_E6="$SITE_DIR/hardware/e6ofmn.py"
DEST_LF="$SITE_DIR/hardware/lf3bn4.py"
DEST_CLEAN="$SITE_DIR/commands/json/clean.py"
DEST_STATION="$SITE_DIR/messages/json/station_state.py"
DEST_STATS="$SITE_DIR/messages/json/stats.py"
DEST_JSON_INIT="$SITE_DIR/messages/json/__init__.py"
DEST_CAPABILITIES="$SITE_DIR/capabilities.py"
DEST_EVENTS_INIT="$SITE_DIR/events/__init__.py"

HA_ECOVACS_DIR="/usr/src/homeassistant/homeassistant/components/ecovacs"
DEST_HA_EVENT="$HA_ECOVACS_DIR/event.py"
DEST_HA_VACUUM="$HA_ECOVACS_DIR/vacuum.py"


# ---------------------------------------------------------------------------
# Make sure expected installed files exist
# ---------------------------------------------------------------------------

DEST_FILES=(
  "$DEST_E6"
  "$DEST_LF"
  "$DEST_CLEAN"
  "$DEST_STATION"
  "$DEST_STATS"
  "$DEST_JSON_INIT"
  "$DEST_CAPABILITIES"
  "$DEST_EVENTS_INIT"
  "$DEST_HA_EVENT"
  "$DEST_HA_VACUUM"
)

for file in "${DEST_FILES[@]}"; do
  if [ ! -f "$file" ]; then
    echo "ERROR: Expected installed file not found:"
    echo "  $file"
    echo
    echo "The Home Assistant or deebot-client package layout may have changed."
    echo "Patch NOT applied."
    exit 1
  fi
done


# ---------------------------------------------------------------------------
# Check current patch status
# ---------------------------------------------------------------------------

echo "Patch status:"
echo

PATCH_NEEDED=0

echo "deebot-client:"

if cmp -s "$DOWNLOAD_DIR/e6ofmn.py" "$DEST_E6"; then
  echo "  e6ofmn.py         PATCHED"
else
  echo "  e6ofmn.py         NOT PATCHED"
  PATCH_NEEDED=1
fi

if cmp -s "$DOWNLOAD_DIR/e6ofmn.py" "$DEST_LF"; then
  echo "  lf3bn4.py         PATCHED"
else
  echo "  lf3bn4.py         NOT PATCHED"
  PATCH_NEEDED=1
fi

if cmp -s "$DOWNLOAD_DIR/clean.py" "$DEST_CLEAN"; then
  echo "  clean.py          PATCHED"
else
  echo "  clean.py          NOT PATCHED"
  PATCH_NEEDED=1
fi

if cmp -s "$DOWNLOAD_DIR/station_state.py" "$DEST_STATION"; then
  echo "  station_state.py  PATCHED"
else
  echo "  station_state.py  NOT PATCHED"
  PATCH_NEEDED=1
fi

if cmp -s "$DOWNLOAD_DIR/stats.py" "$DEST_STATS"; then
  echo "  stats.py          PATCHED"
else
  echo "  stats.py          NOT PATCHED"
  PATCH_NEEDED=1
fi

if cmp -s "$DOWNLOAD_DIR/json_init.py" "$DEST_JSON_INIT"; then
  echo "  json/__init__.py  PATCHED"
else
  echo "  json/__init__.py  NOT PATCHED"
  PATCH_NEEDED=1
fi

if cmp -s "$DOWNLOAD_DIR/capabilities.py" "$DEST_CAPABILITIES"; then
  echo "  capabilities.py   PATCHED"
else
  echo "  capabilities.py   NOT PATCHED"
  PATCH_NEEDED=1
fi

if cmp -s "$DOWNLOAD_DIR/events_init.py" "$DEST_EVENTS_INIT"; then
  echo "  events/__init__.py PATCHED"
else
  echo "  events/__init__.py NOT PATCHED"
  PATCH_NEEDED=1
fi

echo
echo "Home Assistant:"

if cmp -s "$DOWNLOAD_DIR/ha_ecovacs_event.py" "$DEST_HA_EVENT"; then
  echo "  ecovacs/event.py   PATCHED"
else
  echo "  ecovacs/event.py   NOT PATCHED"
  PATCH_NEEDED=1
fi

if cmp -s "$DOWNLOAD_DIR/ha_ecovacs_vacuum.py" "$DEST_HA_VACUUM"; then
  echo "  ecovacs/vacuum.py  PATCHED"
else
  echo "  ecovacs/vacuum.py  NOT PATCHED"
  PATCH_NEEDED=1
fi

echo


# ---------------------------------------------------------------------------
# Exit if everything is already patched
# ---------------------------------------------------------------------------

if [ "$PATCH_NEEDED" -eq 0 ]; then
  echo "Patch already installed. Nothing to do."
  echo "========================================"
  exit 0
fi


# ---------------------------------------------------------------------------
# Backup currently installed files
# ---------------------------------------------------------------------------

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

cp "$DEST_STATS" \
   "$BACKUP_DIR/stats.py"

cp "$DEST_JSON_INIT" \
   "$BACKUP_DIR/json_init.py"

cp "$DEST_CAPABILITIES" \
   "$BACKUP_DIR/capabilities.py"

cp "$DEST_EVENTS_INIT" \
   "$BACKUP_DIR/events_init.py"

cp "$DEST_HA_EVENT" \
   "$BACKUP_DIR/ha_ecovacs_event.py"

cp "$DEST_HA_VACUUM" \
   "$BACKUP_DIR/ha_ecovacs_vacuum.py"


# ---------------------------------------------------------------------------
# Apply patches
# ---------------------------------------------------------------------------

echo "Applying patch..."

cp "$DOWNLOAD_DIR/e6ofmn.py" \
   "$DEST_E6"

# X2 OMNI lf3bn4 uses the e6ofmn hardware definition
cp "$DOWNLOAD_DIR/e6ofmn.py" \
   "$DEST_LF"

cp "$DOWNLOAD_DIR/clean.py" \
   "$DEST_CLEAN"

cp "$DOWNLOAD_DIR/station_state.py" \
   "$DEST_STATION"

cp "$DOWNLOAD_DIR/stats.py" \
   "$DEST_STATS"

cp "$DOWNLOAD_DIR/json_init.py" \
   "$DEST_JSON_INIT"

cp "$DOWNLOAD_DIR/capabilities.py" \
   "$DEST_CAPABILITIES"

cp "$DOWNLOAD_DIR/events_init.py" \
   "$DEST_EVENTS_INIT"

cp "$DOWNLOAD_DIR/ha_ecovacs_event.py" \
   "$DEST_HA_EVENT"

cp "$DOWNLOAD_DIR/ha_ecovacs_vacuum.py" \
   "$DEST_HA_VACUUM"


# ---------------------------------------------------------------------------
# Remove Python bytecode caches
# ---------------------------------------------------------------------------

echo "Removing Python bytecode caches..."

find "$SITE_DIR" \
  -type d \
  -name __pycache__ \
  -prune \
  -exec rm -rf {} +

find "$HA_ECOVACS_DIR" \
  -type d \
  -name __pycache__ \
  -prune \
  -exec rm -rf {} +


# ---------------------------------------------------------------------------
# Verify installed files exactly match downloaded files
# ---------------------------------------------------------------------------

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

if ! cmp -s "$DOWNLOAD_DIR/stats.py" "$DEST_STATS"; then
  echo "ERROR: stats.py verification failed"
  VERIFY_FAILED=1
fi

if ! cmp -s "$DOWNLOAD_DIR/json_init.py" "$DEST_JSON_INIT"; then
  echo "ERROR: json/__init__.py verification failed"
  VERIFY_FAILED=1
fi

if ! cmp -s "$DOWNLOAD_DIR/capabilities.py" "$DEST_CAPABILITIES"; then
  echo "ERROR: capabilities.py verification failed"
  VERIFY_FAILED=1
fi

if ! cmp -s "$DOWNLOAD_DIR/events_init.py" "$DEST_EVENTS_INIT"; then
  echo "ERROR: events/__init__.py verification failed"
  VERIFY_FAILED=1
fi

if ! cmp -s "$DOWNLOAD_DIR/ha_ecovacs_event.py" "$DEST_HA_EVENT"; then
  echo "ERROR: Home Assistant ecovacs/event.py verification failed"
  VERIFY_FAILED=1
fi

if ! cmp -s "$DOWNLOAD_DIR/ha_ecovacs_vacuum.py" "$DEST_HA_VACUUM"; then
  echo "ERROR: Home Assistant ecovacs/vacuum.py verification failed"
  VERIFY_FAILED=1
fi

if [ "$VERIFY_FAILED" -ne 0 ]; then
  echo
  echo "Patch verification FAILED."
  exit 1
fi


# ---------------------------------------------------------------------------
# Verify expected patch markers
# ---------------------------------------------------------------------------

echo "Checking expected patch markers..."

grep -q "CapabilityStation" "$DEST_E6" || {
  echo "ERROR: CapabilityStation marker not found in e6ofmn.py"
  exit 1
}

grep -q "CLEAN_BASE" "$DEST_E6" || {
  echo "ERROR: CLEAN_BASE marker not found in e6ofmn.py"
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

grep -q "OnCleanDataUpdateV2" "$DEST_STATS" || {
  echo "ERROR: OnCleanDataUpdateV2 marker not found in stats.py"
  exit 1
}

grep -q "OnLastTimeStats" "$DEST_STATS" || {
  echo "ERROR: OnLastTimeStats marker not found in stats.py"
  exit 1
}

grep -q "rooms:" "$DEST_STATS" || {
  echo "ERROR: room tracking marker not found in stats.py"
  exit 1
}

grep -q "OnCleanDataUpdateV2" "$DEST_JSON_INIT" || {
  echo "ERROR: OnCleanDataUpdateV2 marker not found in json/__init__.py"
  exit 1
}

grep -q "OnLastTimeStats" "$DEST_JSON_INIT" || {
  echo "ERROR: OnLastTimeStats marker not found in json/__init__.py"
  exit 1
}

grep -q "selected_rooms" "$DEST_CAPABILITIES" || {
  echo "ERROR: selected_rooms capability marker not found in capabilities.py"
  exit 1
}

grep -q "CleaningProgressEvent" "$DEST_CAPABILITIES" || {
  echo "ERROR: CleaningProgressEvent marker not found in capabilities.py"
  exit 1
}

grep -q "SelectedRoomsEvent" "$DEST_EVENTS_INIT" || {
  echo "ERROR: SelectedRoomsEvent marker not found in events/__init__.py"
  exit 1
}

grep -q "CleaningProgressEvent" "$DEST_EVENTS_INIT" || {
  echo "ERROR: CleaningProgressEvent marker not found in events/__init__.py"
  exit 1
}

grep -q "CleaningProgressEvent" "$DEST_STATS" || {
  echo "ERROR: CleaningProgressEvent marker not found in stats.py"
  exit 1
}

grep -q "RoomCleaningStatus" "$DEST_STATS" || {
  echo "ERROR: RoomCleaningStatus marker not found in stats.py"
  exit 1
}

grep -q '"rooms": event.content' "$DEST_HA_EVENT" || {
  echo "ERROR: Last Job room attribute marker not found in HA ecovacs/event.py"
  exit 1
}

grep -q '"duration": event.time' "$DEST_HA_EVENT" || {
  echo "ERROR: Last Job duration attribute marker not found in HA ecovacs/event.py"
  exit 1
}

grep -q '_ATTR_SELECTED_ROOMS = "selected_rooms"' "$DEST_HA_VACUUM" || {
  echo "ERROR: selected_rooms marker not found in HA ecovacs/vacuum.py"
  exit 1
}

grep -q '_ATTR_ROOM_PROGRESS = "room_progress"' "$DEST_HA_VACUUM" || {
  echo "ERROR: room_progress marker not found in HA ecovacs/vacuum.py"
  exit 1
}

grep -q '_ATTR_CURRENT_ROOM = "current_room"' "$DEST_HA_VACUUM" || {
  echo "ERROR: current_room marker not found in HA ecovacs/vacuum.py"
  exit 1
}

grep -q '_ATTR_COMPLETED_ROOMS = "completed_rooms"' "$DEST_HA_VACUUM" || {
  echo "ERROR: completed_rooms marker not found in HA ecovacs/vacuum.py"
  exit 1
}


# ---------------------------------------------------------------------------
# Finished
# ---------------------------------------------------------------------------

echo
echo "Patch verification successful."
echo

echo "Patched:"
echo
echo "deebot-client:"
echo "  hardware/e6ofmn.py"
echo "  hardware/lf3bn4.py"
echo "  commands/json/clean.py"
echo "  messages/json/station_state.py"
echo "  messages/json/stats.py"
echo "  messages/json/__init__.py"
echo "  capabilities.py"
echo "  events/__init__.py"
echo
echo "Home Assistant:"
echo "  components/ecovacs/event.py"
echo "  components/ecovacs/vacuum.py"
echo

echo "Restart Home Assistant Core to load the new code."
echo "========================================"
