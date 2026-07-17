; extends

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
