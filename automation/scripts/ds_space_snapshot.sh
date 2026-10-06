#!/usr/bin/env bash
# ds_space_snapshot.sh
# Emits a JSON snapshot of all spaces defined in the config: object counts by type.
# Usage:
#   CONFIG=config/trial.yaml ./scripts/ds_space_snapshot.sh
# Output:
#   samples/space_snapshot_<env>_<timestamp>.json
# Exit codes:
#   0 clean, 2 CLI or auth error

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
REPO_ROOT=$(cd "$SCRIPT_DIR/.." && pwd)
# shellcheck source=../lib/common.sh
. "$REPO_ROOT/lib/common.sh"

TS=$(date -u +'%Y%m%dT%H%M%SZ')
OUT="$OUTPUT_DIR/space_snapshot_${ENV_NAME}_${TS}.json"

log_info "starting space snapshot: spaces=${#SPACES[@]} types=${#OBJECT_TYPES[@]}"

# Build JSON output incrementally into a temp file, then move
TMP=$(mktemp)
trap 'rm -f "$TMP"' EXIT

echo '{' > "$TMP"
echo "  \"env\": \"$ENV_NAME\"," >> "$TMP"
echo "  \"tenant\": \"$TENANT_HOST\"," >> "$TMP"
echo "  \"timestamp\": \"$(_ts)\"," >> "$TMP"
echo '  "spaces": [' >> "$TMP"

first_space=1
for space in "${SPACES[@]}"; do
  [ $first_space -eq 1 ] && first_space=0 || echo "    ," >> "$TMP"
  log_info "space: $space"
  echo "    {" >> "$TMP"
  echo "      \"name\": \"$space\"," >> "$TMP"
  echo '      "objects": {' >> "$TMP"

  first_type=1
  for otype in "${OBJECT_TYPES[@]}"; do
    [ $first_type -eq 1 ] && first_type=0 || echo "        ," >> "$TMP"
    log_debug "  listing $otype in $space"
    # datasphere objects <type> list output is JSON array by default
    count=$(ds objects "$otype" list -y "$space" 2>/dev/null \
              | jq 'if type=="array" then length else 0 end' 2>/dev/null || echo 0)
    echo "        \"$otype\": $count" >> "$TMP"
    log_debug "  $otype=$count"
  done
  echo '      }' >> "$TMP"
  echo "    }" >> "$TMP"
done

echo '  ]' >> "$TMP"
echo '}' >> "$TMP"

# Validate JSON before saving
if jq empty "$TMP" 2>/dev/null; then
  mv "$TMP" "$OUT"
  log_info "wrote $OUT"
  # Print a compact summary to stdout
  jq -c '{env, tenant, timestamp, space_count: (.spaces|length), total_objects: [.spaces[].objects | to_entries[].value] | add}' "$OUT"
  exit 0
else
  log_error "produced invalid JSON, kept at $TMP"
  exit 2
fi
