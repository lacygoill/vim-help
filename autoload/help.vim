if exists('g:autoloaded_help')
    finish
endif
let g:autoloaded_help = 1

" Init {{{1

import Catch from 'lg.vim'

" the patterns can be found in `$VIMRUNTIME/syntax/help.vim`
const s:PAT_HYPERTEXT = '\\\@1<!|[#-)!+-~]\+|'
const s:PAT_OPTION = '''[a-z]\{2,\}''\|''t_..'''

const s:SYNTAX_GROUPS_HYPERTEXT =<< trim END
    helpBar
    helpHyperTextJump
END

const s:SYNTAX_GROUPS_OPTION = ['helpOption']

" Interface {{{1
fu help#preview_tag() abort "{{{2
    if index(s:SYNTAX_GROUPS_HYPERTEXT + s:SYNTAX_GROUPS_OPTION, s:syntax_under_cursor()) == -1
        return
    endif
    try
        " Why not `:exe 'ptag ' .. ident`?{{{
        "
        " Not reliable enough.
        "
        " For example,  if an  identifier in  a help file  begins with  a slash,
        " `:ptag` will – wrongly – interpret it as a regex, instead of a literal
        " string.
        "
        " Example:
        "
        "     :h usr_41
        "     /\\C
        "
        " You would need to escape the slash:
        "
        "     let ident = '/\V' .. escape(ident[1:], '\')
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
        au CursorMoved * ++once call s:close_preview()
    catch
        call s:Catch()
    endtry
endfu

fu help#jump_to_tag(type, dir) abort "{{{2
    let flags = (a:dir is# 'previous' ? 'b' : '') .. 'W'

    let pos = getcurpos()
    let pat = s:PAT_{toupper(a:type)}
    let find_sth = search(pat, flags)

    while find_sth && !s:has_right_syntax(a:type)
        let find_sth = search(pat, flags)
    endwhile

    if !s:has_right_syntax(a:type)
        call setpos('.', pos)
    else
        " allow us to jump back with `C-o`
        let new_pos = getcurpos()
        call setpos('.', pos)
        norm! m'
        call setpos('.', new_pos)
    endif
endfu

fu help#undo_ftplugin() abort "{{{2
    setl cms< cocu< cole< isk< ts< tw<
    set kp<
    au! my_help * <buffer>

    sil! nunmap <buffer> p
    sil! xunmap <buffer> p

    sil! nunmap <buffer> q
    sil! nunmap <buffer> u

    nunmap <buffer> (
    nunmap <buffer> )
    nunmap <buffer> <
    nunmap <buffer> >
    nunmap <buffer> z}
    nunmap <buffer> <cr>
    nunmap <buffer> <bs>
endfu
"}}}1
" Core {{{1
fu s:highlight_tag() abort "{{{2
    let winid = s:preview_getid()
    let matchid = getwinvar(winid, '_preview_tag')
    if matchid
        call matchdelete(matchid, winid)
    endif
    call win_execute(winid, 'let w:_tag_pos = getcurpos()')
    let [lnum, col] = getwinvar(winid, '_tag_pos')[1:2]
    let pat = '\%' .. lnum .. 'l\%' .. col .. 'c\S\+'
    let _preview_tag = matchadd('IncSearch', pat, 10, -1, {'window': winid})
    call setwinvar(winid, '_preview_tag', _preview_tag)
endfu

fu s:close_preview() abort "{{{2
    if exists('+pvp') && &pvp != ''
        let winid = popup_findpreview()
        call popup_close(winid)
    else
        pclose
        wincmd _
    endif
endfu
"}}}1
" Utilities {{{1
fu s:has_right_syntax(type) abort "{{{2
    return index(s:SYNTAX_GROUPS_{toupper(a:type)}, s:syntax_under_cursor()) >= 0
endfu

fu s:syntax_under_cursor() abort "{{{2
    " twice because of bug: https://github.com/vim/vim/issues/5252
    let id = synID('.', col('.'), 1)
    let id = synID('.', col('.'), 1)
    return synIDattr(id, 'name')
endfu

fu s:preview_getid() abort "{{{2
    if exists('+pvp') && &pvp != ''
        let winid = popup_findpreview()
    else
        let winnr = range(1, winnr('$'))->map({_, v -> getwinvar(v, '&pvw')})->match(1) + 1
        let winid = win_getid(winnr)
    endif
    return winid
endfu

