if exists('g:autoloaded_help')
    finish
endif
let g:autoloaded_help = 1

" Functions {{{1
fu! help#auto_preview(action) abort "{{{2
    if a:action ==# 'is_active'
        return get(s:, 'my_auto_preview', 0) == 1
    else
        let s:my_auto_preview = a:action ==# 'enable' ? 1 : 0
    endif
    echo '[auto-preview] '.(s:my_auto_preview ? 'ON' : 'OFF')
endfu

fu! help#bracket_rhs(kwd, is_fwd) abort "{{{2
    let mode = mode(1)

    let seq = "\<plug>(help-bracket-motion)"

    let seq .= (a:is_fwd ? "\u2001" : "\u2000")
    \
    \         .get({ 'n':      "\u2001",
    \                'v':      "\u2002",
    \                'V':      "\u2002",
    \                "\<c-v>": "\u2002",
    \                'o':      "\u2003" }, mode, 'invalid')
    \
    \         .get({ 'command':   "\u2001",
    \                'example':   "\u2002",
    \                'hypertext': "\u2003",
    \                'option':    "\u2004", }, a:kwd, 'invalid')
    \
    \         ."\<cr>"

    if seq !~# 'invalid.\?\r'
        call feedkeys(seq, 'i')
    endif
    return ''
endfu

fu! help#bracket_motion() abort "{{{2
    try
        let args = split(input(''), '\zs')

        let is_fwd = args[0] ==# "\u2001" ? 1 : 0

        let mode = get({
        \                "\u2001": 'n',
        \                "\u2002": 'v',
        \                "\u2003": 'o',
        \              }, args[1], '')

        let kwd = get({
        \               "\u2001": 'command',
        \               "\u2002": 'example',
        \               "\u2003": 'hypertext',
        \               "\u2004": 'option',
        \             }, args[2], '')

        if empty(mode) || empty(kwd)
            return
        endif

        let s:kwd = kwd

        if mode ==# 'v'
            norm! gv
        endif

        " try to position the cursor on the next relevant tag
        if !s:search_tag(kwd, is_fwd)
            return
        endif

        if index(['command', 'example'], kwd) >= 0 || !get(s:, 'my_auto_preview', 0)
            return ''
        endif

        " try to open preview window
        " it may fail because some words which are colored as tags don't have any
        " matching tag:
        "                 :h
        "                 /pi_logipat
        "                 k$
        "                 ]h
        if !s:open_preview()
            return
        endif

        call s:highlight_tag()

        " We need to install a fire-once autocmd to close the preview
        " window when we'll move the cursor. But we can't do it now.
        "
        " Why?
        " The `search()` invocation inside `s:search_tag()` fires `CursorMoved`.
        " And for some reason, this motion would trigger our closing autocmd too soon.
        " It shouldn't happen, since `search()` is invoked BEFORE the installation…
        " Anyway, a solution is to delay the installation of the autocmd.
        call timer_start(0, { -> s:teardown_auto_preview() })

    catch
        return lg#catch_error()
    endtry
endfu

fu! s:has_right_syntax() abort "{{{2
    return index(s:keyword2syntax[s:kwd], s:syntax_under_cursor()) >= 0
endfu

fu! s:highlight_tag() abort "{{{2
    " go to preview window
    noautocmd wincmd P
    " check we're there
    if &l:pvw
        if exists('w:my_preview_tag')
            call matchdelete(w:my_preview_tag)
        endif
        let pat = '\v%'.line('.').'l%'.col('.').'c\S+'
        let w:my_preview_tag = matchadd('IncSearch', pat)
        " make sure there's no conceal so that we see the tag
        let &l:cole = 0
    endif
    " back to original window
    noautocmd wincmd p
endfu

fu! s:open_preview() abort "{{{2
    if s:kwd ==# 'option'
        " sometimes option names are followed by punctuation
        " characters which aren't a part of the tag name
        let ident = matchstr(expand('<cword>'), "'.\\{-}'")
    elseif s:kwd ==# 'hypertext'
        let ident = matchstr(expand('<cWORD>'), '\v.{-}\|\zs.{-1,}\ze\|.*')
    else
        return 0
    endif

    if empty(ident)
        return 0
    endif

    try
        " Why remove the autocmd?{{{
        "
        " Suppose we have already used our mapping `]H`:
        "
        "         the cursor is on a tag
        "         the preview window is open
        "         a fire-once autocmd is installed
        "
        " In this case, the next `:ptag` will trigger:
        "
        "       1. CursorMoved
        "       2. the autocmd
        "       3. close the preview window
        "
        " If we don't remove the autocmd,  we can't repeat `]H`, without closing
        " the preview window.
        "}}}
        sil! au! my_help_close_preview_window
        "  │
        "  └─ if it's the 1st time we hit `]H` since the autocmd has
        "     been removed, there won't be any autocmd

        " Why not `:ptag`?{{{
        "
        " `C-w }` is more reliable.
        " For example,  if an  identifier in  a help file  begins with  a slash,
        " `:ptag` will,  wrongly, interpret  it as a  regex, instead  of literal
        " string.
        " Example:    :h usr_41|/\\C
        " We would need to escape the slash:
        "
        "         let ident = '/\V'.escape(ident[1:], '\')
        "}}}
        exe "norm! \<c-w>}"
    catch
        call lg#catch_error()
        return 0
    endtry
    return 1
endfu

fu! s:search_tag(kwd, is_fwd) abort "{{{2
    let pat = s:keyword2pattern[a:kwd]
    let flags = (a:is_fwd ? '' : 'b').'W'

    let orig_pos = getcurpos()
    let find_sth = search(pat, flags)

    norm! m'

    while find_sth && !s:has_right_syntax()
        let find_sth = search(pat, flags)
    endwhile

    if !s:has_right_syntax()
        call setpos('.', orig_pos)
        return 0
    endif
    return 1
endfu

fu! s:syntax_under_cursor() abort "{{{2
    return synIDattr(synID(line('.'), col('.'), 1), 'name')
endfu

fu! s:teardown_auto_preview() abort "{{{2
    augroup my_help_close_preview_window
        au!
        "              ┌─ if we use `<buffer>`, the preview window wouldn't be
        "              │  closed when we hit Enter on a tag, because `CursorMoved`
        "              │  would occur in the new buffer;
        "              │  if the tag is defined in another file
        "              │
        au CursorMoved * pclose
                      \| wincmd _
                      \| exe 'au!  my_help_close_preview_window'
                      \|      aug! my_help_close_preview_window
                      " after closing the preview window, the help window isn't maximized
                      " anymore, therefore we execute `wincmd _`
    augroup END
endfu

" Variables {{{1

" The patterns can be found in `$VIMRUNTIME/syntax/help.vim`.
let s:keyword2pattern = {
\                         'command'   : '`[^` \t]\+`',
\                         'example'   : ' \?>\n\_.\{-}\zs\S',
\                         'hypertext' : '\\\@<!|[#-)!+-~]\+|',
\                         'option'    : '''[a-z]\{2,\}''\|''t_..''',
\                       }

let s:keyword2syntax = {
\                        'command'   : ['helpBacktick'],
\                        'example'   : ['helpExample'],
\                        'hypertext' : ['helpBar', 'helpHyperTextJump'],
\                        'option'    : ['helpOption'],
\                      }
