" Conceal syntax item helpNotVi.
"
" We found `helpNotVi` with `zs`.
" Its definition was found with:
"
"     :Verbose syn list helpNotVi
syn region help_noise_NotInVi start="{only" start="{not" start="{Vi[: ]" end="}"  contains=helpLeadBlank,helpHyperTextJump conceal

syn match help_noise_env_vrb      /\%(- \)\?Environment\_s*variables\_s*are\_s*expanded\_s*|:set_env|./ conceal
syn match help_noise_op_backslash /,\?\_s*(\?\_s*[sS]ee\_s*|option-backslash|\_s*about\_s*including\_s*spaces\_s*and\_s*backslashes)\?./ conceal
syn match help_noise_modeline /This\_s*option\_s*cannot\_s*be\_s*set\_s*from\_s*a\_s*|modeline|\_s*or\_s*in\_s*the\_s*|sandbox|,\_s*for\_s*security\_s*reasons./ conceal

" Functions arguments containing an underscore are not highlighted.{{{
"
" Example: `:h syn-region`
"
"     :sy[ntax] region {group-name} [{options}]
"                     [matchgroup={group-name}]
"                     [keepend]
"                     [extend]
"                     [excludenl]
"                     start={start_pattern} ..
"                           ^-------------^
"                     ...
"}}}
syn match helpSpecial @{[-_a-zA-Z0-9'"*+/:%#=[\]<>.,]\+}@
"                         ^

