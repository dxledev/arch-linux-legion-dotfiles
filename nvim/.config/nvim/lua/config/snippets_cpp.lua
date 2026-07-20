local ls = require("luasnip")
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node
local f = ls.function_node

ls.add_snippets("cpp", {
  s("stdo", {
    t("std::cout << "),
    i(1),
    t(";"),
  }),
})

ls.add_snippets("cpp", {
  s("stdon", {
    t("std::cout << "),
    i(1),
    t(" << '\\n';"),
  }),
})

ls.add_snippets("cpp", {
  s("stdi", {
    t("std::cin >> "),
    i(1),
    t(";"),
  }),
})

ls.add_snippets("cpp", {
  s("stdglws", {
    t("std::getline(std::cin >> std::ws, "),
    i(1),
    t(");"),
  }),
})

ls.add_snippets("cpp", {
  s("stdgl", {
    t("std::getline("),
    i(1),
    t(");"),
  }),
})

ls.add_snippets("cpp", {
  s("mainsnip", {
    t({
      "int main()",
      "{",
      "    ",
    }),
    i(1),
    t({
      "",
      "",
      "    return 0;",
      "}",
    }),
  }),
})

ls.add_snippets("cpp", {
  s("mainargs", {
    t({
      "int main(int argc, char* argv[])",
      "{",
      "    ",
    }),
    i(1),
    t({
      "",
      "",
      "    return 0;",
      "}",
    }),
  }),
})

ls.config.set_config({
  enable_autosnippets = true,
})

local function guard_name(_, snip)
  return snip.captures[1]
end

local hdef = s(
  {
    trig = "([%w_]+)%s+hdef",
    regTrig = true,
    wordTrig = false,
    snippetType = "autosnippet",
    name = "header guard",
  },
  {
    t("#ifndef "),
    f(guard_name),

    t({ "", "#define " }),
    f(guard_name),

    t({ "", "" }),
    i(1),

    t({ "", "#endif" }),
  }
)

for _, ft in ipairs({ "c", "cpp" }) do
  ls.add_snippets(ft, {
    hdef,
  })
end
