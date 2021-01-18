vim9 noclear

if exists('loaded') | finish | endif
var loaded = true

# Init {{{1

import Catch from 'lg.vim'

# the patterns can be found in `$VIMRUNTIME/syntax/help.vim`
const PAT_HYPERTEXT: string = '\\\@1<!|[#-)!+-~]\+|'
const PAT_OPTION: string = '''[a-z]\{2,\}''\|''t_..'''

const SYNTAX_GROUPS_HYPERTEXT: list<string> =<< trim END
    helpBar
    helpHyperTextJump
END

const SYNTAX_GROUPS_OPTION: list<string> = ['helpOption']

# Interface {{{1
def help#previewTag() #{{{2
    if index(SYNTAX_GROUPS_HYPERTEXT + SYNTAX_GROUPS_OPTION, SyntaxUnderCursor()) == -1
        return
    endif
    try
        # Why not `:exe 'ptag ' .. ident`?{{{
        #
        # Not reliable enough.
        #
        # For example,  if an  identifier in  a help file  begins with  a slash,
        # `:ptag` will – wrongly – interpret it as a regex, instead of a literal
        # string.
        #
        # Example:
        #
        #     :h usr_41
        #     /\\C
        #
        # You would need to escape the slash:
        #
        #     let ident = '/\V' .. escape(ident[1 :], '\')
        #}}}
        wincmd }
        HighlightTag()
        # Why `wincmd _`?{{{
        #
        # After  closing the  preview window,  the help  window isn't  maximized
        # anymore.
        #}}}
        # Do *not* use the autocmd pattern `<buffer>`.{{{
        #
        # The preview  window wouldn't be closed  when we press Enter  on a tag,
        # because – if the tag is  defined in another file – `CursorMoved` would
        # be fired in the new buffer.
        #}}}
        au CursorMoved * ++once ClosePreview()
    catch
        Catch()
    endtry
enddef

def help#jumpToTag(type: string, dir: string) #{{{2
    var flags: string = (dir == 'previous' ? 'b' : '') .. 'W'

    var pos: list<number> = getcurpos()
    var pat: string
    if type == 'option'
        pat = PAT_OPTION
    elseif type == 'hypertext'
        pat = PAT_HYPERTEXT
    endif
    var find_sth: bool = search(pat, flags) != 0

    while find_sth && !HasRightSyntax(type)
        find_sth = search(pat, flags) != 0
    endwhile

    if !HasRightSyntax(type)
        setpos('.', pos)
    else
        # allow us to jump back with `C-o`
        var new_pos: list<number> = getcurpos()
        setpos('.', pos)
        norm! m'
        setpos('.', new_pos)
    endif
enddef

def help#undoFtplugin() #{{{2
    set cms< cocu< cole< isk< kp< ts< tw<
    au! MyHelp * <buffer>

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
enddef
#}}}1
# Core {{{1
def HighlightTag() #{{{2
    var winid: number = PreviewGetid()
    var matchid: number = getwinvar(winid, '_preview_tag', 0)
    if matchid != 0
        matchdelete(matchid, winid)
    endif
    win_execute(winid, 'w:_tag_pos = getcurpos()')
    var lnum: number
    var col: number
    [lnum, col] = getwinvar(winid, '_tag_pos')[1 : 2]
    var pat: string = '\%' .. lnum .. 'l\%' .. col .. 'c\S\+'
    var _preview_tag: number = matchadd('IncSearch', pat, 0, -1, {window: winid})
    setwinvar(winid, '_preview_tag', _preview_tag)
enddef

def ClosePreview() #{{{2
    if exists('+pvp') && &pvp != ''
        popup_findpreview()->popup_close()
    else
        pclose
        wincmd _
    endif
enddef
#}}}1
# Utilities {{{1
def HasRightSyntax(type: string): bool #{{{2
    var syngroups: list<string>
    if type == 'option'
        syngroups = SYNTAX_GROUPS_OPTION
    else
        syngroups = SYNTAX_GROUPS_HYPERTEXT
    endif
    return index(syngroups, SyntaxUnderCursor()) >= 0
enddef

def SyntaxUnderCursor(): string #{{{2
    # twice because of a bug: https://github.com/vim/vim/issues/5252
    var id: number = synID('.', col('.'), true)
    id = synID('.', col('.'), true)
    return synIDattr(id, 'name')
enddef

def PreviewGetid(): number #{{{2
    var winid: number
    if exists('+pvp') && &pvp != ''
        winid = popup_findpreview()
    else
        var winnr: number = range(1, winnr('$'))
            ->mapnew((_, v) => getwinvar(v, '&pvw'))->match(true) + 1
        winid = win_getid(winnr)
    endif
    return winid
enddef

