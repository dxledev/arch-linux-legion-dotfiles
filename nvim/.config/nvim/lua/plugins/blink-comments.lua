return {
  "saghen/blink.cmp",
  opts = function(_, opts)
    local function node_is_comment(node)
      while node do
        if node:type():find("comment") then
          return true
        end

        node = node:parent()
      end

      return false
    end

    local function in_comment()
      local ok, node = pcall(vim.treesitter.get_node)

      if ok and node and node_is_comment(node) then
        return true
      end

      local row, col = unpack(vim.api.nvim_win_get_cursor(0))
      row = row - 1
      col = math.max(col - 1, 0)

      ok, node = pcall(vim.treesitter.get_node, {
        pos = { row, col },
      })

      return ok and node and node_is_comment(node)
    end

    local old_enabled = opts.enabled

    opts.enabled = function()
      if vim.tbl_contains({ "c", "cpp", "cpp.tpp" }, vim.bo.filetype) and in_comment() then
        return false
      end

      if type(old_enabled) == "function" then
        return old_enabled()
      end

      return old_enabled ~= false
    end
  end,
}
