if exists('g:autoloaded_help')
    finish
endif
let g:autoloaded_help = 1

" Init {{{1

" the patterns can be found in `$VIMRUNTIME/syntax/help.vim`
let s:PAT = '\\\@1<!|[#-)!+-~]\+|\|''[a-z]\{2,\}''\|''t_..'''
"            ├──────────────────┘  ├───────────────────────┘
"            │                     └ helpOption
"            └ helpHyperTextJump

let s:SYNTAX_GROUPS = ['helpBar', 'helpHyperTextJump', 'helpOption']

" Interface {{{1
fu! help#bracket_rhs(kwd, is_fwd) abort "{{{2
    let mode = mode(1)

    " If we're in visual block mode, we can't pass `C-v` directly.
    " It's going to by directly typed on the command-line.
    " On the command-line, `C-v` means:
    "
    "     “insert the next character literally”
    "
    " The solution is to double `C-v`.
    if mode is# "\<c-v>"
        let mode = "\<c-v>\<c-v>"
    endif

    return printf(":\<c-u>call help#bracket_motion(%s,%d,%s)\<cr>",
    \             string(a:kwd), a:is_fwd, string(mode))
endfu

fu! help#bracket_motion(kwd, is_fwd, mode) abort "{{{2
    try
        if a:mode is# 'n'
            norm! m'
        elseif index(['v', 'V', "\<c-v>"], a:mode) >= 0
            norm! gv
        endif
        " try to position the cursor on the next relevant tag
        call s:search_tag(a:is_fwd)
    catch
        return lg#catch_error()
    endtry
endfu

fu! help#preview_tag() abort "{{{2
    try
        " Why not `:exe 'ptag '..ident`?{{{
        "
        " Not reliable enough.
        "
        " For example,  if an  identifier in  a help file  begins with  a slash,
        " `:ptag` will,  wrongly, interpret  it as a  regex, instead  of literal
        " string.
        "
        " Example:
        "
        "     :h usr_41
        "     /\\C
        "
        " You would need to escape the slash:
        "
        "     let ident = '/\V'.escape(ident[1:], '\')
        "}}}
        wincmd }
        call s:highlight_tag()
        " Why `wincmd _`?{{{
        "
        " After  closing the  preview window,  the help  window isn't  maximized
        " anymore.
        "}}}
        " Do *not* use the autocmd pattern `<buffer>`.{{{
        "
        " The preview  window wouldn't be closed  when we press Enter  on a tag,
        " because – if the tag is  defined in another file – `CursorMoved` would
        " be fired in the new buffer.
        "}}}
        au CursorMoved * ++once sil! pclose | sil! wincmd _
    catch
        call lg#catch_error()
    endtry
endfu

fu! help#jump_to_tag(which_one) abort "{{{2
    if a:which_one is# 'next'
        call s:search_tag(1)
    elseif a:which_one is# 'previous'
        call s:search_tag(0)
    endif
endfu
"}}}1
" Core {{{1
fu! s:search_tag(is_fwd) abort "{{{2
    let flags = (a:is_fwd ? '' : 'b')..'W'

    let orig_pos = getcurpos()
    let find_sth = search(s:PAT, flags)

    while find_sth && !s:has_right_syntax()
        let find_sth = search(s:PAT, flags)
    endwhile

    if !s:has_right_syntax()
        call setpos('.', orig_pos)
        return 0
    endif
    return 1
endfu

fu! s:highlight_tag() abort "{{{2
    " go to preview window
    noa wincmd P
    " check we're there
    if &l:pvw
        if exists('w:my_preview_tag')
            call matchdelete(w:my_preview_tag)
        endif
        let pat = '\%'..line('.')..'l\%'..col('.')..'c\S\+'
        let w:my_preview_tag = matchadd('IncSearch', pat)
        " make sure there's no conceal so that we see the tag
        let &l:cole = 0
    endif
    " back to original window
    noa wincmd p
endfu
"}}}1
" Utilities {{{1
fu! s:has_right_syntax() abort "{{{2
    return index(s:SYNTAX_GROUPS, s:syntax_under_cursor()) >= 0
endfu

fu! s:syntax_under_cursor() abort "{{{2
    return synIDattr(synID(line('.'), col('.'), 1), 'name')
endfu

