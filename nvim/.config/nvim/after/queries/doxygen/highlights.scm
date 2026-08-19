; extends

((tag
  (tag_name) @_return
  (description) @comment.documentation.return)
 (#any-of? @_return "@return" "\\return" "@returns" "\\returns")
 (#doxygen-first-token! @comment.documentation.return)
 (#set! priority 110))
