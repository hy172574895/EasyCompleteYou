" Author: Jimmy Huang (1902161621@qq.com)
" License: WTFPL

function! ECY#utility#Init() abort
"{{{
  let s:show_msg_windows_nr = -1
  let s:show_msg_windows_text_list = []
  let s:show_msg_time = 5
  let s:show_msg_timer_id = -1
  let g:ECY_buffer_preview_windows_size = [[80, 120], [30, 40]]
  let g:ECY_buffer_preview_windows_nr = -1
  let g:ECY_windows_are_showing = {}
"}}}
endfunction

function! ECY#utility#MoveToBuffer(line, colum, file_path, windows_to_show) abort
"{{{ move cursor to windows, in normal mode
" a:colum is 0-based
" a:line is 1-based
" the a:windows_to_show hightly fit leaderf

  "TODO
  " if a:windows_to_show == 'preview' && g:ECY_leaderf_preview_mode != 'normal'
  "   if g:has_floating_windows_support == 'vim'
  "     call s:ShowPreview_vim(a:file_path, a:line, &syntax)
  "   endif
  "   return
  " endif

  if a:windows_to_show == 'h'
    exe 'new ' . a:file_path
    " horizontally new a windows at current tag
  elseif a:windows_to_show == 'v'
    " vertically new a windows at current tag
    exe 'vnew ' . a:file_path
  elseif a:windows_to_show == 't'
    " new a windows and new a tab
    exe 'tabedit '
    silent exe "hide edit " .  a:file_path
  elseif a:windows_to_show == 'to'
    " new a windows and a tab that can be a previous old one.
    silent exe 'tabedit ' . a:file_path
  else
    " use current buffer's windows to open that buffer if current buffer is
    " not that buffer, and if current buffer is that buffer, it will fit
    " perfectly.
    if ECY#utility#GetCurrentBufferPath() != a:file_path
      silent exe "hide edit " .  a:file_path
    endif
  endif
  call cursor(a:line, a:colum + 1)
"}}}
endfunction

function! ECY#utility#IsFileLoaded(file_name) abort
  return bufnr(a:file_name)
endfunction

function! ECY#utility#has_key(dicts, key) abort
  if !has_key(a:dicts , a:key)
    return ''
  endif
  return a:dicts[a:key]
endfunction

function! ECY#utility#CheckCurrentCapabilities(capability) abort
"{{{
  try
    let l:engine_name = ECY_main#GetCurrentUsingSourceName()
    let l:capabilities = g:ECY_all_engine_info[l:engine_name]['capabilities']
    return ECY#utility#IsInList(a:capability, l:capabilities)
  catch 
    return v:false
  endtry
"}}}
endfunction

function! ECY#utility#ParseCMD(variable) abort
"{{{
  let l:types = type(a:variable)
  if l:types == 1
    " string
    return split(a:variable, " ")
  elseif l:types == 3
    " lists
    return a:variable
  else
    throw "[ECY] invalid command."
  endif
"}}}
endfunction

function! ECY#utility#CMDRunable(cmd, ...) abort
"{{{
  let l:lists = ECY#utility#ParseCMD(a:cmd)
  if len(l:lists) == 0
    throw '[ECY] invalid command.  ' . string(a:cmd)
  endif
  if executable(l:lists[0])
    return v:true
  endif
  if a:0 != 0
    throw '[ECY] invalid command.  ' . string(l:lists[0])
  endif
  return v:false
"}}}
endfunction

function! s:ShowPreview_vim(file_name, roll_line, syntaxs) abort
"{{{
  let l:bufnr = ECY#utility#IsFileLoaded(a:file_name)
  let s:preview_cache = []
  if l:bufnr == -1
    let s:preview_cache = readfile(a:file_name)
  else
    let s:preview_cache = getbufline(l:bufnr, 1, "$")
  endif
  let l:opts = {
      \ 'minwidth': g:ECY_buffer_preview_windows_size[0][0],
      \ 'maxwidth': g:ECY_buffer_preview_windows_size[0][1],
      \ 'minheight': g:ECY_buffer_preview_windows_size[1][0],
      \ 'maxheight': g:ECY_buffer_preview_windows_size[1][1],
      \ 'border': [],
      \ 'close': 'click',
      \ 'scrollbar': 1,
      \ 'firstline': a:roll_line,
      \ 'padding': [0,1,0,1],
      \ 'zindex': 2000}
  let g:ECY_buffer_preview_windows_nr = popup_create(s:preview_cache, l:opts)
"}}}
endfunction

function! ECY#utility#GetLoadedFile() abort
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

function! ECY#utility#OpenECYLogFile() abort
"{{{
  let l:server_log_file_path = g:ECY_python_script_folder_path . '/server/ECY_server.log'
  let l:client_log_file_path = g:ECY_python_script_folder_path . '/client/ECY_client.log'
  execute 'new '. l:server_log_file_path
  execute 'new '. l:client_log_file_path
"}}}
endfunction

function! ECY#utility#GetCurrentBufferPath(...) abort
"{{{
  " let l:full_path = fnamemodify(@%, ':p')
  let l:full_path = expand('%:p')
  return l:full_path

"}}}
endfunction

function! ECY#utility#SendKeys(keys) abort
"{{{
  call feedkeys( a:keys, 'in' )
"}}}
endfunction

function! ECY#utility#HasYCM() abort
"{{{
  if exists('g:loaded_youcompleteme')
    if g:loaded_youcompleteme == 1
      return v:true
    endif
  endif
  return v:false
"}}}
endfunction

function! ECY#utility#IsCurrentBufferBigFile()
"{{{ we use same variable as YCM's one
  if exists( 'b:ycm_largefile' )
    return b:ycm_largefile
  endif
  let threshold = g:ECY_disable_for_files_larger_than_kb * 1024
  let b:ycm_largefile =
        \ threshold > 0 && getfsize(expand('%')) > threshold
  if b:ycm_largefile
    " only echo once because this will only check once
    call ECY#utility#ShowMsg("ECY unavailable: the file exceeded the max size.", 2)
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

function! ECY#utility#ShowMsg(msg, style) abort
"{{{
  " if a:style == 1 means short
  " a:style == 2 warning with no redraw
  " a:style == 3 erro with redraw
  " a:style == 4 warning with redraw
  if g:loaded_easycomplete && g:has_floating_windows_support == 'vim'
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
      let s:show_msg_windows_text_list = []
    else
      call add(s:show_msg_windows_text_list, '--------------------')
    endif
    if type(a:msg) == 3
      " == list
      call extend(s:show_msg_windows_text_list, a:msg)
    else
      call add(s:show_msg_windows_text_list, a:msg)
    endif
    if s:show_msg_windows_nr == -1
      let s:show_msg_windows_nr = popup_create(s:show_msg_windows_text_list, l:opts)
    else
      " delay, have new msg.
      call popup_settext(s:show_msg_windows_nr, s:show_msg_windows_text_list)
    endif
    let s:show_msg_timer_id = timer_start(1000, function('g:ShowMsg_timer'))
  elseif g:loaded_easycomplete && g:has_floating_windows_support == 'has_no' 
    if type(a:msg) == 3
      let l:temp = join(a:msg, '|')
    else
      let l:temp = a:msg
    endif
    echohl WarningMsg |
          \ echomsg l:temp |
          \ echohl None
  endif
"}}}
endfunction

function! ECY#utility#IsInList(item, list) abort
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

function! ECY#utility#FormatPosition(line, colum) abort
"{{{ return such as "[34, 35]"
  let l:temp = '[' . string(a:line). ', ' . string(a:colum) . ']'
  return l:temp
"}}}
endfunction

function! ECY#utility#StartLeaderfSelecting(content, callback_name) abort
"{{{
  try
    call leaderf_ECY#items_selecting#Start(a:content, a:callback_name)
  catch 
    call ECY#utility#ShowMsg("[ECY] You are missing 'Leaderf' or its version is too low. Please install/update it.", 2)
  endtry
"}}}
endfunction

function! ECY#utility#SaveIndent() abort
"{{{
  if !exists('b:indentexpr_temp')
    let b:indentexpr_temp = &indentexpr
  endif
"}}}
endfunction

function! ECY#utility#DisableIndent() abort
"{{{ DisableIndent temporally.
  call ECY#utility#SaveIndent()
  let &indentexpr = ''
"}}}
endfunction

function! ECY#utility#RecoverIndent() abort
"{{{
  if exists('b:indentexpr_temp')
    let &indentexpr = b:indentexpr_temp
  endif
"}}}
endfunction

function! ECY#utility#RollFloatingWindows(up_or_down) abort
"{{{ a:up_or_down = -1 = up; a:up_or_down = 1 = down
"this function will be mapped, so we should return ''
  if g:has_floating_windows_support == 'vim'
    for [key, value] in items(g:ECY_windows_are_showing)
      if value != -1
        try
          let l:opts = popup_getoptions(value)
          if has_key(l:opts, 'firstline')
            let l:current_first_line = l:opts['firstline']
            let l:next_line = l:current_first_line + a:up_or_down
            call popup_setoptions(value, {'firstline': l:next_line})
          endif
        " catch
        endtry
      endif
    endfor
  endif
  return ''
"}}}
endfunction
