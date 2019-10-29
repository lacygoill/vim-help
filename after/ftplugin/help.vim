" Mappings {{{1

" avoid error `E21` when pressing `p` by accident
nno  <buffer><nowait><silent> p :<c-u>call help#preview_tag()<cr>
xno  <buffer><nowait><silent> p <nop>
nmap <buffer><nowait><silent> q <plug>(my_quit)
nno  <buffer><nowait><silent> u <nop>

nno <buffer><nowait><silent> <cr> <c-]>
nno <buffer><nowait><silent> <bs> <c-t>

nno <buffer><nowait><silent> ( :<c-u>call help#jump_to_tag('hypertext', 'previous')<cr>
nno <buffer><nowait><silent> ) :<c-u>call help#jump_to_tag('hypertext', 'next')<cr>
nno <buffer><nowait><silent> O :<c-u>call help#jump_to_tag('option', 'previous')<cr>
nno <buffer><nowait><silent> o :<c-u>call help#jump_to_tag('option', 'next')<cr>
nno <buffer><nowait><silent> z} <c-w>z<c-w>_

" Options {{{1

" When we re-display a help buffer in a 2nd window, the conceal feature
" doesn't seem to work. Re-apply the conceal options to make sure that all
" characters which are supposed to be concealed, are concealed.
setl cocu=nc
setl cole=3

" don't comment a diagram
setl cms=

" Adding `-` allows  us to correctly jump to a  tag definition, whose identifier
" contains a hyphen (for an example, see `:h usr_05 /load-plugins`).
setl isk+=-

" Default program to call when hitting K on a word
setl keywordprg=:help

" It seems to make the text better alignmed.
setl tabstop=8

" default value in the modeline of Vim help files
setl tw=78

" Teardown {{{1

let b:undo_ftplugin = get(b:, 'undo_ftplugin', 'exe')
    \ ..'| call help#undo_ftplugin()'

