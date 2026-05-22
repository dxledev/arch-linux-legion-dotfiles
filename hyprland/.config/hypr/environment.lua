hl.env("GTK_THEME", "Adwaita:dark")
hl.env("XCURSOR_SIZE", "24")
hl.env("XCURSOR_THEME", "Bibata-Osaka-Jade")
hl.env("GTK_ICON_THEME", "Papirus")
hl.env("PATH", "/home/dxle/bin:/home/dxle/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/bin:/usr/lib/jvm/default/bin:/usr/bin/site_perl:/usr/bin/vendor_perl:/usr/bin/core_perl")
hl.env("WLR_DRM_DEVICES", "/dev/dri/card1")
hl.env("AQ_DRM_DEVICES", "/dev/dri/card1:/dev/dri/card2")
hl.env("AMD_PERF_LEVEL", "high")

hl.config({
  debug = {
    vfr = false,
  },
})
