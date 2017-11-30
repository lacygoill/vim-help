" Conceal syntax item helpNotVi.
"
" We found the name `helpNotVi` with `zs`.
" Its definition was found with `Verbose syn list helpNotVi`.
syn region help_noise_NotInVi start="{only" start="{not" start="{Vi[: ]" end="}"  contains=helpLeadBlank,helpHyperTextJump conceal

syn match help_noise_env_vrb /\%(- \)\?Environment variables are expanded |:set_env|./ conceal

" The name of the syntax item `helpHyperTextEntry` was found with
" `zS`. Its definition was found with `:Verbose syn list helpHyperTextEntry`.
syn match helpHyperTextEntry /\*[#-)!+-~]\+\*\s/he=e-1 contains=helpStar conceal
syn match helpHyperTextEntry /\*[#-)!+-~]\+\*$/        contains=helpStar conceal
