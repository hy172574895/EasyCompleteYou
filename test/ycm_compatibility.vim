" can YCM work with ECY?


fun! ycm_compatibility#Test1()
  call test#Execute("new")
  if utility#HasYCM()
    call s:T1()
    return
  endif
  " user have no ycm, we test ECY at here
  let l:temp = ["i", 'abcdefghhhhhhhhhhh ',"hhhhhh", "\<Tab>", "\<ESC>"]
  call test#Input(l:temp, function('s:T2'))
endf

fun! s:T1()
  " switch to ycm and then test
  if ECY_main#GetCurrentUsingSourceName() != 'youcompleteme'
    let l:temp = ["\<Tab>",'j',"\<ESC>"]
    call test#Input(l:temp, function('s:T1'))
    return
  endif
  let l:temp = ["i", 'abcdefghhhhhhhhhhh ','hhhhhh', "\<Tab>", "\<ESC>"]
  call test#Input(l:temp, function('s:T3'))
  return
endf

fun! s:T2()
  let l:content = getbufline(bufnr(),1, "$")
  call test#Execute("q!")
  if l:content != ['abcdefghhhhhhhhhhh abcdefghhhhhhhhhhh']
    throw "erro"
  endif
  call test#TestOK('ycm_compatibility')
endf

fun! s:T3()
  let l:temp = ["\<Tab>",'j',"\<ESC>"]
  call test#Input(l:temp, function('s:T4'))
endf

fun! s:T4()
  let l:temp = ["o", "hhhhhh", "\<Tab>", "\<ESC>"]
  call test#Input(l:temp, function('s:T5'))
endf

fun! s:T5()
  let l:content = getbufline(bufnr(),1, "$")
  call test#Execute("q!")
  if l:content != ['abcdefghhhhhhhhhhh abcdefghhhhhhhhhhh', 'abcdefghhhhhhhhhhh']
    throw "erro"
  endif
  call test#TestOK('ycm_compatibility')
endf

call test#AddTestToQueue('ycm_compatibility', function('ycm_compatibility#Test1'))
