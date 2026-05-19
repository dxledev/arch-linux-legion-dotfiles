hl.config({
  plugin = {
    hyprexpo = {
      columns = 3,
      gap_size = 5,
      bg_col = "rgb(000000)",
      workspace_method = "center current",
      skip_empty = false,
    },
  },
  ["plugin:dynamic-cursors"] = {
    enabled = true,
    mode = "none",
    threshold = 2,
    rotate = {
      length = 20,
      offset = 0.0,
    },
    tilt = {
      limit = 5000,
      ["function"] = "negative_quadratic",
      window = 100,
      full_tilt = 60,
    },
    stretch = {
      limit = 3000,
      ["function"] = "quadratic",
      window = 100,
    },
    shake = {
      enabled = true,
      nearest = false,
      threshold = 8.0,
      base = 2.0,
      speed = 2.0,
      influence = 0.0,
      limit = 4.0,
      timeout = 1500,
      effects = false,
      ipc = false,
    },
    hyprcursor = {
      nearest = false,
      enabled = false,
      resolution = -1,
      fallback = "clientside",
    },
  },
})

if hl.plugin then
  hl.plugin("/home/dxle/builds/hypr-scrolling-fix/hyprscrollingfix.so")
else
  hl.on("hyprland.start", function()
    hl.exec_cmd("hyprctl plugin load /home/dxle/builds/hypr-scrolling-fix/hyprscrollingfix.so")
  end)
end
