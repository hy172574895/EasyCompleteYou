let s:loop_times = -1
let s:name = "can ECY works with snippets?"

fun! snippets#Test1()
  let &filetype = 'html'
  if g:has_ultisnips_support
    call s:T1()
    return
  endif
  for item in g:ECY_file_type_info['nothing']['available_sources']
    if item == 'snippets'
      throw "g:has_ultisnips_support have no snippets, but in engien list."
    endif
  endfor
endf

fun! s:T1()
  " switch to ycm and then test
  if ECY_main#GetCurrentUsingSourceName() != 'snippets'
    if s:loop_times == 20
      throw "Have no snippets support. but user have snippets engine."
    endif
    let l:temp = ["\<Tab>",'j',"\<ESC>"]
    call test#Input(l:temp, function('s:T1'))
    let s:loop_times += 1
    return
  endif
  let l:temp = ["i", 'return', "\<Tab>", "\<CR>", "\<ESC>"]
  call test#Input(l:temp, function('s:T2'))
  return
endf

fun! s:T2()
  let l:content = getbufline(bufnr(),1, "$")
  if l:content != ['&#x21A9;']
    throw "erro"
  endif
  call test#TestOK(s:name)
endf

call test#AddTestToQueue(s:name, function('snippets#Test1'))
