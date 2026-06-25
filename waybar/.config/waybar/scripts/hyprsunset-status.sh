#!/usr/bin/env bash

set -euo pipefail

STATE_FILE="${XDG_RUNTIME_DIR:-/tmp}/system-toggle-nightlight.state"
PGREP_BIN="${PGREP_BIN:-/usr/bin/pgrep}"

if "$PGREP_BIN" -x hyprsunset >/dev/null 2>&1 \
  && [[ -f "$STATE_FILE" ]] \
  && [[ "$(<"$STATE_FILE")" == "on" ]]; then

  printf '{"text":"running","tooltip":"Nightlight: ON","class":"on","percentage":100}\n'
else
  printf '{"text":"stopped","tooltip":"Nightlight: OFF","class":"off","percentage":0}\n'
fi
