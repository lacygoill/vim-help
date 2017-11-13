" The name of the syntax item `helpNotVi` was found with `ZS`.
" Its definition was found with `Verbose syn list helpNotVi`.
syn region helpNotVi start="{only" start="{not" start="{Vi[: ]" end="}"  contains=helpLeadBlank,helpHyperTextJump conceal
