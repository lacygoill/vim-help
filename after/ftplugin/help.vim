" Mappings {{{1

nno  <buffer><nowait><silent>  [oP  :<c-u>call help#auto_preview('enable')<cr>
nno  <buffer><nowait><silent>  ]oP  :<c-u>call help#auto_preview('disable')<cr>
nno  <buffer><nowait><silent>  coP  :<c-u>call help#auto_preview(help#auto_preview('is_active')
                                   \ ? 'disable' : 'enable')<cr>

" avoid error `E21` when hitting `p` by accident
nno  <buffer><nowait><silent>  p  <nop>
xno  <buffer><nowait><silent>  p  <nop>
nno  <buffer><nowait><silent>  q  :<c-u>call lg#window#quit()<cr>
nno  <buffer><nowait><silent>  u  <nop>

nno  <buffer><nowait><silent>  <cr>  <c-]>
nno  <buffer><nowait><silent>  <bs>  <c-t>

nno  <buffer><nowait><silent>  <c-w>P  :<c-u>sil! exe 'au! my_help_close_preview_window'
                                      \ <bar> sil! aug! my_help_close_preview_window<cr>
                                       \<c-w>P


noremap  <buffer><expr><nowait><silent>  [c  help#bracket_rhs('command', 0)
noremap  <buffer><expr><nowait><silent>  ]c  help#bracket_rhs('command', 1)

noremap  <buffer><expr><nowait><silent>  [E  help#bracket_rhs('example', 0)
noremap  <buffer><expr><nowait><silent>  ]E  help#bracket_rhs('example', 1)

noremap  <buffer><expr><nowait><silent>  [H  help#bracket_rhs('hypertext', 0)
noremap  <buffer><expr><nowait><silent>  ]H  help#bracket_rhs('hypertext', 1)

noremap  <buffer><expr><nowait><silent>  [O  help#bracket_rhs('option', 0)
noremap  <buffer><expr><nowait><silent>  ]O  help#bracket_rhs('option', 1)
"                                         │
"                                         └  can't use `o`:
"                                                it would prevent us from typing `[oP`

if stridx(&rtp, 'vim-lg-lib') >= 0
    call lg#motion#repeatable#make#all({
        \ 'mode': '',
        \ 'buffer': 1,
        \ 'axis': {'bwd': ',', 'fwd': ';'},
        \ 'from': expand('<sfile>:p').':'.expand('<slnum>'),
        \ 'motions': [
        \     {'bwd': '[c',  'fwd': ']c',},
        \     {'bwd': '[E',  'fwd': ']E',},
        \     {'bwd': '[H',  'fwd': ']H',},
        \     {'bwd': '[O',  'fwd': ']O',},
        \ ]})
endif

" Options {{{1

" When we re-display a help buffer in a 2nd window, the conceal feature
" doesn't seem to work. Re-apply the conceal options to make sure that all
" characters which are supposed to be concealed, are concealed.
augroup my_help
    au! *           <buffer>
    au  BufWinEnter <buffer>  setl cocu=nc cole=3
augroup END

" don't comment a diagram
setl cms=

" Adding `-` allows  us to correctly jump to a  tag definition, whose identifier
" contains a hyphen (for an example, see `:h usr_05 | /load-plugins`).
setl isk+=-

" Default program to call when hitting K on a word
setl keywordprg=:help

" It seems to make the text better alignmed.
setl tabstop=8

" default value in the modeline of Vim help files
setl tw=78

" Teardown {{{1

let b:undo_ftplugin = get(b:, 'undo_ftplugin', '')
    \ . (empty(get(b:, 'undo_ftplugin', '')) ? '' : '|')
    \ . "
    \   setl cms< cocu< cole< isk< kp< ts< tw<
    \ | exe 'au! my_help * <buffer>'
    \
    \ | exe 'nunmap <buffer> [oP'
    \ | exe 'nunmap <buffer> ]oP'
    \ | exe 'nunmap <buffer> coP'
    \
    \ | sil! exe 'nunmap <buffer> p'
    \ | sil! exe 'xunmap <buffer> p'
    \
    \ | sil! exe 'nunmap <buffer> q'
    \ | sil! exe 'nunmap <buffer> u'
    \
    \ | exe 'nunmap <buffer> <cr>'
    \ | exe 'nunmap <buffer> <bs>'
    \ | exe 'nunmap <buffer> <c-w>P'
    \
    \ | exe 'unmap <buffer> [c'
    \ | exe 'unmap <buffer> ]c'
    \ | exe 'unmap <buffer> [E'
    \ | exe 'unmap <buffer> ]E'
    \ | exe 'unmap <buffer> [H'
    \ | exe 'unmap <buffer> ]H'
    \ | exe 'unmap <buffer> [O'
    \ | exe 'unmap <buffer> ]O'
    \ "

