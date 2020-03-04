function! ECY#document_help#Init() abort
"{{{
"}}}
endfunction

function! s:ShowHelp_new_windows(msg) abort
"{{{
  
"}}}
endfunction

function! s:ShowHelp_vim(msg, file_type) abort
"{{{
  let l:text = a:msg['Results']
  let l:opts = {
      \ 'minwidth': g:ECY_preview_windows_size[0][0],
      \ 'maxwidth': g:ECY_preview_windows_size[0][1],
      \ 'minheight': g:ECY_preview_windows_size[1][0],
      \ 'maxheight': g:ECY_preview_windows_size[1][1],
      \ 'border': [],
      \ 'close': 'click',
      \ 'scrollbar': 1,
      \ 'firstline': 1,
      \ 'padding': [0,1,0,1],
      \ 'zindex': 2000}
  let l:nr = popup_atcursor(l:text, l:opts)
  call setbufvar(winbufnr(l:nr), '&syntax', a:file_type)
"}}}
endfunction

function! s:ShowHelp_nvim(msg) abort
"{{{
 " TODO
"}}}
endfunction

function! ECY#document_help#cb(msg) abort
"{{{
  if g:has_floating_windows_support == 'vim'  
    call s:ShowHelp_vim(a:msg, &filetype)
  else
    call s:ShowHelp_new_windows(a:msg)
  endif
"}}}
endfunction
