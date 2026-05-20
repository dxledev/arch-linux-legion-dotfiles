hl.config({
  animations = {
    enabled = true,
  },
})

local curves = {
  { "easeOutQuint", { { 0.23, 1 }, { 0.32, 1 } } },
  { "easeInOutCubic", { { 0.65, 0.05 }, { 0.36, 1 } } },
  { "linear", { { 0, 0 }, { 1, 1 } } },
  { "almostLinear", { { 0.5, 0.5 }, { 0.75, 1 } } },
  { "quick", { { 0.15, 0 }, { 0.1, 1 } } },
  { "overshot", { { 0.05, 0.87 }, { 0.1, 1.05 } } },
  { "overshotExtended", { { 0.05, 0.8 }, { 0.1, 1.1 } } },
  { "overshotOverkill", { { 0.05, 0.95 }, { 0.1, 1.2 } } },
  { "anticipate", { { 0.36, 0.0 }, { 0.66, -0.4 } } },
  { "elastic", { { 0.68, -0.6 }, { 0.32, 1.6 } } },
  { "expo", { { 0.19, 1.0 }, { 0.22, 1.0 } } },
  { "mango", { { 0.46, 1.0 }, { 0.29, 0.99 } } },
}

for _, curve in ipairs(curves) do
  hl.curve(curve[1], { type = "bezier", points = curve[2] })
end

local animations = {
  { "global", true, 10, "default" },
  { "border", true, 14, "easeOutQuint" },
  { "windows", true, 8, "easeOutQuint" },
  { "windowsIn", true, 3, "mango", "slide" },
  { "windowsOut", true, 2, "mango", "slide" },
  { "windowsMove", true, 5, "mango", "slide" },
  { "fadeIn", true, 1, "easeInOutCubic" },
  { "fadeOut", true, 2, "easeInOutCubic" },
  { "fade", true, 0.5, "easeInOutCubic" },
  { "layers", true, 0.01, "easeOutQuint" },
  { "layersIn", true, 0.9, "easeOutQuint", "fade" },
  { "layersOut", false, 0.9, "linear", "fade" },
  { "fadeLayersIn", true, 4, "easeOutQuint" },
  { "fadeLayersOut", false, 1, "linear" },
  { "workspaces", true, 4.9, "overshot", "slidevert 100%" },
  { "specialWorkspace", true, 4, "overshotOverkill", "slidevert 100%" },
  { "specialWorkspaceIn", true, 4, "overshotOverkill", "slidevert 100%" },
  { "specialWorkspaceOut", true, 4, "anticipate", "slidevert 100%" },
  { "zoomFactor", true, 4, "quick" },
}

for _, animation in ipairs(animations) do
  hl.animation({
    leaf = animation[1],
    enabled = animation[2],
    speed = animation[3],
    bezier = animation[4],
    style = animation[5],
  })
end
