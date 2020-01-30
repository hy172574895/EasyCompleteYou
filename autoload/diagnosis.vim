" Author: Jimmy Huang (1902161621@qq.com)
" License: WTFPL

function s:Init() abort
"{{{ var init
  hi ECY_diagnosis_erro  guifg=#eee8d5	guibg=#586e75	ctermfg=white	ctermbg=Blue
  hi ECY_diagnosis_warn  guifg=#eee8d5	guibg=#586e75	ctermfg=white	ctermbg=Blue
  hi ECY_diagnosis_highlight  term=undercurl gui=undercurl guisp=DarkRed cterm=underline
  let g:ECY_diagnosis_erro      = get(g:,'ECY_diagnosis_erro', 'ECY_diagnosis_erro')
  let g:ECY_diagnosis_warn      = get(g:,'ECY_diagnosis_warn', 'ECY_diagnosis_warn')
  let g:ECY_diagnosis_highlight = get(g:,'ECY_diagnosis_highlight','ECY_diagnosis_highlight')

  hi ECY_erro_sign_highlight  guifg=#eee8d5	guibg=#586e75	ctermfg=white	ctermbg=Blue
  hi ECY_warn_sign_highlight  guifg=#eee8d5	guibg=#586e75	ctermfg=white	ctermbg=Blue
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

  let g:ECY_sign_lists    = []
  let s:current_diagnosis = {}

  call s:SetUpEvent()

  let g:ECY_show_diagnosis = get(g:,'ECY_show_diagnosis', 'H')
  exe 'nmap ' . g:ECY_show_diagnosis .
        \ ' :call diagnosis#ShowCurrentLineDiagnosis(v:false)<CR>'
"}}}
endfunction

function s:SetUpEvent() abort
  augroup EasyCompleteYou_Diagnosis
    autocmd CursorHold * call s:OnCursorHold()
  augroup END
endfunction

function s:OnCursorHold() abort
  call diagnosis#ShowCurrentLineDiagnosis(v:true)
endfunction

function! diagnosis#ShowCurrentLineDiagnosis(is_triggered_by_event) abort
"{{{ show diagnosis msg in normal mode.
  if g:ECY_disable_diagnosis || mode() != 'n'
    call user_ui#ShowMsg("[ECY] Diagnosis had been turn off.", 2)
    return ''
  endif
  let l:current_line_nr   = line('.')
  let l:current_buffer_nr = bufnr()
  let l:index_list        = []
  for item in g:ECY_sign_lists
    if item['buffer_nr'] != l:current_buffer_nr || 
          \item['position']['line'] != l:current_line_nr
      continue
    endif
    call add(l:index_list, item)
  endfor
  if len(l:index_list) != 0
    let s:current_diagnosis['line']      = l:current_line_nr
    let s:current_diagnosis['buffer_nr'] = l:current_buffer_nr
    call diagnosis#ShowDiagnosis(l:index_list)
  else
    if !a:is_triggered_by_event 
      call user_ui#ShowMsg("[ECY] Diagnosis has nothing to show.", 2)
    endif
  endif
  return ''
"}}}
endfunction

function! diagnosis#ShowNextDiagnosis() abort
"{{{ show diagnosis msg in normal mode at current buffer. 
  let l:current_buffer_nr = bufnr()

  let l:i = 0
  if s:current_diagnosis == {}
    " init
    for item in g:ECY_sign_lists
      if l:current_buffer_nr == item['buffer_nr']
        let l:line = item['position']['line']
        let l:colum = item['position']['range']['start']['colum']
        let s:current_diagnosis['buffer_nr'] = l:current_buffer_nr
        let s:current_diagnosis['line'] = l:line
        call diagnosis#MoveTo(l:line, l:colum, l:i)
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
            \&& l:current_buffer_nr == s:current_diagnosis['buffer_nr']
        let l:colum = g:ECY_sign_lists[l:index]['position']['range']['start']['colum']
        call diagnosis#MoveTo(l:line, l:colum, l:index)
        call diagnosis#ShowCurrentLineDiagnosis(v:true)
        let s:current_diagnosis['line'] = l:line
        return ''
      endif
    endif
    let l:i += 1
  endfor
  call user_ui#ShowMsg("[ECY] Diagnosis has no next one.", 2)
  return ''
"}}}
endfunction

function! diagnosis#MoveTo(line, colum, index) abort
"{{{ on current buffer
  let l:lens = string(len(g:ECY_sign_lists))
  call user_ui#ShowMsg("[ECY] Diagnosis goto next (". a:index . '/' . l:lens . ')' , 2)
"}}}
endfunction

function! diagnosis#ShowDiagnosis(index_list) abort
"{{{ 
  if g:has_floating_windows_support == 'vim'
    let l:text = []
    for item in a:index_list
      if len(l:text) != 0
        call add(l:text, '----------------------------')
      endif
      let l:line = string(item['position']['line'])
      let l:colum = string(item['position']['range']['start']['colum'])
      call add(l:text, item['kind'] . ' [' .l:line . ', ' . l:colum . ']',)
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
          \ 'scrollbar': 1,
          \ 'firstline': 1,
          \ 'padding': [0,1,0,1],
          \ 'zindex': 2000}
      let l:nr = popup_atcursor(l:text, l:opts)
      call setbufvar(winbufnr(l:nr), '&filetype', &filetype)
      let l:exe = "call prop_add(1, 1, {'length': 100,'type': 'ECY_diagnosis_text'})"
      call win_execute(l:nr, l:exe)
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
"ensure cursor in buffer you want to highlight before you call this function.

  " map like a loop
  call map(s:CalculatePosition(a:range['start']['line'],
          \a:range['start']['colum'],
          \a:range['end']['line'],
          \a:range['end']['colum']),
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

function! diagnosis#UnPlaceAllSignInBuffer(buffer_nr) abort
"{{{ remove all ECY's sign in current buffer.
  let i = 0
  for item in g:ECY_sign_lists
    if item['buffer_nr'] == a:buffer_nr
      call sign_unplace('', {'buffer' : item['buffer_name'], 'id': item['id']})
      unlet g:ECY_sign_lists[i]
      call diagnosis#UnPlaceAllSignInBuffer(a:buffer_nr)
      return
    endif
    let i += 1
  endfor
  return
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

function! s:PlaceSign(position, diagnosis, items, style) abort
"{{{ place a sign in current buffer.
  " a:position = {'line': 10, 'range': {'start': { 'line': 5, 'colum': 23 },'end' : { 'line': 6, 'colum': 0 } }}
  " a:diagnosis = {'item':{'1':'asdf', '2':'sdf'}}
  let l:buffer_nr = bufnr()
  if a:style == 1
    let l:style = 'ECY_diagnosis_erro'
  else
    let l:style = 'ECY_diagnosis_warn'
  endif
  let l:buffer_name = s:GetCurrentBufferName()
  let l:sign_id = sign_place(0,'',l:style, l:buffer_name, {'lnum' : a:position['line']})
  call s:HighlightRange(a:position['range'], 'ECY_diagnosis_highlight')

  let l:temp = {'position': a:position, 
        \'id': l:sign_id,
        \'buffer_nr': l:buffer_nr,
        \'items': a:items,
        \'buffer_name': l:buffer_name,
        \'diagnosis': a:diagnosis,
        \'kind': l:style}
  call add(g:ECY_sign_lists, l:temp)
"}}}
endfunction

function! diagnosis#PlaceSign(msg) abort
"{{{Place a Sign and highlight it.
  " order matters
  call diagnosis#CleanAllSignHighlight()
  call diagnosis#UnPlaceAllSignInBuffer(bufnr())
  let l:items = a:msg['Lists']
  if len(l:items) > 100
    call user_ui#ShowMsg("[ECY] Diagnosis will not be highlighted: the erros/warnnings are too much.", 2)
    return
  endif
  for item in l:items
    " item = {'items':[
    " {'name':'1', 'content': {'abbr': 'xxx'}},
    " {'name':'2', 'content': {'abbr': 'yyy'}}
    "  ],
    " 'position':{...}, 'diagnosis': 'strings'}
    call s:PlaceSign(item['position'], item['diagnosis'], item['items'], 1)
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
"}}}
endfunction

function! s:GetCurrentBufferName(...) abort
  "{{{
  let l:file = a:0 ? a:1 : @%
  if l:file =~# '^\a\a\+:' || a:0 > 1
    return call('Current_buffer_path', [l:file] + a:000[1:-1])
  elseif l:file =~# '^/\|^\a:\|^$'
    return l:file
  else
    let l:full_path = fnamemodify(l:file, ':p' . (l:file =~# '[\/]$' ? '' : ':s?[\/]$??'))
    return l:full_path
  endif
  "}}}
endfunction

function! diagnosis#ShowSelecting() abort
"{{{ show all
  let g:ECY_items_data = g:ECY_sign_lists
  " must be called by a timer.
  call timer_start(1, 'user_ui#UsingTimerStartingSelectingWindows')
"}}}
endfunction

call s:Init()
