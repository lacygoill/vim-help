" Functions {{{1
fu! help#auto_preview(action) abort "{{{2
    if a:action ==# 'is_active'
        return get(s:, 'my_auto_preview', 0) == 1
    else
        let s:my_auto_preview = a:action ==# 'enable' ? 1 : 0
    endif
    echo '[auto-preview] '.(s:my_auto_preview ? 'ON' : 'OFF')
endfu

fu! s:has_right_syntax() abort "{{{2
    return index(s:keyword2syntax[s:keyword], s:syntax_under_cursor()) >= 0
endfu

fu! help#hide_noise(action) abort "{{{2
    if a:action ==# 'is_active'
        return match(execute('syn list helpHyperTextEntry'), 'conceal') != -1
    elseif a:action ==# 'enable'
        " The name of the syntax item `helpHyperTextEntry` was found with
        " `zS`. Its definition was found with `:Verbose syn list helpHyperTextEntry`.
        syn clear helpHyperTextEntry
        syn match helpHyperTextEntry /\*[#-)!+-~]\+\*\s/he=e-1 contains=helpStar conceal
        syn match helpHyperTextEntry /\*[#-)!+-~]\+\*$/ contains=helpStar conceal
        echo '[hide noise] ON'
    else
        syn clear helpHyperTextEntry
        syn match helpHyperTextEntry /\*[#-)!+-~]\+\*\s/he=e-1 contains=helpStar
        syn match helpHyperTextEntry /\*[#-)!+-~]\+\*$/ contains=helpStar
        echo '[hide noise] OFF'
    endif
endfu

fu! s:highlight_tag() abort "{{{2
    " go to preview window
    wincmd P
    " check we're there
    if &l:pvw
        if exists('w:my_preview_tag')
            call matchdelete(w:my_preview_tag)
        endif
        let pattern = '\v%'.line('.').'l%'.col('.').'c\S+'
        let w:my_preview_tag = matchadd('IncSearch', pattern)
    endif
    " back to original window
    wincmd p
endfu

fu! help#main(keyword, lhs, fwd) abort "{{{2
    try
        let s:keyword = a:keyword

        " try to position the cursor on the next relevant tag
        if !s:search_tag(a:keyword, a:lhs, a:fwd)
            return ''
        endif

        if index(['command', 'example'], a:keyword) >= 0 || !get(s:, 'my_auto_preview', 0)
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
            return ''
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
        return 'echoerr '.string(v:exception)
    endtry
    return ''
endfu

fu! s:open_preview() abort "{{{2
    if s:keyword ==# 'option'
        " sometimes option names are followed by punctuation
        " characters which aren't a part of the tag name
        let ident = matchstr(expand('<cword>'), "'.\\{-}'")
    elseif s:keyword ==# 'hypertext'
        let ident = matchstr(expand('<cWORD>'), '\v.{-}\|\zs.{-1,}\ze\|.*')
    else
        return
    endif

    if empty(ident)
        return
    endif

    try
        " Suppose we have already used our mapping `]h`:
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
        " We have to remove the autocmd. Otherwise, we can't repeat `]h`,
        " without closing the preview window.
        sil! au! my_help_close_preview_window
        "  │
        "  └─ if it's the 1st time we hit `]h` since the autocmd has
        "     been removed, there won't be any autocmd

        " Using `C-w }` instead of `:ptag` is more reliable.
        " For example,  if an  identifier in  a help file  begins with  a slash,
        " `:ptag` will,  wrongly, interpret  it as a  regex, instead  of literal
        " string.
        " Example:    :h usr_41|/\\C
        " We would need to escape the slash:
        "
        "         let ident = '/\V'.escape(ident[1:], '\')
        exe "norm! \<c-w>}"
    catch
        echohl ErrorMsg
        " ┌─ in case of an error, this will just display the message
        " │  it won't raise a real error (stack trace, abort function…)
        " │
        echo v:exception
        echohl NONE
        return 0
    endtry
    return 1
endfu

fu! s:search_tag(keyword, lhs, fwd) abort "{{{2
    let g:motion_to_repeat = a:lhs

    let pattern = s:keyword2pattern[a:keyword]
    let flags   = (a:fwd ? '' : 'b').'W'

    let orig_pos = getcurpos()
    let find_sth = search(pattern, flags)

    norm! m'

    while find_sth && !s:has_right_syntax()
        let find_sth = search(pattern, flags)
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
