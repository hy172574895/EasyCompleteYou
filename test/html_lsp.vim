let s:loop_times = -1
let s:name = "can html_lsp works?"

fun! s:Html_lsp()
  let &filetype = 'html'
  call s:T1()
endf

fun! s:T1()
  " switch to ycm and then test
  if ECY_main#GetCurrentUsingSourceName() != 'html_lsp'
    if s:loop_times == 20
      throw "Have no html_lsp support. but user have html_lsp engine."
    endif
    let l:temp = ["\<Tab>",'j',"\<ESC>"]
    call test#Input(l:temp, function('s:T1'))
    let s:loop_times += 1
    return
  endif
  let l:temp = ["i", '<html']
  call test#Input(l:temp, function('s:T2'))
  return
endf

fun! s:T2()
  let l:compare = [{'word': 'html', 'menu': '', 'user_data': '0', 'match_point': [0, 1, 2, 3], 'info': ['The html element represents the root of an HTML document.'], 'kind': 'Property', 'abbr': 'html  '}]
  if g:ECY_current_popup_windows_info['items_info'] != l:compare
    throw "erro"
  endif
  call test#TestOK(s:name)
endf

call test#AddTestToQueue(s:name, function('s:Html_lsp'))
