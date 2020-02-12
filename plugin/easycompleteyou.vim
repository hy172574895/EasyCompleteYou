" Author: Jimmy Huang (1902161621@qq.com)
" License: WTFPL

" This is basic vim plugin boilerplate
let s:save_cpo = &cpo
set cpo&vim

let g:ECY_starttime = reltimefloat(reltime())

function! s:restore_cpo()
  let &cpo = s:save_cpo
  unlet s:save_cpo
endfunction

let g:ECY_version = {'version': 10, 'tags': '1.0'}
let g:is_vim = !has('nvim')

if exists( "g:loaded_easycomplete" )
  finish
elseif v:version < 800
  echohl WarningMsg |
        \ echomsg "ECY unavailable: requires Vim 8.0+." |
        \ echohl None
  call s:restore_cpo()
  finish
elseif &encoding !~? 'utf-\?8'
  echohl WarningMsg |
        \ echomsg "ECY unavailable: requires UTF-8 encoding. " .
        \ "Put the line 'set encoding=utf-8' in your vimrc." |
        \ echohl None
  call s:restore_cpo()
  finish
elseif !has('python3')
  echohl WarningMsg |
        \ echomsg "ECY unavailable: unable to load Python3." |
        \ echohl None
  call s:restore_cpo()
  finish
elseif ( g:is_vim && (!exists('*job_start') || !exists('*ch_close_in')) ) || 
      \ (!g:is_vim && !has('nvim-0.2.0'))
  echohl WarningMsg |
        \ echomsg "ECY unavailable: requires NeoVim >= 0.2.0 ".
        \ "or Vim 8 with +job +channel." |
        \ echohl None
  call s:restore_cpo()
  finish
elseif !exists( '*json_decode' )
  echohl WarningMsg |
        \ echomsg "ECY unavailable: requires with function of json_decode. ".
        \ "You should build Vim with this feature." |
        \ echohl None
  call s:restore_cpo()
  finish
endif

if !g:is_vim && exists('*nvim_win_set_config')
  let g:has_floating_windows_support = 'nvim'
  " TODO:
  let g:has_floating_windows_support = 'has_no'
elseif has('textprop') || has('popupwin')
  let g:has_floating_windows_support = 'vim'
else
  let g:has_floating_windows_support = 'has_no'
  let g:ECY_use_floating_windows_to_be_popup_windows = v:false
endif

let g:loaded_easycomplete = v:true

" main:
call diagnosis#Init()
call completion_preview_windows#Init()
call color_completion#Init()
call goto#Init()
call ECY_main#Start()

let g:ECY_endtime = reltimefloat(reltime())
let g:ECY_start_time = g:ECY_endtime - g:ECY_starttime

" This is basic vim plugin boilerplate
call s:restore_cpo()
