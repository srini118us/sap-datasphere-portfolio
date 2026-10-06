#!/usr/bin/env bash
# Common helpers for datasphere automation scripts.
# Sourced by every script. Loads config, provides logger and CLI wrapper.
#
# Required env vars:
#   CONFIG  path to a config yaml (e.g., config/trial.yaml)
# Optional env vars:
#   DRY_RUN if set to 1, print commands without executing

set -eu -o pipefail

# ---------- prerequisites ----------
_require_bin() {
  command -v "$1" >/dev/null 2>&1 || { echo "ERROR: $1 not installed" >&2; exit 2; }
}
_require_bin yq
_require_bin jq
_require_bin datasphere

# ---------- config load ----------
: "${CONFIG:?ERROR: set CONFIG=path/to/config.yaml before running}"
[ -f "$CONFIG" ] || { echo "ERROR: config file not found: $CONFIG" >&2; exit 2; }

ENV_NAME=$(yq -r '.env_name' "$CONFIG")
TENANT_HOST=$(yq -r '.tenant.host' "$CONFIG")
AUTH_MODE=$(yq -r '.tenant.auth_mode' "$CONFIG")
OUTPUT_DIR=$(yq -r '.output_dir' "$CONFIG")
LOG_LEVEL=$(yq -r '.log_level' "$CONFIG")
TC_WARN=$(yq -r '.thresholds.taskchain_failures_warn' "$CONFIG")
TC_CRIT=$(yq -r '.thresholds.taskchain_failures_crit' "$CONFIG")

# Space list and object type list as bash arrays
mapfile -t SPACES < <(yq -r '.spaces[]' "$CONFIG")
mapfile -t OBJECT_TYPES < <(yq -r '.object_types[]' "$CONFIG")
mapfile -t TC_WINDOWS < <(yq -r '.taskchain_windows_hours[]' "$CONFIG")

mkdir -p "$OUTPUT_DIR"

# ---------- logger ----------
_ts() { date -u +'%Y-%m-%dT%H:%M:%SZ'; }
log_info()  { echo "[$(_ts)] INFO  $*" >&2; }
log_warn()  { echo "[$(_ts)] WARN  $*" >&2; }
log_error() { echo "[$(_ts)] ERROR $*" >&2; }
log_debug() { [ "$LOG_LEVEL" = "debug" ] && echo "[$(_ts)] DEBUG $*" >&2 || true; }

# ---------- CLI wrapper ----------
# Runs the datasphere CLI against the tenant defined in the config.
# Pass all args after the function name.
# Honors DRY_RUN=1 to print without executing.
ds() {
  if [ "${DRY_RUN:-0}" = "1" ]; then
    echo "DRY_RUN: datasphere $*" >&2
    echo '{}'
    return 0
  fi
  datasphere "$@"
}

# ---------- exit code helper ----------
# Set the failure count into a global, then call exit_by_threshold at end.
FAILURES=0
add_failures() { FAILURES=$((FAILURES + $1)); }
exit_by_threshold() {
  if [ "$FAILURES" -ge "$TC_CRIT" ]; then
    log_error "failures=$FAILURES at or above crit=$TC_CRIT, exit 2"
    exit 2
  elif [ "$FAILURES" -ge "$TC_WARN" ]; then
    log_warn "failures=$FAILURES at or above warn=$TC_WARN, exit 1"
    exit 1
  else
    log_info "failures=$FAILURES below warn=$TC_WARN, exit 0"
    exit 0
  fi
}

log_info "config loaded: env=$ENV_NAME tenant=$TENANT_HOST spaces=${#SPACES[@]} auth=$AUTH_MODE"
