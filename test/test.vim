
fun! test#Init()
  let s:is_input_working = v:false
  let g:ECY_testing_case = []
  let s:testing_case_nr = 0
  let s:testing_windows_nr = -1
endf

fun! test#Execute(key)
  exe a:key
endf

fun! s:Timer_cb(timer_id) abort
  let l:index = s:key_dict['current_key']
  if l:index == len(s:key_dict['key_list'])
    let s:is_input_working = v:false
    if exists("s:key_dict['callback']")
      call s:Processor(s:key_dict['callback'])
    endif
    return
  endif
  call feedkeys(s:key_dict['key_list'][l:index], 'i')
  let s:key_dict['current_key'] += 1
  call timer_start(500, function('s:Timer_cb'))
endf

fun! test#Input(key, ...) abort
  if s:is_input_working != v:false
    throw "You must call Input after last input is done. This test is finished."
  endif
  let s:key_dict = {'current_key': 0, 'key_list': a:key}
  if a:0 != 0
    let s:key_dict['callback'] = a:000[0]
  endif
  call s:Timer_cb(1)
  let s:is_input_working = v:true
endf

fun! test#TestOK(test_name) abort
  let g:ECY_testing_case[s:testing_case_nr]['status'] = 'ok'
  let s:testing_case_nr += 1
  call test#Starting(s:testing_case_nr)
endf

fun! test#AddTestToQueue(test_name, starting_fuc) abort
  let l:temp = {'name': a:test_name, 'starting_fuc': a:starting_fuc}
  call add(g:ECY_testing_case, l:temp)
endf


fun! test#Starting(index) abort
  if s:testing_windows_nr != -1
    call test#Execute("bd! ". string(s:testing_windows_nr))
    let s:testing_windows_nr = -1
  endif
  if len(g:ECY_testing_case) == 0
    throw "Have no testing case."
  endif
  if a:index >= len(g:ECY_testing_case)
    " end
    echo "Testing Done."
    return
  endif
  call test#Execute("new")
  let s:testing_windows_nr = bufnr()
  call s:Processor(g:ECY_testing_case[a:index]['starting_fuc'])
endf

fun! s:Processor(Fuc) abort

  if s:testing_case_nr >= len(g:ECY_testing_case)
    " end
    echo "Testing Done."
    return
  endif
  try
    call a:Fuc()
  catch 
    let g:ECY_testing_case[s:testing_case_nr]['status'] = 'failed'
    let g:ECY_testing_case[s:testing_case_nr]['info'] = v:exception
    let g:ECY_testing_case[s:testing_case_nr]['point'] = v:throwpoint
    let s:testing_case_nr += 1
    call test#Starting(s:testing_case_nr)
  endtry
endf

call test#Init()
