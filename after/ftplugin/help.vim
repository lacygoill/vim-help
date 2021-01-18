" Mappings {{{1

" avoid error `E21` when pressing `p` by accident
nno  <buffer><nowait> p <cmd>call help#previewTag()<cr>
xno  <buffer><nowait> p <nop>
nmap <buffer><nowait> q <plug>(my_quit)
nno  <buffer><nowait> u <nop>

nno <buffer><nowait> <cr> <c-]>
nno <buffer><nowait> <bs> <c-t>

nno <buffer><nowait> ( <cmd>call help#jumpToTag('hypertext', 'previous')<cr>
nno <buffer><nowait> ) <cmd>call help#jumpToTag('hypertext', 'next')<cr>
nno <buffer><nowait> < <cmd>call help#jumpToTag('option', 'previous')<cr>
nno <buffer><nowait> > <cmd>call help#jumpToTag('option', 'next')<cr>
nno <buffer><nowait> z} <c-w>z<c-w>_

" Options {{{1

" When we re-display a help buffer in  a 2nd window, the conceal feature doesn't
" seem to work.   Re-apply the conceal options to make  sure that all characters
" which are supposed to be concealed, are concealed.
setl cocu=nc cole=3

" don't comment a diagram
setl cms=

" Adding  `-` lets  us  correctly jump  to a  tag  definition, whose  identifier
" contains a hyphen (for an example, see `:h usr_05 /load-plugins`).
" Warning:{{{
"
" If you customize `'isk'` further, make sure to update `s:restore_these()` in:
"
"     ~/.vim/plugged/vim-session/plugin/session.vim
"}}}
setl isk+=-
    augroup MyHelp
        au! * <buffer>
        " Without  this  autocmd,  our  'isk'  configuration  is  lost  when  we
        " redisplay a help file after quitting it `:h|q|h`.
        au BufWinEnter <buffer> setl isk+=-
        " Why resetting these options to their default values in a popup?  Doesn't Vim do it automatically?{{{
        "
        " Apparently, not always.
        "
        "     $ vim -Nu NONE +'set scl=yes previewpopup=height:10,width:60'
        "     :h
        "     /bar
        "     :wincmd }
        "}}}
        au BufWinEnter <buffer> if win_gettype() is# 'popup' | setl scl&vim wrap&vim cole&vim | endif
    augroup END

" default program to call when pressing `K` on a word
setl kp=:help

" It seems to make the text better aligned.
setl ts=8

" default value in the modeline of Vim help files
setl tw=78

" Teardown {{{1

let b:undo_ftplugin = get(b:, 'undo_ftplugin', 'exe')
    \ .. '| call help#undoFtplugin()'

