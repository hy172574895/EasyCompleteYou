" Author: Jimmy Huang (1902161621@qq.com)
" License: WTFPL

let s:show_msg_windows_nr = -1
let s:show_msg_windows_text = []
let s:show_msg_time = 5
let s:show_msg_timer_id = -1

function! utility#MoveToBuffer(line, colum, buffer_name, windows_to_show) abort
"{{{ move cursor to windows, in normal mode
" a:colum is 0-based
" a:line is 1-based
" the a:windows_to_show hightly fit leaderf
  if a:windows_to_show == 'h'
    exe 'new ' . a:buffer_name
    " horizontally new a windows at current tag
  elseif a:windows_to_show == 'v'
    " vertically new a windows at current tag
    exe 'vnew ' . a:buffer_name
  elseif a:windows_to_show == 't'
    " new a windows and new a tab
    exe 'tabedit '
    silent exe "hide edit " .  a:buffer_name
  elseif a:windows_to_show == 'to'
    " new a windows and a tab that can be a previous old one.
    silent exe 'tabedit ' . a:buffer_name
  else
    " use current buffer's windows to open that buffer if current buffer is
    " not that buffer, and if current buffer is that buffer, it will fit
    " perfectly.
    if utility#GetCurrentBufferPath() != a:buffer_name
      silent exe "hide edit " .  a:buffer_name
    endif
  endif
  call cursor(a:line, a:colum + 1)
"}}}
endfunction

function! utility#GetLoadedFile() abort
"{{{
  "return the loaded file with path
  let l:list_of_buf = []
  for l:buff in getbufinfo()
    let l:path = l:buff['name']
    let l:buf_info = {'bufnr': l:buff['bufnr'],'buf_path': l:path}
    call add(l:list_of_buf,l:buf_info)
  endfor
  return l:list_of_buf
"}}}
endfunction

function! utility#GetCurrentBufferPath(...) abort
"{{{
  " let l:full_path = fnamemodify(@%, ':p')
  let l:full_path = expand('%:p')
  return l:full_path

"}}}
endfunction

function! utility#SendKeys(keys) abort
"{{{
  call feedkeys( a:keys, 'in' )
"}}}
endfunction

function! utility#HasYCM() abort
"{{{
  if exists('g:loaded_youcompleteme')
    if g:loaded_youcompleteme == 1
      return v:true
    endif
  endif
  return v:false
"}}}
endfunction

function! utility#IsCurrentBufferBigFile()
"{{{ we use same variable as YCM's one
  if exists( 'b:ycm_largefile' )
    return b:ycm_largefile
  endif
  let threshold = g:ECY_disable_for_files_larger_than_kb * 1024
  let b:ycm_largefile =
        \ threshold > 0 && getfsize(expand('%')) > threshold
  if b:ycm_largefile
    " only echo once because this will only check once
    call utility#ShowMsg("ECY unavailable: the file exceeded the max size.", 2)
  endif
  return b:ycm_largefile
"}}}
endfunction

function! g:ShowMsg_cb(id, key) abort
"{{{
  let s:show_msg_windows_nr = -1
"}}}
endfunction

function! g:ShowMsg_timer(timer_id)
"{{{
  if a:timer_id != s:show_msg_timer_id
    return
  endif
  if s:show_msg_time != 0 
    let s:show_msg_time -= 1
  else
    if s:show_msg_windows_nr != -1
      call popup_close(s:show_msg_windows_nr)
    endif
    return
  endif
 let l:temp = 'Message Box Closing in ' . string(s:show_msg_time) . 's '
 call popup_setoptions(s:show_msg_windows_nr, {'title': l:temp})
 let s:show_msg_timer_id = timer_start(1000, function('g:ShowMsg_timer'))
"}}}
endfunction

function! utility#ShowMsg(msg, style) abort
"{{{
  " if a:style == 1 means short
  " a:style == 2 warning with no redraw
  " a:style == 3 erro with redraw
  " a:style == 4 warning with redraw
  if g:has_floating_windows_support == 'vim'
    let s:show_msg_time = 10
    let l:temp = 'Message Box Closing in ' . string(s:show_msg_time) . 's '
    let l:opts = {
          \ 'callback': 'g:ShowMsg_cb',
          \ 'minwidth': g:ECY_preview_windows_size[0][0],
          \ 'maxwidth': g:ECY_preview_windows_size[0][1],
          \ 'minheight': g:ECY_preview_windows_size[1][0],
          \ 'maxheight': g:ECY_preview_windows_size[1][1],
          \ 'title': l:temp,
          \ 'moved': 'WORD',
          \ 'border': [],
          \}
    if s:show_msg_windows_nr == -1
      let s:show_msg_windows_text = [a:msg]
      let s:show_msg_windows_nr = popup_create(s:show_msg_windows_text, l:opts)
    else
      call add(s:show_msg_windows_text, '--------------------')
      call add(s:show_msg_windows_text, a:msg)
      " delay, have new msg.
      call popup_settext(s:show_msg_windows_nr, s:show_msg_windows_text)
    endif
    let s:show_msg_timer_id = timer_start(1000, function('g:ShowMsg_timer'))
  elseif g:has_floating_windows_support == 'has_no' 
    echohl WarningMsg |
          \ echomsg a:msg |
          \ echohl None
  endif
"}}}
endfunction

function! utility#IsInList(item, list) abort
"{{{
  let i = 0
  while i < len(a:list)
    if a:item == a:list[i]
      return v:true
    endif
    let i += 1
  endw
  return v:false
"}}}
endfunction

function! utility#FormatPosition(line, colum) abort
"{{{ return such as "[34, 35]"
  let l:temp = '[' . string(a:line). ', ' . string(a:colum) . ']'
  return l:temp
"}}}
endfunction

function! utility#StartLeaderfSelecting(content, callback_name) abort
"{{{
  try
    call leaderf_ECY#items_selecting#Start(a:content, a:callback_name)
  catch 
    call utility#ShowMsg("[ECY] You are missing 'Leaderf'. Please install it.", 2)
  endtry
"}}}
endfunction
