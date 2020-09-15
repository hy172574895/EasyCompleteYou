" Author: Jimmy Huang (1902161621@qq.com)
" License: WTFPL

fun! ECY#document_help#OnDocKey()
  call ECY_main#Do("OnDocumentHelp", v:true)
  return ''
endf

" this file namely hover.
function! ECY#document_help#Init() abort
"{{{
  let g:ECY_show_doc_key = get(g:,'ECY_show_doc_key', '<C-n>')
  let g:ECY_windows_are_showing['document_help'] = -1
  exe 'nmap ' . g:ECY_show_doc_key . ' :ECYDocHelp<CR>'
  exe 'inoremap <silent> ' . g:ECY_show_doc_key . ' <C-R>=ECY#document_help#OnDocKey()<CR>'
"}}}
endfunction

function! s:ClosePreviewWindows_buffer() abort
"{{{
  if g:ECY_windows_are_showing['document_help'] != -1
    exe ':bd!' . string(g:ECY_windows_are_showing['document_help'])
  endif
  let g:ECY_windows_are_showing['document_help'] = -1
"}}}
endfunction

function! s:ShowHlep_buffer(msg) abort
"{{{ only works on normal mode.
  let l:text = a:msg['Results'] " lists
  let l:text_len = len(l:text)
  let l:text = join(l:text, "\n") . "\n"
  call s:ClosePreviewWindows_buffer()
  silent! exe ':new ' . 'ECY-preview'
  silent! exe ':res '. l:text_len
  let l:current_windows = winnr('$')
  silent! put=l:text
  let g:ECY_windows_are_showing['document_help'] = bufnr()

  silent! exe string(l:current_windows).'wincmd w'
"}}}
endfunction

function! s:ShowHelp_vim(msg, file_type) abort
"{{{ floating windows
  let l:temp = g:ECY_windows_are_showing['document_help']
  if l:temp != -1
    call popup_close(l:temp)
  endif
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
  let g:ECY_windows_are_showing['document_help'] = l:nr
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
  if len(a:msg['Results']) == 0
    call ECY#utility#ShowMsg("[ECY] No document to show.", 2)
    return
  endif
  if g:has_floating_windows_support == 'vim'
    call s:ShowHelp_vim(a:msg, &filetype)
  else
    call s:ShowHlep_buffer(a:msg)
  endif
"}}}
endfunction
