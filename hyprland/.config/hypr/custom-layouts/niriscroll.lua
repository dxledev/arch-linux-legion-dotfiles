local state = {
  offset = 0,
  visible = 1,
}

local function clamp(value, min_value, max_value)
  return math.max(min_value, math.min(max_value, value))
end

local function get_active_index(ctx)
  for i, target in ipairs(ctx.targets) do
    local win = target.window

    if win and win.active then
      return i
    end
  end

  return 1
end

local function park_offscreen(ctx, target)
  target:place({
    x = ctx.area.x,
    y = ctx.area.y,
    w = 1,
    h = 1,
  })
end

hl.layout.register("niriscroll", {
  recalculate = function(ctx)
    local n = #ctx.targets

    if n == 0 then
      return
    end

    state.visible = clamp(state.visible, 1, n)

    local active = get_active_index(ctx)

    -- Scroll right if active window moved past the visible range.
    if active > state.offset + state.visible then
      state.offset = active - state.visible
    end

    -- Scroll left if active window moved before the visible range.
    if active <= state.offset then
      state.offset = active - 1
    end

    state.offset = clamp(state.offset, 0, math.max(0, n - state.visible))

    for i, target in ipairs(ctx.targets) do
      local slot = i - state.offset

      if slot >= 1 and slot <= state.visible then
        target:place(ctx:column(slot, state.visible))
      else
        park_offscreen(ctx, target)
      end
    end
  end,

  layout_msg = function(ctx, msg)
    local command, arg = msg:match("^(%S+)%s*(.*)$")
    local n = #ctx.targets

    if command == "visible" then
      state.visible = clamp(tonumber(arg) or state.visible, 1, math.max(1, n))
      state.offset = clamp(state.offset, 0, math.max(0, n - state.visible))
      return true
    end

    if command == "one" then
      state.visible = 1
      return true
    end

    if command == "two" then
      state.visible = clamp(2, 1, math.max(1, n))
      return true
    end

    if command == "three" then
      state.visible = clamp(3, 1, math.max(1, n))
      return true
    end

    if command == "reset" then
      state.offset = 0
      state.visible = 1
      return true
    end

    return "niriscroll commands: visible <n>, one, two, three, reset"
  end,
})
