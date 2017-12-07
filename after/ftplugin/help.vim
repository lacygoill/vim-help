" Mappings {{{1

nno  <buffer><nowait><silent>  [oP  :<c-u>call help#auto_preview('enable')<cr>
nno  <buffer><nowait><silent>  ]oP  :<c-u>call help#auto_preview('disable')<cr>
nno  <buffer><nowait><silent>  coP  :<c-u>call help#auto_preview(help#auto_preview('is_active')
                                    \? 'disable' : 'enable')<cr>

" avoid error `E21` when hitting `p` by accident
nno  <buffer><nowait><silent>  p  <nop>
xno  <buffer><nowait><silent>  p  <nop>
nno  <buffer><nowait><silent>  q  :<c-u>exe my_lib#quit()<cr>
nno  <buffer><nowait><silent>  u  <nop>

nno  <buffer><nowait><silent>  <cr>  <c-]>
nno  <buffer><nowait><silent>  <BS>  <c-t>

nno  <buffer><nowait><silent>  [c  :<c-u>exe help#main('command', '[c', 0)<cr>
nno  <buffer><nowait><silent>  ]c  :<c-u>exe help#main('command', ']c', 1)<cr>

nno  <buffer><nowait><silent>  [e  :<c-u>exe help#main('example', '[e', 0)<cr>
nno  <buffer><nowait><silent>  ]e  :<c-u>exe help#main('example', ']e', 1)<cr>

nno  <buffer><nowait><silent>  [h  :<c-u>exe help#main('hypertext', '[h', 0)<cr>
nno  <buffer><nowait><silent>  ]h  :<c-u>exe help#main('hypertext', ']h', 1)<cr>

"                              ┌─ setting (can't use `o`: it would prevent us from typing `[oP`)
"                              │
nno  <buffer><nowait><silent> [s  :<c-u>exe help#main('option', '[s', 0)<cr>
nno  <buffer><nowait><silent> ]s  :<c-u>exe help#main('option', ']s', 1)<cr>

nno  <buffer><nowait><silent>  <c-w>P  :<c-u>sil! exe 'au! my_help_close_preview_window'
                                       \<bar> sil! aug! my_help_close_preview_window<cr>
                                       \<c-w>P

" Options {{{1

" When we re-display a help buffer in a 2nd window, the conceal feature
" doesn't seem to work. Re-apply the conceal options to make sure that all
" characters which are supposed to be concealed, are concealed.
augroup my_help
    au! *           <buffer>
    au  BufWinEnter <buffer>  setl cocu=nc cole=3
augroup END

" Adding `-` allows us to correctly jump to a tag definition, whose identifier
" contains a dash (for an example, see `:h usr_05 | /load-plugins`).
setl isk+=-

" Default program to call when hitting K on a word
setl keywordprg=:help

" It seems to make the text better alignmed.
setl tabstop=8

" Teardown {{{1

let b:undo_ftplugin =         get(b:, 'undo_ftplugin', '')
                    \ .(empty(get(b:, 'undo_ftplugin', '')) ? '' : '|')
                    \ ."
                    \   setl cocu< cole< isk< kp< ts<
                    \|  exe 'nunmap <buffer> [oP'
                    \|  exe 'nunmap <buffer> ]oP'
                    \|  exe 'nunmap <buffer> coP'
                    \|  exe 'nunmap <buffer> p'
                    \|  exe 'xunmap <buffer> p'
                    \|  exe 'nunmap <buffer> q'
                    \|  exe 'nunmap <buffer> u'
                    \|  exe 'nunmap <buffer> <cr>'
                    \|  exe 'nunmap <buffer> <bs>'
                    \|  exe 'nunmap <buffer> [c'
                    \|  exe 'nunmap <buffer> ]c'
                    \|  exe 'nunmap <buffer> [e'
                    \|  exe 'nunmap <buffer> ]e'
                    \|  exe 'nunmap <buffer> [h'
                    \|  exe 'nunmap <buffer> ]h'
                    \|  exe 'nunmap <buffer> [s'
                    \|  exe 'nunmap <buffer> ]s'
                    \|  exe 'nunmap <buffer> <c-w>P'
                    \|  exe 'au!  my_help * <buffer>'
                    \  "
