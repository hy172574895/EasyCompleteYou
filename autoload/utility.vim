
function! utility#MoveToBuffer(line, colum, buffer_name, windows_to_show) abort
"{{{ move cursor to windows
" a:colum is 0-based
" a:line is 1-based
  if a:windows_to_show == 'h'
    exe 'new ' . a:buffer_name
    " horizontally new a windows at current tag
  elseif a:windows_to_show == 'v'
    " vertically new a windows at current tag
    exe 'vnew ' . a:buffer_name
  elseif a:windows_to_show == 'tn'
    " new a windows and new a tab
    exe 'tabedit '
    exe "hide edit " .  a:buffer_name
  elseif a:windows_to_show == 'to'
    " new a windows and a tab that can be a previous old one.
    exe 'tabedit ' . a:buffer_name
  else
    " use current buffer's windows to open that buffer if current buffer is
    " not that buffer, and if current buffer is that buffer, it will fit
    " perfectly.
    if utility#GetCurrentBufferPath() != a:buffer_name
      exe "hide edit " .  a:buffer_name
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

function! utility#GetCurrentBufferPath() abort
"{{{
  " let l:temp = "ECY_Client_.GetCurrentBufferPath()"
  " return s:PythonEval(l:temp)
  let l:file = @%
  if l:file =~# '^\a\a\+:' || a:0 > 1
    return call('Current_buffer_path', [l:file] + a:000[1:-1])
  elseif l:file =~# '^/\|^\a:\|^$'
    return l:file
  else
    let l:full_path = fnamemodify(l:file, ':p' . (l:file =~# '[\/]$' ? '' : ':s?[\/]$??'))
    return l:full_path
  endif
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

function! utility#ShowMsg(msg, style) abort
"{{{
  " if a:style == 1 means erro with no redraw
  " a:style == 2 warning with no redraw
  " a:style == 3 erro with redraw
  " a:style == 4 warning with redraw
    if a:style == 3 || a:style == 4
      redraw!
    endif
    if a:style == 2 || a:style == 4
      echohl WarningMsg |
            \ echomsg a:msg |
            \ echohl None
    endif
"}}}
endfunction
