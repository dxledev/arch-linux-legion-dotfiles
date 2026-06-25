local ls = require("luasnip")
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node

ls.add_snippets("cpp", {
  s("stdo", {
    t("std::cout << "),
    i(1),
    t(";"),
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

