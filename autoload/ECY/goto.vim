" Author: Jimmy Huang (1902161621@qq.com)
" License: WTFPL

" goto --> declaration | definition | typeDefinition | implementation 
" | references and so on. 
"
function! ECY#goto#Init() abort
"{{{
  let s:available_goto = ['declaration',
                        \'definition',
                        \'typeDefinition',
                        \'implementation',
                        \'references']
  let g:ECY_goto_info = []
  let s:goto_lists = []
  let g:ECY_show_goto_hint = get(g:, 'ECY_show_goto_hint', v:false)
"}}}
endfunction

function! ECY#goto#Selecting_cb(line, event, index, nodes) abort
"{{{
  let l:item = s:goto_lists[a:index]
  if l:item['position'] != {}
    let l:item = l:item['position']
    call s:MoveToBuffer(l:item['line'], 
          \l:item['colum'], 
          \l:item['path'], 
          \a:nodes)
  else
      call ECY#utility#ShowMsg(
            \"[ECY] Current goto have no position. So we can't jump.", 2)
  endif
"}}}
endfunction

function! s:MoveToBuffer(line, colum, buffer_name, windows_to_show) abort
"{{{
  let l:windows_to_show = 'nothing'
  if a:windows_to_show == 't'
    " we do this maybe it's a bug of leaderf
    " there no same problem in goto.vim
    let l:windows_to_show = 't'
  endif
  if g:ECY_show_goto_hint
    call ECY#utility#ShowMsg("[ECY] You had gone to : " . ECY#utility#FormatPosition(a:line, a:colum) , 2)
  endif
  call ECY#utility#MoveToBuffer(a:line, a:colum, a:buffer_name,l:windows_to_show)
"}}}
endfunction


function! ECY#goto#Go_cb(items) abort
"{{{
  if a:items['ID'] < ECY_main#GetVersionID()
    return
  endif
  let s:goto_lists = a:items['Results']
  if len(s:goto_lists) > 1
    call ECY#utility#StartLeaderfSelecting(s:goto_lists, 'ECY#goto#Selecting_cb')
  elseif len(s:goto_lists) == 0
      call ECY#utility#ShowMsg(
            \"[ECY] Engine return none at current position.", 2)
  else
    " goto it directly.
    let l:item = a:items['Results'][0]['position']
    if l:item != {}
      call s:MoveToBuffer(l:item['line'], 
            \l:item['colum'], 
            \l:item['path'], 
            \'current buffer')
    else
      call ECY#utility#StartLeaderfSelecting(s:goto_lists, 'ECY#goto#Selecting_cb')
    endif
  endif
"}}}
endfunction

function! ECY#goto#Go(...) abort
"{{{
  if a:0 == 0
    " ask server that where current position can goto.
    let g:ECY_goto_info = []
  else
    " check name first
    let g:ECY_goto_info = []
    let i = 0
    while i < a:0
      let l:temp = a:000[i]
      let i += 1
      if !ECY#utility#IsInList(l:temp, s:available_goto)
        call ECY#utility#ShowMsg(
              \"[ECY] Goto wrong name: " . 
              \l:temp . "; available_goto: " . string(s:available_goto), 2)
        return
      endif
      call add(g:ECY_goto_info, l:temp)
    endw
  endif
  if g:ECY_show_goto_hint
    call ECY#utility#ShowMsg("[ECY] Going to ....", 2)
  endif
  call ECY_main#ChangeVersionID()
  call ECY_main#Do('Goto', v:true)
"}}}
endfunction
