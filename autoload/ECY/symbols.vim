" Author: Jimmy Huang (1902161621@qq.com)
" License: WTFPL

function! ECY#symbols#Selecting_cb(line, event, index, nodes) abort
"{{{
  let l:data  = g:ECY_items_data[a:index]
  let g:abc = a:nodes
  if a:event == 'acceptSelection' || a:event == 'previewResult'
    let l:temp = l:data['position']

    " we do this maybe it's a bug of leaderf
    " there no same problem in goto.vim
    let l:node = 'nothing'
    if a:nodes == 't'
      let l:node = 't'
    endif

    call ECY#utility#MoveToBuffer(l:temp['line'], 
          \l:temp['colum'], 
          \l:temp['path'], 
          \l:node)
  endif
"}}}
endfunction

function! ECY#symbols#ReturingResults_cb(items_2_show) abort
  call ECY#utility#StartLeaderfSelecting(a:items_2_show, 'ECY#symbols#Selecting_cb')
endfunction
