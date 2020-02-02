" Author: Jimmy Huang (1902161621@qq.com)
" License: WTFPL

function! symbols#Selecting_cb(line, event, index, nodes) abort
"{{{
  let l:data  = g:ECY_items_data[a:index]
  if a:event == 'acceptSelection' || a:event == 'previewResult'
    let l:temp = l:data['position']
    call utility#MoveToBuffer(l:temp['line'], 
          \l:temp['colum'], 
          \l:temp['path'], 
          \'current buffer')
  endif
"}}}
endfunction

function! symbols#ReturingResults_cb(items_2_show) abort
  call leaderf_ECY#items_selecting#Start(a:items_2_show, 'symbols#Selecting_cb')
endfunction
