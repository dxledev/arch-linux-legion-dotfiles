#!/usr/bin/env bash

PROCESS="hypridle"

if pgrep -x "$PROCESS" >/dev/null; then
    printf '{"text":"running","tooltip":"Idle Lock: ON","class":"running","percentage":100}\n'
else
    printf '{"text":"stopped","tooltip":"Idle Lock: OFF","class":"stopped","percentage":0}\n'
fi
