local M = {}

M.config = {
  events = {
    "InsertEnter",
    "TextChanged",
    "TextChangedI",
    "TextChangedP",
  },
  filetypes = {
    "html",
    "javascriptreact",
    "typescriptreact",
  },
  html_void_elements = {
    area = true,
    base = true,
    br = true,
    col = true,
    embed = true,
    hr = true,
    img = true,
    input = true,
    link = true,
    meta = true,
    param = true,
    source = true,
    track = true,
    wbr = true,
  },
}

local function is_supported_buffer(buffer)
  return vim.tbl_contains(M.config.filetypes, vim.bo[buffer].filetype)
end

local function cursor_empty_tag(buffer)
  local row, column = unpack(vim.api.nvim_win_get_cursor(0))
  local line = vim.api.nvim_buf_get_lines(buffer, row - 1, row, false)[1]
  local cursor_position = column + 1
  local start_position = line:sub(1, cursor_position):match(".*()<")

  if not start_position then
    return nil
  end

  local end_position = line:find(">", start_position, true)
  if not end_position or cursor_position > end_position then
    return nil
  end

  local text = line:sub(start_position, end_position)
  if text ~= "<>" and text ~= "</>" then
    return nil
  end

  return {
    end_col = end_position,
    kind = text == "<>" and "opening" or "closing",
    row = row - 1,
    start_col = start_position - 1,
    text = text,
  }
end

local function node_text(node, buffer)
  return vim.treesitter.get_node_text(node, buffer)
end

local function jsx_counterpart(buffer, empty_tag)
  local ok, parser = pcall(vim.treesitter.get_parser, buffer)
  if not ok or not parser then
    return nil
  end

  local tree = parser:parse(true)[1]
  if not tree then
    return nil
  end

  local node =
    tree:root():named_descendant_for_range(empty_tag.row, empty_tag.start_col, empty_tag.row, empty_tag.end_col)

  while node and node:type() ~= "jsx_element" do
    node = node:parent()
  end

  if not node then
    return nil
  end

  local current_field = empty_tag.kind == "opening" and "open_tag" or "close_tag"
  local counterpart_field = empty_tag.kind == "opening" and "close_tag" or "open_tag"
  local current_node = node:field(current_field)[1]
  local counterpart_node = node:field(counterpart_field)[1]

  if not current_node or not counterpart_node or node_text(current_node, buffer) ~= empty_tag.text then
    return nil
  end

  local start_row, start_col, end_row, end_col = counterpart_node:range()
  return {
    end_col = end_col,
    end_row = end_row,
    start_col = start_col,
    start_row = start_row,
    text = node_text(counterpart_node, buffer),
  }
end

local function find_tag_end(document, start_position)
  local brace_depth = 0
  local index = start_position + 1
  local quote

  while index <= #document do
    local character = document:sub(index, index)

    if quote then
      if character == "\\" then
        index = index + 1
      elseif character == quote then
        quote = nil
      end
    elseif character == '"' or character == "'" or character == "`" then
      quote = character
    elseif character == "{" then
      brace_depth = brace_depth + 1
    elseif character == "}" and brace_depth > 0 then
      brace_depth = brace_depth - 1
    elseif character == ">" and brace_depth == 0 then
      return index
    end

    index = index + 1
  end
end

local function parse_tag(document, start_position, end_position)
  local body = document:sub(start_position + 1, end_position - 1):match("^%s*(.-)%s*$")
  if body:sub(1, 1) == "!" or body:sub(1, 1) == "?" then
    return nil
  end

  local kind = "opening"
  if body:sub(1, 1) == "/" then
    kind = "closing"
    body = body:sub(2):match("^%s*(.-)%s*$")
  end

  local name = body:match("^([%a_$][%w_:$%.%-]*)")
  if body ~= "" and not name then
    return nil
  end

  return {
    end_position = end_position,
    kind = kind,
    name = name or "",
    self_closing = kind == "opening" and body:match("/%s*$") ~= nil,
    start_position = start_position,
    text = document:sub(start_position, end_position),
  }
end

local function document_tags(document)
  local tags = {}
  local search_position = 1

  while search_position <= #document do
    local start_position = document:find("<", search_position, true)
    if not start_position then
      break
    end

    if document:sub(start_position, start_position + 3) == "<!--" then
      local comment_end = document:find("-->", start_position + 4, true)
      search_position = comment_end and comment_end + 3 or #document + 1
    else
      local end_position = find_tag_end(document, start_position)
      if not end_position then
        break
      end

      local tag = parse_tag(document, start_position, end_position)
      if tag then
        table.insert(tags, tag)
      end
      search_position = end_position + 1
    end
  end

  return tags
end

local function opens_scope(tag)
  return tag.kind == "opening" and not tag.self_closing and not M.config.html_void_elements[tag.name:lower()]
end

local function matching_structural_tag(tags, current_index, kind)
  local depth = 0

  if kind == "opening" then
    for index = current_index + 1, #tags do
      local tag = tags[index]
      if opens_scope(tag) then
        depth = depth + 1
      elseif tag.kind == "closing" then
        if depth == 0 then
          return tag
        end
        depth = depth - 1
      end
    end
  else
    for index = current_index - 1, 1, -1 do
      local tag = tags[index]
      if tag.kind == "closing" then
        depth = depth + 1
      elseif opens_scope(tag) then
        if depth == 0 then
          return tag
        end
        depth = depth - 1
      end
    end
  end
end

local function line_offsets(lines)
  local offsets = {}
  local offset = 0

  for index, line in ipairs(lines) do
    offsets[index] = offset
    offset = offset + #line + 1
  end

  return offsets
end

local function offset_position(lines, offset)
  local current_offset = 0

  for index, line in ipairs(lines) do
    if offset <= current_offset + #line then
      return index - 1, offset - current_offset
    end
    current_offset = current_offset + #line + 1
  end
end

local function html_counterpart(buffer, empty_tag)
  local lines = vim.api.nvim_buf_get_lines(buffer, 0, -1, false)
  local document = table.concat(lines, "\n")
  local offsets = line_offsets(lines)
  local start_position = offsets[empty_tag.row + 1] + empty_tag.start_col + 1
  local end_position = offsets[empty_tag.row + 1] + empty_tag.end_col
  local tags = document_tags(document)
  local current_index

  for index, tag in ipairs(tags) do
    if tag.start_position == start_position and tag.end_position == end_position then
      current_index = index
      break
    end
  end

  if not current_index then
    return nil
  end

  local counterpart = matching_structural_tag(tags, current_index, empty_tag.kind)
  if not counterpart then
    return nil
  end

  local start_row, start_col = offset_position(lines, counterpart.start_position - 1)
  local end_row, end_col = offset_position(lines, counterpart.end_position)
  return {
    end_col = end_col,
    end_row = end_row,
    start_col = start_col,
    start_row = start_row,
    text = counterpart.text,
  }
end

local function synchronize_empty_tag(buffer)
  local empty_tag = cursor_empty_tag(buffer)
  if not empty_tag then
    return false
  end

  local filetype = vim.bo[buffer].filetype
  local counterpart = filetype == "html" and html_counterpart(buffer, empty_tag) or jsx_counterpart(buffer, empty_tag)
  if not counterpart then
    return false
  end

  local replacement = empty_tag.kind == "opening" and "</>" or "<>"
  if counterpart.text ~= replacement then
    vim.api.nvim_buf_set_text(
      buffer,
      counterpart.start_row,
      counterpart.start_col,
      counterpart.end_row,
      counterpart.end_col,
      { replacement }
    )
  end

  return true
end

local function rename_matching_tag(args)
  if not is_supported_buffer(args.buf) then
    return
  end

  if synchronize_empty_tag(args.buf) then
    return
  end

  require("nvim-ts-autotag.internal").rename_tag()
end

function M.setup()
  local group = vim.api.nvim_create_augroup("web_tag_live_rename", { clear = true })

  vim.api.nvim_create_autocmd(M.config.events, {
    group = group,
    callback = rename_matching_tag,
  })
end

return M
