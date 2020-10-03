""""""""""""""""""""""""""""""""""""""""""""
"  note!! this file conflict with lsp-vim  "
""""""""""""""""""""""""""""""""""""""""""""

let g:ECY_lsp_setting_dict = []
let g:ECY_lsp_setting_new_server = 0

fun! lsp#register_server(dicts) abort
  let l:dictss = a:dicts
  for [Key, Value] in items(a:dicts)
    if type(Value) == 2
      let l:dictss[Key] = Value(1)
    endif
  endfor
  call add(g:ECY_lsp_setting_dict , l:dictss)
  let g:ECY_lsp_setting_new_server = 1
endf

fun! lsp#GetDict() abort
  let g:ECY_lsp_setting_new_server = 0
  return g:ECY_lsp_setting_dict
endf

