" Author: Jimmy Huang (1902161621@qq.com)
" License: WTFPL
 
function diagnosis#Init() abort
"{{{ var init
  hi ECY_diagnosis_highlight  term=undercurl gui=undercurl guisp=DarkRed cterm=underline
  let g:ECY_diagnosis_highlight = get(g:,'ECY_diagnosis_highlight','ECY_diagnosis_highlight')

  hi ECY_erro_sign_highlight  guifg=red	    ctermfg=red	
  hi ECY_warn_sign_highlight  guifg=yellow	ctermfg=yellow
  let g:ECY_erro_sign_highlight = get(g:,'ECY_erro_sign_highlight', 'ECY_erro_sign_highlight')
  let g:ECY_warn_sign_highlight = get(g:,'ECY_warn_sign_highlight', 'ECY_warn_sign_highlight')

  if g:has_floating_windows_support == 'vim'
    let g:ECY_diagnosis_text = get(g:,'ECY_diagnosis_text', 'Title')
    call prop_type_add('ECY_diagnosis_text', {'highlight': g:ECY_diagnosis_text})
  endif

  " 1 means ask diagnosis when there are changes not including user in insert mode, trigger by DoCompletion()
  " 2 means ask diagnosis when there are changes including user in insert mode, trigger by OnBufferTextChanged().
  let g:ECY_update_diagnosis_mode
        \= get(g:,'ECY_update_diagnosis_mode', 1)
  if g:ECY_update_diagnosis_mode == 2
    let g:ECY_update_diagnosis_mode = v:true
  else
    let g:ECY_update_diagnosis_mode = v:false
  endif
  " user don't want to update diagnosis in insert mode, but engine had
  " returned diagnosis, so we cache it and update after user leave insert
  " mode.
  let s:need_to_update_diagnosis_after_user_leave_insert_mode = v:false
  let g:ECY_enable_diagnosis
        \= get(g:,'ECY_enable_diagnosis', v:true)

  " can not use sign_define()
  execute 'sign define ECY_diagnosis_erro text=>> texthl=' . g:ECY_erro_sign_highlight
  execute 'sign define ECY_diagnosis_warn text=!! texthl=' . g:ECY_warn_sign_highlight

  " call sign_define("ECY_diagnosis_erro", {
  "   \ "text" : ">>",
  "   \ "texthl" : g:ECY_erro_sign_highlight})
  " call sign_define("ECY_diagnosis_warn", {
  "   \ "text" : "!!",
  "   \ "texthl" : g:ECY_warn_sign_highlight})

  let s:current_diagnosis                    = {}
  let s:current_diagnosis_nr                 = -1
  let g:ECY_diagnosis_items_all              = []
  let g:ECY_diagnosis_items_with_engine_name = {'nothing': []}


  call s:SetUpEvent()

  let g:ECY_show_diagnosis_in_normal_mode = get(g:,'ECY_show_diagnosis_in_normal_mode', 'H')
  let g:ECY_show_next_diagnosis_in_normal_mode = get(g:,'ECY_show_next_diagnosis_in_normal_mode', '[j')
  exe 'nmap ' . g:ECY_show_diagnosis_in_normal_mode . ' :call diagnosis#ShowCurrentLineDiagnosis(v:false)<CR>'
  exe 'nmap ' . g:ECY_show_next_diagnosis_in_normal_mode . ' :call diagnosis#ShowNextDiagnosis()<CR>'
"}}}
endfunction

function s:SetUpEvent() abort
  augroup EasyCompleteYou_Diagnosis
    autocmd CursorHold * call s:OnCursorHold()
  augroup END
endfunction

function s:OnCursorHold() abort
  if s:current_diagnosis_nr == -1
    call diagnosis#ShowCurrentLineDiagnosis(v:true)
  endif
endfunction

function! diagnosis#ShowCurrentLineDiagnosis(is_triggered_by_event) abort
"{{{ show diagnosis msg in normal mode.
  if !g:ECY_enable_diagnosis || mode() != 'n'
    if !a:is_triggered_by_event
      call utility#ShowMsg("[ECY] Diagnosis had been turn off.", 2)
    endif
    return ''
  endif
  let g:ECY_diagnosis_items_all = diagnosis#GetAllDiagnosis()
  let l:current_line_nr   = line('.')
  let l:current_buffer_path = utility#GetCurrentBufferPath()
  let l:index_list        = []
  let i = 0
  for item in g:ECY_diagnosis_items_all
    let item['index'] = i
    let i += 1
    if item['file_path'] != l:current_buffer_path || 
          \item['position']['line'] != l:current_line_nr
      continue
    endif
    call add(l:index_list, item)
  endfor
  if len(l:index_list) != 0
    let s:current_diagnosis['line']      = l:current_line_nr
    let s:current_diagnosis['file_path'] = l:current_buffer_path
    call s:ShowDiagnosis(l:index_list)
  else
    if !a:is_triggered_by_event 
      call utility#ShowMsg("[ECY] Diagnosis has nothing to show in current buffer.", 2)
    endif
  endif
  return ''
"}}}
endfunction

function! diagnosis#ShowNextDiagnosis() abort
"{{{ show diagnosis msg in normal mode at current buffer. 
  let l:current_buffer_path = utility#GetCurrentBufferPath()

  let l:i = 0
  if s:current_diagnosis == {}
    let g:ECY_diagnosis_items_all = diagnosis#GetAllDiagnosis()
    " init
    for item in g:ECY_diagnosis_items_all
      if l:current_buffer_path == item['file_path']
        let l:line = item['position']['line']
        let l:colum = item['position']['range']['start']['colum']
        let s:current_diagnosis['file_path'] = l:current_buffer_path
        let s:current_diagnosis['line'] = l:line
        call utility#MoveToBuffer(l:line, l:colum, l:current_buffer_path, 'current buffer')
        call diagnosis#ShowCurrentLineDiagnosis(v:true)
        break
      endif
      let l:i += 1
    endfor
    return ''
  endif

  let l:i = 0
  for item in g:ECY_diagnosis_items_all
    if item['position']['line'] == s:current_diagnosis['line']
      let l:index = (l:i + 1) % len(g:ECY_diagnosis_items_all)
      let l:line = g:ECY_diagnosis_items_all[l:index]['position']['line']
      if  l:line != s:current_diagnosis['line'] 
            \&& l:current_buffer_path == s:current_diagnosis['file_path']
        let l:colum = g:ECY_diagnosis_items_all[l:index]['position']['range']['start']['colum']
        call utility#MoveToBuffer(l:line, l:colum, l:current_buffer_path, 'current buffer')
        call diagnosis#ShowCurrentLineDiagnosis(v:true)
        let s:current_diagnosis['line'] = l:line
        return ''
      endif
    endif
    let l:i += 1
  endfor
  call utility#ShowMsg("[ECY] Diagnosis has no next one.", 2)
  return ''
"}}}
endfunction

function! g:Diagnosis_vim_cb(id, key) abort
  let s:current_diagnosis_nr = -1
endfunction

function! s:CloseDiagnosisPopupWindows() abort
"{{{
  if s:current_diagnosis_nr != -1
    if g:has_floating_windows_support == 'vim'
      call popup_close(s:current_diagnosis_nr)
      let s:current_diagnosis_nr = -1
    endif
  endif
"}}}
endfunction

function! s:ShowDiagnosis(index_list) abort
"{{{ 
  call s:CloseDiagnosisPopupWindows()
  if g:has_floating_windows_support == 'vim'
    let l:text = []
    for item in a:index_list
      if len(l:text) != 0
        call add(l:text, '----------------------------')
      endif
      let l:line = string(item['position']['line'])
      let l:colum = string(item['position']['range']['start']['colum'])
      let l:index = string(item['index'] + 1)
      let l:lists_len = string(len(g:ECY_diagnosis_items_all))
      let l:nr = "(" . l:index . '/' . l:lists_len . ')'
      if item['kind'] == 1
        let l:style = 'ECY_diagnosis_erro'
      else
        let l:style = 'ECY_diagnosis_warn'
      endif
      call add(l:text, l:style . ' [' .l:line . ', ' . l:colum . '] ' . l:nr)
      call add(l:text, '(' . item['diagnosis'] . ')')
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
      " let l:exe = "call prop_add(1, 1, {'length': 100,'type': 'ECY_diagnosis_text'})"
      " call win_execute(l:nr, l:exe)
      let s:current_diagnosis_nr = l:nr
    endif
  endif
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

function! diagnosis#CleanAllSignHighlight() abort
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

function! diagnosis#UnPlaceAllSignInBufferName(file_path) abort
"{{{ remove all ECY's sign in current buffer.
  let i = 0
  while i < len(g:ECY_diagnosis_items_all)
    let l:temp = g:ECY_diagnosis_items_all[i]
    if l:temp['file_path'] == a:file_path
      call sign_unplace('', {'buffer' : l:temp['file_path'], 'id': l:temp['id']})
      unlet g:ECY_diagnosis_items_all[i]
      continue
    endif
    let i += 1
  endw
"}}}
endfunction

function! diagnosis#UnPlaceAllSign() abort
"{{{
  for item in g:ECY_diagnosis_items_all
    call sign_unplace('', {'buffer' : item['file_path'], 'id' : item['id']})
  endfor
  let g:ECY_diagnosis_items_all = []
"}}}
endfunction

function! diagnosis#UnPlaceAllSignByEngineName(engine_name, is_clean_sign) abort
"{{{
  " let i = 0
  " while i < len(g:ECY_diagnosis_items_all)
  "   let l:temp = g:ECY_diagnosis_items_all[i]
  "   if l:temp['engine_name'] == a:engine_name
  "     unlet g:ECY_diagnosis_items_all[i]
  "     continue
  "   endif
  "   let i += 1
  " endw
  let g:ECY_diagnosis_items_with_engine_name[a:engine_name] = []
  if a:is_clean_sign
    call sign_unplace(a:engine_name)
  endif
"}}}
endfunction

function! diagnosis#UnPlacePartialSignByEngineName(engine_name, new_lists) abort
"{{{
  let i = 0
  while i < len(g:ECY_diagnosis_items_all)
    let l:need = v:false
    let l:temp = g:ECY_diagnosis_items_all[i]
    if l:temp['engine_name'] == a:engine_name
      for item in new_lists
        if item['position'] == l:temp['position'] && 
              \item['file_path'] == l:temp['file_path']
          let l:need = v:true
          break
        endif
      endfor
      if !l:need
        call sign_unplace('', {'buffer' : l:temp['file_path'], 'id': l:temp['id']})
      endif
      unlet g:ECY_diagnosis_items_all[i]
      continue
    endif
    let i += 1
  endw
"}}}
endfunction

function! s:PlaceSign(position, diagnosis, items, style, path, engine_name, current_buffer_path) abort
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
    call sign_place(0,
           \l:group_name,
           \l:style, a:path,
           \{'lnum' : a:position['line']})
  catch 
  endtry
  if a:current_buffer_path == a:path
    call s:HighlightRange(a:position['range'], 'ECY_diagnosis_highlight')
  endif
"}}}
endfunction

function! diagnosis#OnInsertModeLeave() abort
"{{{ show all.
  if !g:ECY_enable_diagnosis
    return
  endif
  if s:need_to_update_diagnosis_after_user_leave_insert_mode &&
        \g:ECY_update_diagnosis_mode
    let s:need_to_update_diagnosis_after_user_leave_insert_mode = v:false
    let l:engine_name = ECY_main#GetCurrentUsingSourceName()
    call s:UpdateAllSign(l:engine_name)
  endif
"}}}
endfunction

function! s:PartlyPlaceSign_timer_cb(starts, ends, engine_name) abort
"{{{
  if !exists('g:ECY_diagnosis_items_with_engine_name[a:engine_name]')
    return
  endif
  let l:file_path = utility#GetCurrentBufferPath()
  let l:lists = py3eval('CalculateScreenSign(' . string(a:starts) . ',' . string(a:ends) . ')')
  call diagnosis#CleanAllSignHighlight()
  call sign_unplace(a:engine_name)
  for item in l:lists
    call s:PlaceSign(item['position'], 
          \item['diagnosis'],
          \item['items'], item['kind'],
          \item['file_path'],
          \a:engine_name,
          \l:file_path)
  endfor
  " let l:file_path = utility#GetCurrentBufferPath()
  " call diagnosis#CleanAllSignHighlight()
  " call sign_unplace(a:engine_name)
  " for item in g:ECY_diagnosis_items_with_engine_name[a:engine_name]
  "   if item['file_path'] == l:file_path
  "     let l:line = item['position']['line']
  "     if a:starts <= l:line && a:ends >= l:line
  "       call s:PlaceSign(item['position'], 
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
  let s:current_diagnosis = {}
endfunction

function! diagnosis#PartlyPlaceSign(msg) abort
  call s:StartUpdateTimer()
endfunction

function! diagnosis#PlaceSign(msg) abort
"{{{Place Sign and highlight it. partly or all
  let l:engine_name = a:msg['EngineName']
  if !g:ECY_enable_diagnosis || l:engine_name == ''
    return
  endif
  call s:UpdateDiagnosisByEngineName(a:msg) " but don't show sign, just update variable.
  if len(a:msg['Lists']) > 80
    call diagnosis#PartlyPlaceSign(a:msg)
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
  call s:UpdateAllSign(l:engine_name)
"}}}
endfunction

function! s:UpdateAllSign(engine_name) abort
"{{{
  call diagnosis#CleanAllSignHighlight()
  call sign_unplace(a:engine_name)
  let l:sign_lists = g:ECY_diagnosis_items_with_engine_name[a:engine_name]
  let l:file_path = utility#GetCurrentBufferPath()
  for item in l:sign_lists
    " item = {'items':[
    " {'name':'1', 'content': {'abbr': 'xxx'}},
    " {'name':'2', 'content': {'abbr': 'yyy'}}
    "  ],
    " 'position':{...}, 'diagnosis': 'strings'}
    call s:PlaceSign(item['position'], 
          \item['diagnosis'],
          \item['items'], item['kind'],
          \item['file_path'],
          \a:engine_name,
          \l:file_path)
  endfor
"}}}
endfunction

function! diagnosis#GetAllDiagnosis() abort
"{{{return lists
 let l:temp = []
 for [key, lists] in items(g:ECY_diagnosis_items_with_engine_name)
   call extend(l:temp, lists)
 endfor
 return l:temp
"}}}
endfunction

function! diagnosis#Toggle() abort
"{{{
  let g:ECY_enable_diagnosis = (!g:ECY_enable_diagnosis)
  if g:ECY_enable_diagnosis
    let l:status = 'Alive'
    call s:StartUpdateTimer()
  else
    let l:status = 'Disabled'
    call s:StopUpdateTimer()
    call diagnosis#CleanAllSignHighlight()
    call sign_unplace('*')
    let s:current_diagnosis       = {}
    let s:current_diagnosis_nr    = -1
    let g:ECY_diagnosis_items_all = []
    let g:ECY_diagnosis_items_with_engine_name = {}
  endif
  call utility#ShowMsg('[ECY] Diagnosis status: ' . l:status, 2)
"}}}
endfunction

function! diagnosis#ShowSelecting() abort
"{{{ show all
  let g:ECY_diagnosis_items_all = diagnosis#GetAllDiagnosis()
  call utility#StartLeaderfSelecting(g:ECY_diagnosis_items_all, 'diagnosis#Selecting_cb')
"}}}
endfunction

function! diagnosis#Selecting_cb(line, event, index, nodes) abort
"{{{
 let l:data = diagnosis#GetAllDiagnosis()
  let l:data  = l:data[a:index]
  if a:event == 'acceptSelection' || a:event == 'previewResult'
    let l:position = l:data['position']['range']['start']
    let l:path = l:data['file_path']
    call utility#MoveToBuffer(l:position['line'], 
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

python3 <<endpython
import vim

def CalculateScreenSign(start, end):
  engine_name = vim.eval('ECY_main#GetCurrentUsingSourceName()')
  lists = "g:ECY_diagnosis_items_with_engine_name['" + engine_name + "']"
  lists = vim.eval(lists)
  file_path = vim.eval('utility#GetCurrentBufferPath()')
  results = []
  for item in lists:
    line = int(item['position']['line'])
    if item['file_path'] == file_path:
      if start <= line and end >= line:
        results.append(item)
  return results
endpython
