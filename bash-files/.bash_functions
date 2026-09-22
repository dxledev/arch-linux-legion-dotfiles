termshark() {
  env -u COLORTERM /usr/bin/termshark "$@"
}

codex() {
  if (( $+functions[load-nvm] )); then
    load-nvm
  fi

  command codex "$@"
}

lsn() {
  local dir="."
  local order="newest"
  local count=10

  # help
  if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    cat <<'EOF'
Usage:
  lsn [directory] [--newest|--oldest] [count]

Defaults:
  directory : current directory (.)
  order     : --newest
  count     : 10
  flags     : -la (always on)

Examples:
  lsn
  lsn 5
  lsn --oldest 20
  lsn ~/dev --newest 15
  lsn ~/dev 3
EOF
    return 0
  fi

  # directory
  if [[ -d "$1" ]]; then
    dir="$1"
    shift
  fi

  # order
  if [[ "$1" == "--newest" || "$1" == "--oldest" ]]; then
    order="${1#--}"
    shift
  fi

  # count
  if [[ "$1" =~ ^[0-9]+$ ]]; then
    count="$1"
  fi

  # execute
  if [[ "$order" == "newest" ]]; then
    eza -lla "$dir" -s newest -r --icons=always --color=always | head -n "$count"
  else
    eza -lla "$dir" -s newest --icons=always --color=always | head -n "$count"
  fi
}

sudo() {
    if [ "$1" = "nvim" ]; then
        shift
        command sudo -e "$@"
    else
        command sudo "$@"
    fi
}
