; extends

((namespace_definition
  name: (namespace_identifier) @namespace.definition)
 (#set! priority 200))

((namespace_alias_definition
  name: (namespace_identifier) @namespace.alias)
 (#set! priority 200))

((qualified_identifier
  scope: (namespace_identifier) @namespace.alias)
 (#cpp-namespace-alias? @namespace.alias)
 (#set! priority 200))

("new" @keyword.operator.new
 (#set! priority 200))

((template_argument_list
  (_) @custom.template_argument)
 (#set! priority 200))

((operator_name) @punctuation
 (#eq? @punctuation "operator[]")
 (#set! priority 210))

(subscript_argument_list
  "[" @custom.array_bracket
  "]" @custom.array_bracket
  (#set! priority 210))
