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

  call sign_define("ECY_diagnosis_erro", {
    \ "text" : ">>",
    \ "texthl" : g:ECY_erro_sign_highlight})
  call sign_define("ECY_diagnosis_warn", {
    \ "text" : "!!",
    \ "texthl" : g:ECY_warn_sign_highlight})

  let g:ECY_sign_lists       = []
  let s:current_diagnosis    = {}
  let s:current_diagnosis_nr = -1

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
  if g:ECY_disable_diagnosis || mode() != 'n'
    if !a:is_triggered_by_event
      call utility#ShowMsg("[ECY] Diagnosis had been turn off.", 2)
    endif
    return ''
  endif
  let l:current_line_nr   = line('.')
  let l:current_buffer_path = utility#GetCurrentBufferPath()
  let l:index_list        = []
  let i = 0
  for item in g:ECY_sign_lists
    let item['index'] = i
    let i += 1
    if item['buffer_name'] != l:current_buffer_path || 
          \item['position']['line'] != l:current_line_nr
      continue
    endif
    call add(l:index_list, item)
  endfor
  if len(l:index_list) != 0
    let s:current_diagnosis['line']      = l:current_line_nr
    let s:current_diagnosis['buffer_name'] = l:current_buffer_path
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
    " init
    for item in g:ECY_sign_lists
      if l:current_buffer_path == item['buffer_name']
        let l:line = item['position']['line']
        let l:colum = item['position']['range']['start']['colum']
        let s:current_diagnosis['buffer_name'] = l:current_buffer_path
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
  for item in g:ECY_sign_lists
    if item['position']['line'] == s:current_diagnosis['line']
      let l:index = (l:i + 1) % len(g:ECY_sign_lists)
      let l:line = g:ECY_sign_lists[l:index]['position']['line']
      if  l:line != s:current_diagnosis['line'] 
            \&& l:current_buffer_path == s:current_diagnosis['buffer_name']
        let l:colum = g:ECY_sign_lists[l:index]['position']['range']['start']['colum']
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
      let l:lists_len = string(len(g:ECY_sign_lists))
      let l:nr = "(" . l:index . '/' . l:lists_len . ')'
      call add(l:text, item['kind'] . ' [' .l:line . ', ' . l:colum . '] ' . l:nr)
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
  for l:match in getmatches()
      if l:match['group'] =~# '^ECY_diagnosis'
          call matchdelete(l:match['id'])
      endif
  endfor
"}}}
endfunction

function! diagnosis#UnPlaceAllSignInBufferName(buffer_name) abort
"{{{ remove all ECY's sign in current buffer.
  let i = 0
  while i < len(g:ECY_sign_lists)
    let l:temp = g:ECY_sign_lists[i]
    if l:temp['buffer_name'] == a:buffer_name
      call sign_unplace('', {'buffer' : l:temp['buffer_name'], 'id': l:temp['id']})
      unlet g:ECY_sign_lists[i]
      continue
    endif
    let i += 1
  endw
"}}}
endfunction

function! diagnosis#UnPlaceAllSign() abort
"{{{
  for item in g:ECY_sign_lists
    call sign_unplace('', {'buffer' : item['buffer_name'], 'id' : item['id']})
  endfor
  let g:ECY_sign_lists = []
"}}}
endfunction

function! s:PlaceSign(position, diagnosis, items, style, path) abort
"{{{ place a sign in current buffer.
  " a:position = {'line': 10, 'range': {'start': { 'line': 5, 'colum': 23 },'end' : { 'line': 6, 'colum': 0 } }}
  " a:diagnosis = {'item':{'1':'asdf', '2':'sdf'}}
  if a:style == 1
    let l:style = 'ECY_diagnosis_erro'
  else
    let l:style = 'ECY_diagnosis_warn'
  endif
  let l:sign_id = sign_place(0,'',l:style, a:path, {'lnum' : a:position['line']})
  if utility#GetCurrentBufferPath() == a:path
    call s:HighlightRange(a:position['range'], 'ECY_diagnosis_highlight')
  endif
  let l:temp = {'position': a:position, 
        \'id': l:sign_id,
        \'items': a:items,
        \'buffer_name': a:path,
        \'diagnosis': a:diagnosis,
        \'kind': l:style}
  call add(g:ECY_sign_lists, l:temp)
"}}}
endfunction

function! diagnosis#PlaceSign(msg) abort
"{{{Place a Sign and highlight it.
  if (exists("a:msg['DocumentID']") 
        \ && ECY_main#GetDocumentVersionID() > a:msg['DocumentID'] )
        \ || g:ECY_disable_diagnosis
    return
  endif
  " order matters
  call diagnosis#CleanAllSignHighlight()
  call diagnosis#UnPlaceAllSignInBufferName(utility#GetCurrentBufferPath())
  let s:current_diagnosis = {}
  let l:items = a:msg['Lists']
  if len(l:items) > 500
    call utility#ShowMsg("[ECY] Diagnosis will not be highlighted: the erros/warnnings are too much.", 2)
    return
  endif
  for item in l:items
    " item = {'items':[
    " {'name':'1', 'content': {'abbr': 'xxx'}},
    " {'name':'2', 'content': {'abbr': 'yyy'}}
    "  ],
    " 'position':{...}, 'diagnosis': 'strings'}
    call s:PlaceSign(item['position'], 
          \item['diagnosis'],
          \item['items'], item['kind'],
          \item['file_path'])
  endfor
"}}}
endfunction

function! diagnosis#Toggle() abort
"{{{
  let g:ECY_disable_diagnosis = (!g:ECY_disable_diagnosis)
  if g:ECY_disable_diagnosis 
    call diagnosis#CleanAllSignHighlight()
    call diagnosis#UnPlaceAllSign()
  endif
  if g:ECY_disable_diagnosis
    let l:status = 'Alive'
  else
    let l:status = 'Disabled'
  endif
  call utility#ShowMsg('[ECY] Diagnosis status: ' . l:status, 2)
"}}}
endfunction

function! diagnosis#ShowSelecting() abort
"{{{ show all
  call utility#StartLeaderfSelecting(g:ECY_sign_lists, 'diagnosis#Selecting_cb')
"}}}
endfunction

function! diagnosis#Selecting_cb(line, event, index, nodes) abort
"{{{
  let l:data  = g:ECY_sign_lists[a:index]
  if a:event == 'acceptSelection' || a:event == 'previewResult'
    let l:position = l:data['position']['range']['start']
    let l:path = l:data['buffer_name']
    call utility#MoveToBuffer(l:position['line'], 
          \l:position['colum'], 
          \l:path, 
          \'current buffer_name')
  endif
"}}}
endfunction
