function! s:Integration(timer_id) abort
  " we put this at here to accelarate the starting time
  try
    call UltiSnips#SnippetsInCurrentScope(1)
    let g:has_ultisnips_support = v:true
    call ECY_main#Log('has UltiSnips')
  catch
    let g:has_ultisnips_support = v:false
    call ECY_main#Log('has no UltiSnips')
  endtry

  " if g:has_ultisnips_support
  " " UltiSnips' API must be called in <C-R>
  "   exe 'inoremap <silent> ' . g:ECY_expand_snippets_key.
  "       \ ' <C-R>=ECY_main#ExpandSnippet()<cr>'
  "   " imap <CR>  <C-R>=ECY_main#ExpandSnippet()<CR>
  "   exe 'let g:ECY_expand_snippets_key = "\'.g:ECY_expand_snippets_key.'"'
  " endif
endfunction

if g:loaded_easycomplete
  call timer_start(2000, function('s:Integration'))  
  exe 'inoremap <silent> ' . g:ECY_expand_snippets_key.
      \ ' <C-R>=ECY_main#ExpandSnippet()<cr>'
  " imap <CR>  <C-R>=ECY_main#ExpandSnippet()<CR>
  exe 'let g:ECY_expand_snippets_key = "\'.g:ECY_expand_snippets_key.'"'
endif
