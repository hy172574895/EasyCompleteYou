" can YCM work with ECY?

let s:loop_times = -1
let s:name = "can YCM works with ECY?"

fun! ycm_compatibility#Test1()
  if utility#HasYCM()
    call s:T1()
    return
  endif
  call s:T11()
endf

fun! s:T11()
  " user have no ycm, we test ECY at here
  " switch to ycm and then test
  if ECY_main#GetCurrentUsingSourceName() != 'label'
    if s:loop_times == 20
      throw "Have no youcompleteme support."
    endif
    let l:temp = ["\<Tab>",'j',"\<ESC>"]
    call test#Input(l:temp, function('s:T11'))
    let s:loop_times += 1
    return
  endif
  let l:temp = ["i", 'abcdefghhhhhhhhhhh ',"hhhhhh", "\<Tab>", "\<ESC>"]
  call test#Input(l:temp, function('s:T2'))
  return
endf

fun! s:T1()
  " switch to ycm and then test
  if ECY_main#GetCurrentUsingSourceName() != 'youcompleteme'
    if s:loop_times == 20
      throw "Have no youcompleteme support."
    endif
    let l:temp = ["\<Tab>",'j',"\<ESC>"]
    call test#Input(l:temp, function('s:T1'))
    let s:loop_times += 1
    return
  endif
  let l:temp = ["i", 'abcdefghhhhhhhhhhh ','hhhhhh', "\<Tab>", "\<ESC>"]
  call test#Input(l:temp, function('s:T3'))
  return
endf

fun! s:T2()
  let l:content = getbufline(bufnr(),1, "$")
  if l:content != ['abcdefghhhhhhhhhhh abcdefghhhhhhhhhhh']
    throw "erro"
  endif
  call test#TestOK(s:name)
endf

fun! s:T3()
  if ECY_main#IsECYWorksAtCurrentBuffer()
    throw "YCM show work right now."
  endif
  let l:temp = ["\<Tab>",'j',"\<ESC>"]
  call test#Input(l:temp, function('s:T4'))
endf

fun! s:T4()
  if !ECY_main#IsECYWorksAtCurrentBuffer()
    throw "ECY show work right now."
  endif
  let l:temp = ["o", "hhhhhh", "\<Tab>", "\<ESC>"]
  call test#Input(l:temp, function('s:T5'))
endf

fun! s:T5()
  let l:content = getbufline(bufnr(),1, "$")
  if l:content != ['abcdefghhhhhhhhhhh abcdefghhhhhhhhhhh', 'abcdefghhhhhhhhhhh']
    throw "erro"
  endif
  call test#TestOK(s:name)
endf

call test#AddTestToQueue(s:name, function('ycm_compatibility#Test1'))
