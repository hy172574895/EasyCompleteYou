" Author: Jimmy Huang (1902161621@qq.com)
" License: WTFPL

" This is basic vim plugin boilerplate
let s:save_cpo = &cpo
set cpo&vim

let g:ECY_starttime = reltimefloat(reltime())
let g:loaded_easycomplete = v:false

function! s:restore_cpo()
  let &cpo = s:save_cpo
  unlet s:save_cpo
endfunction

let g:ECY_version = {'version': 19, 'tags': '1.3'}
let g:is_vim = !has('nvim')

if g:loaded_easycomplete
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
elseif ( g:is_vim && (!exists('*job_start') || !has('channel')) ) || 
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
elseif has('textprop') && has('popupwin')
  let g:has_floating_windows_support = 'vim'
else
  let g:has_floating_windows_support = 'has_no'
endif

if get(g:, 'ECY_PreviewWindows_style', 'append') == 'preview_windows'
  let g:has_floating_windows_support = 'has_no'
endif

let  g:ECY_leaderf_preview_mode = get(g:, 'ECY_leaderf_preview_mode', 'floating_windows')

if g:has_floating_windows_support == 'has_no'
  let g:ECY_use_floating_windows_to_be_popup_windows = v:false
  let g:ECY_leaderf_preview_mode = 'normal'
endif

command! -bar -nargs=0 ECYWorkSpaceSymbols call ECY_main#Execute('get_workspace_symbols')
command! -bar -nargs=0 ECYDocumentSymbols  call ECY_main#Execute('get_symbols')
command! -bar -nargs=0 ECYToggleDiagnosis  call ECY#diagnosis#Toggle()
command! -bar -nargs=0 ECYDiagnosisLists   call ECY#diagnosis#ShowSelecting()
command! -bar -nargs=0 ECYListEngine       call ECY_main#Do("GetAllEngineInfo", v:true)
command! -bar -nargs=0 ECYDocHelp          call ECY_main#Do("OnDocumentHelp", v:true)

command! -bar -nargs=1 ECYInstall         call ECY_main#Install('<args>')
command! -bar -nargs=1 ECYGoTo            call ECY#goto#Go('<args>')

" main:
call ECY#utility#Init()
call ECY#diagnosis#Init()
call ECY#completion_preview_windows#Init()
call ECY#color_completion#Init()
call ECY#document_help#Init()
call ECY#goto#Init()
call ECY#install#Init()
call ECY_main#Start()
filetype on

let g:ECY_endtime = reltimefloat(reltime())
let g:ECY_start_time = g:ECY_endtime - g:ECY_starttime

let g:loaded_easycomplete = v:true
" This is basic vim plugin boilerplate
call s:restore_cpo()
