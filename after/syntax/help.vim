" Conceal syntax item helpNotVi.
"
" We found the name `helpNotVi` with `zs`.
" Its definition was found with `Verbose syn list helpNotVi`.
syn region helpNotVi start="{only" start="{not" start="{Vi[: ]" end="}"  contains=helpLeadBlank,helpHyperTextJump conceal
