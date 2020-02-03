" Author: Jimmy Huang (1902161621@qq.com)
" License: WTFPL

" goto --> declaration | definition | typeDefinition | implementation 
" | references and so on. 
"
function! goto#Init() abort
"{{{
  let s:available_goto = ['declaration',
                        \'definition',
                        \'typeDefinition',
                        \'implementation',
                        \'references']
  let g:ECY_goto_info = []
  let s:goto_lists = []
"}}}
endfunction

function! goto#Selecting_cb(line, event, index, nodes) abort
"{{{
  let l:item = s:goto_lists[a:index]
  call utility#MoveToBuffer(l:item['line'], 
        \l:item['colum'], 
        \l:item['path'], 
        \'current buffer')
"}}}
endfunction

function! goto#Go_cb(items) abort
"{{{
  let s:goto_lists = a:items['Results']
  if len(s:goto_lists) > 1
    call leaderf_ECY#items_selecting#Start(s:goto_lists, 'goto#Selecting_cb')
  else
    " goto it directly.
    let l:item = a:items['Results'][0]['position']
    if l:item != {}
      call utility#MoveToBuffer(l:item['line'], 
            \l:item['colum'], 
            \l:item['path'], 
            \'current buffer')
    else
        call utility#ShowMsg(
              \"[ECY] Current goto have no position. So we can't jump.", 2)
    endif
  endif
"}}}
endfunction

function! goto#Go(...) abort
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
      if !utility#IsInList(l:temp, s:available_goto)
        call utility#ShowMsg(
              \"[ECY] Goto name is wrong: " . 
              \l:temp . "; available_goto: " . string(s:available_goto), 2)
        return
      endif
      call add(g:ECY_goto_info, l:temp)
    endw
  endif
  call ECY_main#Do('Goto', v:true)
"}}}
endfunction

