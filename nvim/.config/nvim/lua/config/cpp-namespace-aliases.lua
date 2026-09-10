local M = {}

local scope_types = {
  translation_unit = true,
  declaration_list = true,
  compound_statement = true,
}

local function find_alias(scope, name, source, reference_start)
  local result
  for child in scope:iter_children() do
    local _, _, child_start = child:start()
    if child_start >= reference_start then
      break
    end
    local declaration_name = child:field("name")[1]
    if declaration_name and vim.treesitter.get_node_text(declaration_name, source) == name then
      result = child:type() == "namespace_alias_definition"
    end
  end
  return result
end

local function is_namespace_alias(match, _, source, predicate)
  local nodes = match[predicate[2]]
  local node = nodes and nodes[1]
  if not node then
    return false
  end

  local name = vim.treesitter.get_node_text(node, source)
  local _, _, reference_start = node:start()
  local scope = node:parent()
  while scope do
    if scope_types[scope:type()] then
      local result = find_alias(scope, name, source, reference_start)
      if result ~= nil then
        return result
      end
    end
    scope = scope:parent()
  end
  return false
end

function M.setup()
  vim.treesitter.query.add_predicate("cpp-namespace-alias?", is_namespace_alias, { force = true })
end

return M
