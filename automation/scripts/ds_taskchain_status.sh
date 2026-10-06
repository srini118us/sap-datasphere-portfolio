#!/usr/bin/env bash
# ds_taskchain_status.sh
# Emits JSON report of task chain runs per space for each configured window.
# CLI: `datasphere tasks logs list -y <space>` returns ALL logs for a space,
# no --since flag. Script fetches once per space, filters windows via jq.
# Usage:
#   CONFIG=config/trial.yaml ./scripts/ds_taskchain_status.sh
# Output:
#   samples/taskchain_status_<env>_<timestamp>.json
# Exit codes:
#   0 clean, 1 warn threshold, 2 crit threshold or CLI error

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
REPO_ROOT=$(cd "$SCRIPT_DIR/.." && pwd)
. "$REPO_ROOT/lib/common.sh"

TS=$(date -u +'%Y%m%dT%H%M%SZ')
OUT="$OUTPUT_DIR/taskchain_status_${ENV_NAME}_${TS}.json"

log_info "starting task chain status: spaces=${#SPACES[@]} windows=${TC_WINDOWS[*]}h"

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

  log_debug "  fetching logs for $space"
  runs_json=$(ds tasks logs list -y "$space" 2>/dev/null || echo '[]')

  if ! echo "$runs_json" | jq -e 'type=="array"' >/dev/null 2>&1; then
    log_warn "  non array response for $space, treating as empty"
    runs_json='[]'
  fi

  total_all=$(echo "$runs_json" | jq 'length')
  log_info "  total logs returned: $total_all"

  echo '      "windows": [' >> "$TMP"

  first_win=1
  for hours in "${TC_WINDOWS[@]}"; do
    [ $first_win -eq 1 ] && first_win=0 || echo "        ," >> "$TMP"
    since=$(date -u -d "$hours hours ago" +'%Y-%m-%dT%H:%M:%SZ' 2>/dev/null \
             || date -u -v-"${hours}"H +'%Y-%m-%dT%H:%M:%SZ')
    log_debug "  window ${hours}h since $since"

    filtered=$(echo "$runs_json" | jq --arg since "$since" '
      [.[] | select(
        (.startTime // .startedAt // .executionTime // .timestamp // "1970-01-01T00:00:00Z") >= $since
      )]
    ')

    total=$(echo "$filtered" | jq 'length')
    success=$(echo "$filtered" | jq '[.[] | select((.status // "") | ascii_downcase | test("success|completed"))] | length')
    failed=$(echo "$filtered" | jq '[.[] | select((.status // "") | ascii_downcase | test("fail|error"))] | length')
    running=$(echo "$filtered" | jq '[.[] | select((.status // "") | ascii_downcase | test("running|in_progress"))] | length')

    add_failures "$failed"

    echo "        {" >> "$TMP"
    echo "          \"hours\": $hours," >> "$TMP"
    echo "          \"since\": \"$since\"," >> "$TMP"
    echo "          \"total\": $total," >> "$TMP"
    echo "          \"success\": $success," >> "$TMP"
    echo "          \"failed\": $failed," >> "$TMP"
    echo "          \"running\": $running" >> "$TMP"
    echo "        }" >> "$TMP"
    log_info "  ${hours}h: total=$total success=$success failed=$failed running=$running"
  done

  echo '      ]' >> "$TMP"
  echo "    }" >> "$TMP"
done

echo '  ],' >> "$TMP"
echo "  \"failure_total\": $FAILURES," >> "$TMP"
echo "  \"thresholds\": { \"warn\": $TC_WARN, \"crit\": $TC_CRIT }" >> "$TMP"
echo '}' >> "$TMP"

if jq empty "$TMP" 2>/dev/null; then
  mv "$TMP" "$OUT"
  log_info "wrote $OUT"
  jq -c '{env, tenant, timestamp, failure_total, thresholds}' "$OUT"
  exit_by_threshold
else
  log_error "produced invalid JSON, kept at $TMP"
  exit 2
fi
