#!/usr/bin/env bash

SERVICE="app-dev.lizardbyte.app.Sunshine.service"

if systemctl --user is-active --quiet "$SERVICE"; then
    printf '{"text":"running","tooltip":"Sunshine: ON","class":"running","percentage":100}\n'
else
    printf '{"text":"stopped","tooltip":"Sunshine: OFF","class":"stopped","percentage":0}\n'
fi
