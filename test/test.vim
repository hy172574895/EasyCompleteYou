let s:is_input_working = v:false
let g:ECY_testing_case = []
let s:testing_case = 0

fun! test#Execute(key)
  exe a:key
endf

fun! s:Timer_cb(timer_id) abort
  let l:index = s:key_dict['current_key']
  if l:index == len(s:key_dict['key_list'])
    let s:is_input_working = v:false
    if exists("s:key_dict['callback']")
      let l:Fuc = s:key_dict['callback']
      call l:Fuc()
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
  let g:ECY_testing_case[s:testing_case]['status'] = 'ok'
  let s:testing_case += 1
  call test#Starting(s:testing_case)
endf

fun! test#AddTestToQueue(test_name, starting_fuc) abort
  let l:temp = {'name': a:test_name, 'starting_fuc': a:starting_fuc}
  call add(g:ECY_testing_case, l:temp)
endf


fun! test#Starting(index) abort
  if len(g:ECY_testing_case) == 0
    throw "Have no testing case."
  endif
  if a:index >= len(g:ECY_testing_case)
    " end
    echo "Testing Done."
    return
  endif
  try
    let l:Fuc = g:ECY_testing_case[a:index]['starting_fuc']
    call l:Fuc()
  catch 
    let g:ECY_testing_case[s:testing_case]['status'] = 'failed'
    let s:testing_case += 1
    call test#Starting(s:testing_case)
  endtry
endf
