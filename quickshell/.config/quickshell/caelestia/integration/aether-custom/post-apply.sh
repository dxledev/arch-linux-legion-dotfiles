#!/usr/bin/env bash
set -euo pipefail

exec "${XDG_CONFIG_HOME:-$HOME/.config}/quickshell/active/integration/aether" apply
