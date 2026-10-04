#!/usr/bin/env bash
set -euo pipefail

usage() { printf 'Usage: publish-brightness-osd.sh <percent> <monitor> [--dry-run]\n'; }
[[ $# == 2 || ( $# == 3 && "$3" == --dry-run ) ]] || { usage >&2; exit 2; }
[[ "$1" =~ ^[0-9]+$ && "$1" -le 100 && "$2" =~ ^[A-Za-z0-9._-]{1,80}$ ]] || { usage >&2; exit 2; }
cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/island/status"
if [[ "${3:-}" == --dry-run ]]; then printf 'brightness|%s|%s\n' "$1" "$2"; exit; fi
/usr/bin/mkdir -p -- "$cache_dir/brightness"
stamp="$(/usr/bin/date +%s%N)"
temporary="$(/usr/bin/mktemp "$cache_dir/brightness/$2.XXXXXX")"
printf 'brightness|%s|%s|%s\n' "$1" "$2" "$stamp" > "$temporary"
/usr/bin/mv -f -- "$temporary" "$cache_dir/brightness/$2"
printf 'brightness|%s|%s|%s\n' "$1" "$2" "$stamp" > "$cache_dir/event"
