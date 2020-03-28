" Author: Jimmy Huang (1902161621@qq.com)
" License: WTFPL

" this file namely hover.
function! ECY#document_help#Init() abort
"{{{
  let g:ECY_show_doc_key = get(g:,'ECY_show_doc_key', '<C-n>')
  let s:preview_windows_nr = -1
  exe 'nmap ' . g:ECY_show_doc_key . ' :ECYDocHelp<CR>'
"}}}
endfunction

function! s:Close_preview_windows() abort
"{{{
  if s:preview_windows_nr != -1
    exe ':bd!' . string(s:preview_windows_nr)
  endif
  let s:preview_windows_nr = -1
"}}}
endfunction

function! s:ShowHelp_new_windows(msg) abort
"{{{ only works on normal mode.
  let l:text = a:msg['Results'] " lists
  let l:text_len = len(l:text)
  let l:text = join(l:text, "\n") . "\n"
  call s:Close_preview_windows()
  silent! exe ':new ' . 'ECY-preview'
  silent! exe ':res '. l:text_len
  let l:current_windows = winnr('$')
  silent! put=l:text
  let s:preview_windows_nr = bufnr()

  silent! exe string(l:current_windows).'wincmd w'
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
