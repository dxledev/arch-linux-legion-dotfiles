local config_home = os.getenv("XDG_CONFIG_HOME") or (os.getenv("HOME") .. "/.config")
dofile(config_home .. "/quickshell/shared/display/monitor-rules.lua")
