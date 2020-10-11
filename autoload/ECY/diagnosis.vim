" Author: Jimmy Huang (1902161621@qq.com)
" License: WTFPL
 
function ECY#diagnosis#Init() abort
"{{{ var init
  let g:ECY_enable_diagnosis
        \= get(g:,'ECY_enable_diagnosis', v:true)
  if !g:ECY_enable_diagnosis
    return
  endif

  hi ECY_diagnosis_highlight  term=undercurl gui=undercurl guisp=DarkRed cterm=underline
  let g:ECY_diagnosis_highlight = get(g:,'ECY_diagnosis_highlight','ECY_diagnosis_highlight')

  hi ECY_erro_sign_highlight  guifg=red	    ctermfg=red	
  hi ECY_warn_sign_highlight  guifg=yellow	ctermfg=yellow
  let g:ECY_erro_sign_highlight = get(g:,'ECY_erro_sign_highlight', 'ECY_erro_sign_highlight')
  let g:ECY_warn_sign_highlight = get(g:,'ECY_warn_sign_highlight', 'ECY_warn_sign_highlight')

  " 1 means ask diagnosis when there are changes not including user in insert mode, trigger by DoCompletion()
  " 2 means ask diagnosis when there are changes including user in insert mode, trigger by OnBufferTextChanged().
  let g:ECY_update_diagnosis_mode
        \= get(g:,'ECY_update_diagnosis_mode', 1)
  if g:ECY_update_diagnosis_mode == 2
    let g:ECY_update_diagnosis_mode = v:true
  else
    let g:ECY_update_diagnosis_mode = v:false
  endif

  " can not use sign_define()
  silent! execute 'sign define ECY_diagnosis_erro text=>> texthl=' . g:ECY_erro_sign_highlight
  silent! execute 'sign define ECY_diagnosis_warn text=!! texthl=' . g:ECY_warn_sign_highlight

  " call sign_define("ECY_diagnosis_erro", {
  "   \ "text" : ">>",
  "   \ "texthl" : g:ECY_erro_sign_highlight})
  " call sign_define("ECY_diagnosis_warn", {
  "   \ "text" : "!!",
  "   \ "texthl" : g:ECY_warn_sign_highlight})

  let s:supports_sign_groups = has('nvim-0.4.2') || exists('*sign_define')
  let s:supports_sign_groups = v:false
  let s:sign_id_dict                         = {}
  let s:current_diagnosis                    = {}
  let g:ECY_windows_are_showing['diagnosis'] = -1
  let g:ECY_diagnosis_items_all              = []
  let g:ECY_diagnosis_items_with_engine_name = {'nothing': []}
  " user don't want to update diagnosis in insert mode, but engine had
  " returned diagnosis, so we cache it and update after user leave insert
  " mode.
  let s:need_to_update_diagnosis_after_user_leave_insert_mode = v:false


  call s:SetUpEvent()
  call s:SetUpPython()

  let g:ECY_key_to_show_current_line_diagnosis = get(g:,'ECY_key_to_show_current_line_diagnosis', 'H')
  let g:ECY_key_to_show_next_diagnosis = get(g:,'ECY_key_to_show_next_diagnosis', '[j')
  exe 'nmap ' . g:ECY_key_to_show_current_line_diagnosis . ' :call ECY#diagnosis#ShowCurrentLineDiagnosis(v:false)<CR>'
  exe 'nmap ' . g:ECY_key_to_show_next_diagnosis . ' :call ECY#diagnosis#ShowNextDiagnosis(1)<CR>'
"}}}
endfunction

function s:SetUpEvent() abort
  augroup EasyCompleteYou_Diagnosis
    autocmd CursorHold * call s:OnCursorHold()
  augroup END
endfunction

function s:SetUpPython() abort
"{{{
python3 <<endpython
import vim

def CalculateScreenSign(start, end):
  engine_name = vim.eval('ECY_main#GetCurrentUsingSourceName()')
  lists = "g:ECY_diagnosis_items_with_engine_name['" + engine_name + "']"
  lists = vim.eval(lists)
  file_path = vim.eval('ECY#utility#GetCurrentBufferPath()')
  results = []
  for item in lists:
    line = int(item['position']['line'])
    if item['file_path'] == file_path:
      if start <= line and end >= line:
        results.append(item)
  return results
endpython
"}}}
endfunction

function s:OnCursorHold() abort
  if g:ECY_windows_are_showing['diagnosis'] == -1
    call ECY#diagnosis#ShowCurrentLineDiagnosis(v:true)
  endif
endfunction

function! ECY#diagnosis#ShowCurrentLineDiagnosis(is_triggered_by_event) abort
"{{{ show diagnosis msg in normal mode.
  if !g:ECY_enable_diagnosis || mode() != 'n'
    if !a:is_triggered_by_event
      call ECY#utility#ShowMsg("[ECY] Diagnosis had been turn off.", 2)
    endif
    return ''
  endif
  let l:current_line_nr     = line('.')
  let l:current_col_nr      = col('.')
  let l:current_buffer_path = ECY#utility#GetCurrentBufferPath()
  call ECY#diagnosis#Show(l:current_buffer_path, l:current_line_nr,
        \l:current_col_nr, a:is_triggered_by_event)
  
  return '' " we should return ''
"}}}
endfunction

function! ECY#diagnosis#CurrentBufferErrorAndWarningCounts() abort
  let l:current_engine = ECY_main#GetCurrentUsingSourceName()
  if !has_key(g:ECY_diagnosis_items_with_engine_name, l:current_engine)
    return 0
  endif
  return len(g:ECY_diagnosis_items_with_engine_name[l:current_engine])
endfunction

function! ECY#diagnosis#Show(file_path, line, colum, is_triggered_by_event) abort
"{{{ show a popup windows and move to that position.
  if g:ECY_diagnosis_items_all == []
    call s:InitDiagnosisLists()
  endif

  let l:index_list = []
  let l:index = -1
  for item in g:ECY_diagnosis_items_all
    if a:file_path != item['file_path'] || a:line != item['position']['line']
      continue
    endif
    let l:index = item['index']
    call add(l:index_list, item)
  endfor

  if len(l:index_list) == 0
    if !a:is_triggered_by_event
      call ECY#utility#ShowMsg("[ECY] Diagnosis has nothing to show at current buffer line.", 2)
    endif
    return
  endif

  let s:current_diagnosis              = {}
  let s:current_diagnosis['file_path'] = a:file_path
  let s:current_diagnosis['line']      = a:line
  let s:current_diagnosis['colum']     = a:colum
  let s:current_diagnosis['index']     = l:index

  call ECY#utility#MoveToBuffer(a:line, a:colum, a:file_path, 'current buffer')

  if g:has_floating_windows_support == 'vim'
    call s:ShowDiagnosis_vim(l:index_list)
  elseif g:has_floating_windows_support == 'nvim'
    " TODO
  else
    call s:ShowDiagnosis_all(l:index_list)
  endif
"}}}
endfunction

function! ECY#diagnosis#ShowNextDiagnosis(next_or_pre) abort
"{{{ show diagnosis msg in normal mode at current buffer. 
  let l:items_len = len(g:ECY_diagnosis_items_all)
  if l:items_len == 0
    call s:InitDiagnosisLists()
    let l:items_len = len(g:ECY_diagnosis_items_all)
    if l:items_len == 0
      call ECY#utility#ShowMsg("[ECY] Diagnosis has nothing to show at current buffer line.", 2)
      return ''
    endif
  endif

  let l:file_path = ECY#utility#GetCurrentBufferPath()

  if s:current_diagnosis != {}
    let l:index = (s:current_diagnosis['index'] + a:next_or_pre) % l:items_len
    try
      let item = g:ECY_diagnosis_items_all[l:index]
      let l:file_path = item['file_path']
      let l:line = item['position']['line']
      let l:colum = item['position']['range']['start']['colum']
    catch 
      let s:current_diagnosis = {}
    endtry
  endif

  if s:current_diagnosis == {}
    for item in g:ECY_diagnosis_items_all
      if l:file_path == item['file_path']
        let l:line = item['position']['line']
        let l:colum = item['position']['range']['start']['colum']
        break
      endif
    endfor
    if !exists('l:line')
      call ECY#utility#ShowMsg("[ECY] Diagnosis has nothing to show at current buffer line.", 2)
      return ''
    endif
  endif

  call ECY#diagnosis#Show(l:file_path, l:line, l:colum, v:true)
  return ''
"}}}
endfunction

function! g:Diagnosis_vim_cb(id, key) abort
  let g:ECY_windows_are_showing['diagnosis'] = -1
endfunction

function! s:CloseDiagnosisPopupWindows() abort
"{{{
  if g:ECY_windows_are_showing['diagnosis'] != -1
    if g:has_floating_windows_support == 'vim'
      call popup_close(g:ECY_windows_are_showing['diagnosis'])
      let g:ECY_windows_are_showing['diagnosis'] = -1
    endif
  endif
"}}}
endfunction

function! s:ShowDiagnosis_vim(index_list) abort
"{{{ 
  call s:CloseDiagnosisPopupWindows()
  let l:text = []
  for item in a:index_list
    if len(l:text) != 0
      call add(l:text, '----------------------------')
    endif
    let l:line = string(item['position']['line'])
    let l:colum = string(item['position']['range']['start']['colum'])
    let l:index = string(s:current_diagnosis['index'] + 1)
    let l:lists_len = string(len(g:ECY_diagnosis_items_all))
    let l:nr = "(" . l:index . '/' . l:lists_len . ')'
    if item['kind'] == 1
      let l:style = 'ECY_diagnosis_erro'
    else
      let l:style = 'ECY_diagnosis_warn'
    endif
    call add(l:text, l:style . ' [' .l:line . ', ' . l:colum . '] ' . l:nr)
    let l:temp = item['diagnosis']
    if type(l:temp) == 1
      " strings
      call add(l:text, '(' . l:temp . ')')
    elseif type(l:temp) == 3
      " lists
      let l:temp[0] = '(' . l:temp[0]
      let l:temp[len(l:temp) - 1] .= ')'
      call extend(l:text, l:temp)
    endif
  endfor
  if g:ECY_PreviewWindows_style == 'append'
    " show a popup windows aside current cursor.
    let l:opts = {
        \ 'minwidth': g:ECY_preview_windows_size[0][0],
        \ 'maxwidth': g:ECY_preview_windows_size[0][1],
        \ 'minheight': g:ECY_preview_windows_size[1][0],
        \ 'maxheight': g:ECY_preview_windows_size[1][1],
        \ 'border': [],
        \ 'close': 'click',
        \ 'callback': 'g:Diagnosis_vim_cb',
        \ 'scrollbar': 1,
        \ 'firstline': 1,
        \ 'padding': [0,1,0,1],
        \ 'zindex': 2000}
    let l:nr = popup_atcursor(l:text, l:opts)
    call setbufvar(winbufnr(l:nr), '&syntax', 'ECY_d')
    " call win_execute(l:nr, l:exe)
    let g:ECY_windows_are_showing['diagnosis'] = l:nr
  endif
"}}}
endfunction

function! s:ShowDiagnosis_all(index_list) abort
"{{{ 
  let l:temp = '[ECY] '
  let i = 0
  for item in a:index_list
    let l:temp .= item['diagnosis']
    if i != 0
      let l:temp .= '|'
    endif
    let i += 1
  endfor
  call ECY#utility#ShowMsg(l:temp, 2)
"}}}
endfunction

function! s:CalculatePosition(line, col, end_line, end_col) abort
"{{{
  " this was copy from ALE
    let l:MAX_POS_VALUES = 8
    let l:MAX_COL_SIZE = 1073741824 " pow(2, 30)
    if a:line >= a:end_line
        " For single lines, just return the one position.
        return [[[a:line, a:col, a:end_col - a:col + 1]]]
    endif

    " Get positions from the first line at the first column, up to a large
    " integer for highlighting up to the end of the line, followed by
    " the lines in-between, for highlighting entire lines, and
    " a highlight for the last line, up to the end column.
    let l:all_positions =
    \   [[a:line, a:col, l:MAX_COL_SIZE]]
    \   + range(a:line + 1, a:end_line - 1)
    \   + [[a:end_line, 1, a:end_col]]

    return map(
    \   range(0, len(l:all_positions) - 1, l:MAX_POS_VALUES),
    \   'l:all_positions[v:val : v:val + l:MAX_POS_VALUES - 1]',
    \)
"}}}
endfunction

function! s:HighlightRange(range, highlights) abort
"{{{ return a list of `matchaddpos` e.g. [match_point1, match_point2]
"a:range = {'start': { 'line': 5, 'colum': 23 },'end' : { 'line': 6, 'colum': 0 } }
"
"colum is 0-based, but highlight's colum is 1-based, so we add 1.
"ensure cursor in buffer you want to highlight before you call this function.

  " map like a loop
  call map(s:CalculatePosition(a:range['start']['line'],
          \a:range['start']['colum'] + 1,
          \a:range['end']['line'],
          \a:range['end']['colum'] + 1),
        \'matchaddpos(a:highlights, v:val)')
"}}}
endfunction

function! ECY#diagnosis#CleanAllSignHighlight() abort
"{{{ should be called after text had been changed.
  if !g:ECY_enable_diagnosis
    return
  endif
  for l:match in getmatches()
      if l:match['group'] =~# '^ECY_diagnosis'
          call matchdelete(l:match['id'])
      endif
  endfor
"}}}
endfunction

function! s:PlaceSignAndHighlight(position, diagnosis, items, style, path,
      \engine_name, current_buffer_path) abort
"{{{ place a sign in current buffer.
  " a:position = {'line': 10, 'range': {'start': { 'line': 5, 'colum': 23 },'end' : { 'line': 6, 'colum': 0 } }}
  " a:diagnosis = {'item':{'1':'asdf', '2':'sdf'}}
  if a:style == 1
    let l:style = 'ECY_diagnosis_erro'
  else
    let l:style = 'ECY_diagnosis_warn'
  endif
  let l:group_name = a:engine_name
  try
    call s:PlaceSign(a:engine_name, l:style, a:path, a:position['line'])
    " call sign_place(0,
    "        \l:group_name,
    "        \l:style, a:path,
    "        \{'lnum' : a:position['line']})
  catch 
  endtry
  if a:current_buffer_path == a:path
    call s:HighlightRange(a:position['range'], 'ECY_diagnosis_highlight')
  endif
"}}}
endfunction

function! s:PlaceSign(engine_name, style, path, line) abort
"{{{
  
  if s:supports_sign_groups
    let l:temp = 'sign place 454 line='.a:line.' group='.a:engine_name.' name='.a:style.' file='.a:path
  else
    let l:increment_id = s:sign_id_dict[a:engine_name]['increment_id'] + 1
    let s:sign_id_dict[a:engine_name]['increment_id'] = l:increment_id
    " l:increment_id will not exceed 45481. so we don't need to consider that id
    " will be invalid. why 454? it doesn't matter, and just a number.
    let l:increment_id = '454'.string(s:sign_id_dict[a:engine_name]['name_id'] ) . string(l:increment_id)
    call add(s:sign_id_dict[a:engine_name]['id_lists'] , {'sign_id': l:increment_id, 'file_path': a:path})
    let l:temp = 'sign place '.l:increment_id.' line='.a:line.' name='.a:style.' file='.a:path
  endif
  silent! execute l:temp
"}}}
endfunction

function! s:UnplaceAllSignByEngineName(engine_name) abort
"{{{
  if s:supports_sign_groups
    silent! execute 'sign unplace * group=' . a:engine_name
  else
    if !exists('s:sign_id_dict[a:engine_name]')
      let s:sign_id_dict[a:engine_name] = {'id_lists': [], 
            \'name_id': len(g:ECY_diagnosis_items_with_engine_name),
            \'increment_id': 1}
    endif
    for item in s:sign_id_dict[a:engine_name]['id_lists']
      silent! execute 'sign unplace '.item['sign_id'].' file=' . item['file_path']
    endfor
    let s:sign_id_dict[a:engine_name]['id_lists']     = []
    let s:sign_id_dict[a:engine_name]['increment_id'] = 1
  endif
"}}}
endfunction

function! ECY#diagnosis#OnInsertModeLeave() abort
"{{{ show all.
  if !g:ECY_enable_diagnosis
    return
  endif
  if s:need_to_update_diagnosis_after_user_leave_insert_mode
    let s:need_to_update_diagnosis_after_user_leave_insert_mode = v:false
    let l:engine_name = ECY_main#GetCurrentUsingSourceName()
    call s:UpdateSignLists(l:engine_name)
  endif
"}}}
endfunction

function! s:PartlyPlaceSign_timer_cb(starts, ends, engine_name) abort
"{{{
  if !exists('g:ECY_diagnosis_items_with_engine_name[a:engine_name]')
    return
  endif
  let l:file_path = ECY#utility#GetCurrentBufferPath()
  let l:lists = py3eval('CalculateScreenSign(' . string(a:starts) . ',' . string(a:ends) . ')')
  call ECY#diagnosis#CleanAllSignHighlight()
  call s:UnplaceAllSignByEngineName(a:engine_name)
  for item in l:lists
    call s:PlaceSignAndHighlight(item['position'], 
          \item['diagnosis'],
          \item['items'], item['kind'],
          \item['file_path'],
          \a:engine_name,
          \l:file_path)
  endfor
  " let l:file_path = ECY#utility#GetCurrentBufferPath()
  " call ECY#diagnosis#CleanAllSignHighlight()
  " call s:UnplaceAllSignByEngineName(a:engine_name)
  " for item in g:ECY_diagnosis_items_with_engine_name[a:engine_name]
  "   if item['file_path'] == l:file_path
  "     let l:line = item['position']['line']
  "     if a:starts <= l:line && a:ends >= l:line
  "       call s:PlaceSignAndHighlight(item['position'], 
  "             \item['diagnosis'],
  "             \item['items'], item['kind'],
  "             \item['file_path'],
  "             \a:engine_name,
  "             \l:file_path)
  "     endif
  "   endif
  " endfor
"}}}
endfunction

function! s:UpdateDiagnosisByEngineName(msg) abort
  let l:engine_name = a:msg['EngineName']
  let g:ECY_diagnosis_items_with_engine_name[l:engine_name] = a:msg['Lists']
  let g:ECY_diagnosis_items_all = []
  let s:current_diagnosis = {}
endfunction

function! ECY#diagnosis#PartlyPlaceSign(msg) abort
  call s:StartUpdateTimer()
endfunction

function! ECY#diagnosis#PlaceSign(msg) abort
"{{{Place Sign and highlight it. partly or all
  let l:engine_name = a:msg['EngineName']
  if !g:ECY_enable_diagnosis || l:engine_name == ''
    return
  endif
  call s:UpdateDiagnosisByEngineName(a:msg) " but don't show sign, just update variable.
  if len(a:msg['Lists']) > 80
    let s:need_to_update_diagnosis_after_user_leave_insert_mode = v:false
    call ECY#diagnosis#PartlyPlaceSign(a:msg)
    return
  else
    call s:StopUpdateTimer()
  endif
  if g:ECY_update_diagnosis_mode == v:false && mode() != 'n'
    " don't want to update diagnosis in insert mode
    let s:need_to_update_diagnosis_after_user_leave_insert_mode = v:true
    return
  endif
  " show sign.
  call s:UpdateSignLists(l:engine_name)
"}}}
endfunction

function! s:UpdateSignLists(engine_name) abort
"{{{
  if !exists('g:ECY_diagnosis_items_with_engine_name[a:engine_name]')
    return
  endif
  call ECY#diagnosis#CleanAllSignHighlight()
  call s:UnplaceAllSignByEngineName(a:engine_name)
  let l:sign_lists = g:ECY_diagnosis_items_with_engine_name[a:engine_name]
  let l:file_path = ECY#utility#GetCurrentBufferPath()
  for item in l:sign_lists
    " item = {'items':[
    " {'name':'1', 'content': {'abbr': 'xxx'}},
    " {'name':'2', 'content': {'abbr': 'yyy'}}
    "  ],
    " 'position':{...}, 'diagnosis': 'strings'}
    call s:PlaceSignAndHighlight(item['position'], 
          \item['diagnosis'],
          \item['items'], item['kind'],
          \item['file_path'],
          \a:engine_name,
          \l:file_path)
  endfor
"}}}
endfunction

function! s:InitDiagnosisLists() abort
"{{{return lists
 let l:temp = []
 for [key, lists] in items(g:ECY_diagnosis_items_with_engine_name)
   if type(lists) != 3 " is not list
     continue
   endif
   call extend(l:temp, lists)
 endfor
 let g:ECY_diagnosis_items_all = l:temp
 let i = 0
 while i < len(g:ECY_diagnosis_items_all)
   let g:ECY_diagnosis_items_all[i]['index'] = i
   let i += 1
 endw
 return l:temp
"}}}
endfunction

function! ECY#diagnosis#ClearAllSign() abort
"{{{
  for [key, lists] in items(g:ECY_diagnosis_items_with_engine_name)
    call s:UnplaceAllSignByEngineName(key)
  endfor
"}}}
endfunction

function! ECY#diagnosis#Toggle() abort
"{{{
  let g:ECY_enable_diagnosis = (!g:ECY_enable_diagnosis)
  if g:ECY_enable_diagnosis
    let l:status = 'Alive'
    call s:StartUpdateTimer()
  else
    let l:status = 'Disabled'
    call s:StopUpdateTimer()
    call ECY#diagnosis#CleanAllSignHighlight()
    call ECY#diagnosis#ClearAllSign()
    let s:current_diagnosis       = {}
    let g:ECY_windows_are_showing['diagnosis']    = -1
    let g:ECY_diagnosis_items_all = []
    let g:ECY_diagnosis_items_with_engine_name = {}
  endif
  call ECY#utility#ShowMsg('[ECY] Diagnosis status: ' . l:status, 2)
"}}}
endfunction

function! ECY#diagnosis#ShowSelecting() abort
"{{{ show all
  call s:InitDiagnosisLists()
  call ECY#utility#StartLeaderfSelecting(g:ECY_diagnosis_items_all, 'ECY#diagnosis#Selecting_cb')
"}}}
endfunction

function! ECY#diagnosis#Selecting_cb(line, event, index, nodes) abort
"{{{
 let l:data = g:ECY_diagnosis_items_all
  let l:data  = l:data[a:index]
  if a:event == 'acceptSelection' || a:event == 'previewResult'
    let l:position = l:data['position']['range']['start']
    let l:path = l:data['file_path']
    call ECY#utility#MoveToBuffer(l:position['line'], 
          \l:position['colum'], 
          \l:path, 
          \'current buffer')
  endif
"}}}
endfunction

function! s:UpdateSignEvent(timer_id) abort 
"{{{
  if !g:ECY_enable_diagnosis
    call s:StopUpdateTimer()
    return
  endif
  if g:ECY_update_diagnosis_mode == v:false && mode() != 'n'
    return
  endif
  let l:start = line('w0')
  let l:end = line('w$')
  let l:windows_nr = winnr()
  if l:start != s:windows_start || l:end != s:windows_end || s:windows_nr !=
        \l:windows_nr
    let s:windows_start = l:start
    let s:windows_end = l:end
    let s:windows_nr = l:windows_nr
    call s:PartlyPlaceSign_timer_cb(s:windows_start, s:windows_end,
          \ECY_main#GetCurrentUsingSourceName())
  endif
"}}}
endfunction

function! s:StartUpdateTimer() abort 
  let s:windows_start = -1
  let s:windows_end = -1
  let s:windows_nr = -1
  " order matters
  call s:StopUpdateTimer()
  let s:update_timer_id = timer_start(1000, function('s:UpdateSignEvent'), {'repeat': -1})
endfunction

function! s:StopUpdateTimer() abort 
  if exists('s:update_timer_id')
    if s:update_timer_id != -1
      call timer_stop(s:update_timer_id)
    endif
  endif
  let s:update_timer_id = -1
endfunction

