" Author: Jimmy Huang (1902161621@qq.com)
" License: WTFPL
" Log:
" 2020-01-30 03:14  Happy birthday to me.
" 2020-02-02 22:25  Happy 2020-0202.

" must put these outside a function
let  g:ECY_python_script_folder_path = expand( '<sfile>:p:h:h' ).'/python'
let  g:ECY_python_script_folder_path = tr(g:ECY_python_script_folder_path, '\', '/')
  
function! s:SetUpEvent() abort
"{{{
  augroup EasyCompleteYou
    autocmd!
    autocmd FileType      * call s:OnBufferEnter()
    autocmd BufEnter      * call s:OnBufferEnter()
    autocmd BufLeave      * call s:OnBufferLeave()
    autocmd VimLeavePre   * call s:OnVIMLeave()

    " will send full buffer data to the server.
    " invoked after typing a character into the buffer or user sept in insert mode  
    autocmd TextChanged   * call s:OnTextChangedNormalMode()
    autocmd TextChangedI  * call s:OnTextChangedInsertMode()

    autocmd InsertLeave   * call s:OnInsertModeLeave()
    autocmd InsertEnter   * call s:OnInsertMode()
    autocmd InsertCharPre * call s:OnInsertChar()

    if g:has_floating_windows_support == 'vim'
      if !g:ECY_use_floating_windows_to_be_popup_windows
        " has floating windows, but user don't want to use it to be popup window
        autocmd CompleteChanged * call s:OnSelectingMenu_vim()
      endif
    elseif g:has_floating_windows_support == 'nvim'
      " TODO
    endif
  augroup END
"}}}
endfunction

function ECY_main#UsingTextDifferEvent()
  if !g:ECY_use_text_differ || !g:has_text_prop_event
    return v:false
  endif
  return v:true
endfunction

function ECY_main#TextDifferEvent(bufnr, start, end, added, changes)
"{{{
  if !ECY_main#UsingTextDifferEvent()
    return
  endif
  let l:line_need_to_update = []
  " let l:line_need_to_update = [a, b ,c]
  " a is the kind of operations.
  " b should > c
  for item in a:changes
    let l:index = item['lnum'] - 1
    if item['lnum'] == item['end'] && item['col'] == 1 && item['added'] > 0
      let l:range = ['insert', l:index, l:index - 1 + item['added']]
    elseif item['added'] != 0
      let l:deleted_line = item['added'] * -1
      let l:range = ['delete', l:index, l:index - 1 + l:deleted_line]
    else
      let l:range = ['replace', l:index, l:index]
    endif
    call add(l:line_need_to_update, l:range)
  endfor
  if exists('g:ECY_buffer_need_to_update[a:bufnr]')
    call extend(g:ECY_buffer_need_to_update[a:bufnr], l:line_need_to_update)
  else
    let g:ECY_buffer_need_to_update[a:bufnr] = l:line_need_to_update
  endif
  if ECY#color_completion#IsPromptOpen()
    return
  endif
  if mode() == 'i'
    call s:OnTextChangedInsertMode()
  else
    call s:OnTextChangedNormalMode()
  endif
"}}}
endfunction

function! s:OnSelectingMenu_vim() abort 
"{{{ currently, only be triggered if there are vim's floating windows supports.
  try
    call ECY#completion_preview_windows#Close()
    if g:ECY_use_floating_windows_to_be_popup_windows == v:true && g:is_vim
      let l:item_index = g:ECY_current_popup_windows_info['selecting_item']
      if l:item_index == 0
        return
      endif
      let l:item_index -= 1
    else
      " v:completed_item could be none, so we try it.
      let l:item_index  = v:completed_item['user_data']
    endif
    call ECY#completion_preview_windows#Show(
          \g:ECY_completion_data[l:item_index], &syntax)
  catch
  endtry
  let s:completion_text_id += 1
  call timer_start(1000, function('s:CallTextChangedEventWithTimer',
        \[s:completion_text_id]))
"}}}
endfunction

function! s:CallTextChangedEventWithTimer(completion_text_id, timer_id) abort 
  "{{{
  if a:completion_text_id != s:completion_text_id
    return
  endif
  call s:OnTextChangedNormalMode()
  "}}}
endfunction

function! s:OnBufferLeave() abort 
  "{{{
  call s:BackToLastSource(-1)
  "}}}
endfunction

function! s:OnTextChangedNormalMode() abort 
  "{{{
  if !ECY_main#IsECYWorksAtCurrentBuffer()
    return
  endif
  call ECY_main#ChangeDocumentVersionID()
  call ECY#diagnosis#CleanAllSignHighlight()
  call ECY_main#Do("OnBufferTextChanged", v:true)
  "}}}
endfunction

function! s:OnInsertMode() abort 
  "{{{
  if !ECY_main#IsECYWorksAtCurrentBuffer()
    return
  endif
  call s:DoCompletion()
  "}}}
endfunction

function! s:OnVIMLeave() abort 
  "{{{ clean all legacy of ECY before existing.
  call ECY_main#Do("Exit", v:true)
  "}}}
endfunction

function! s:OnInsertModeLeave() abort 
  "{{{
  if !ECY_main#IsECYWorksAtCurrentBuffer()
    return
  endif
  " order matters
  call s:BackToLastSource(-1)
  call ECY#diagnosis#OnInsertModeLeave()
  call ECY#completion_preview_windows#Close()
  " we don't trigger this event to Server,
  " because we frequently escape insert mode and this event is unless for most of engines.
  " call ECY_main#Do("OnInsertModeLeave", v:true)
  "}}}
endfunction

function! s:OnBufferEnter() abort 
  "{{{
  if !ECY_main#IsECYWorksAtCurrentBuffer()
    return
  endif
  if ECY_main#UsingTextDifferEvent() && !has_key(g:ECY_cached_buffer_nr_to_path, bufnr())
    call listener_add('ECY_main#TextDifferEvent')
    let g:ECY_cached_buffer_nr_to_path[bufnr()] = ECY#utility#GetCurrentBufferPath()
  endif
  call ECY#utility#SaveIndent()
  let s:completeopt_temp     = &completeopt
  let s:completeopt_fuc_temp = &completefunc
  call ECY#diagnosis#CleanAllSignHighlight()
  call s:SetUpCompleteopt()
  " OnBufferEnter will trigger Diagnosis
  call ECY_main#Do("OnBufferEnter", v:true)
  "}}}
endfunction

function! s:OnTextChangedInsertMode() abort 
  "{{{ invoke pop menu
  if !ECY_main#IsECYWorksAtCurrentBuffer()
    return
  endif
  call ECY_main#ChangeDocumentVersionID()
  call ECY#diagnosis#CleanAllSignHighlight()
  call s:DoCompletion()
  "}}}
endfunction

" ==============================================================================
function! s:SetUpCompleteopt() abort 
"{{{
  " can't format here:
  if g:has_floating_windows_support == 'vim' && 
        \g:ECY_use_floating_windows_to_be_popup_windows == v:true
    " use ours popup windows
    set completeopt-=menuone
    set completeopt+=menu
  else
    set completeopt-=menu
    set completeopt+=menuone
  endif
  set completeopt-=longest
  set shortmess+=c
  set completefunc=ECY_main#CompleteFunc
"}}}
endfunction

function! s:DoCompletion() abort
"{{{ this will update buffer text too. so we don't trigger event of
"'OnBufferTextChanged'
  if g:has_floating_windows_support == 'vim' && 
        \g:ECY_use_floating_windows_to_be_popup_windows == v:true
    if s:isSelecting
      let s:isSelecting = v:false
      " this is necessary, because we don't trigger server to complete when we
      " are selecting.
      return
    endif
    " reflesh it when user typing key into buffer.
    call ECY#completion_preview_windows#Close()
    call ECY#utility#RecoverIndent()
    call ECY#color_completion#ClosePrompt()
  endif
  call ECY_main#ChangeVersionID()
  call ECY_main#Do("DoCompletion", v:true)
"}}}
endfunction

function! s:OnInsertChar() abort
"{{{
  if !ECY_main#IsECYWorksAtCurrentBuffer()
    return
  endif
  if pumvisible()
    call ECY#utility#SendKeys( "\<C-e>" )
  endif
"}}}
endfunction

function! s:PythonEval(eval_string) abort
"{{{
  return py3eval( a:eval_string )
"}}}
endfunction

function! s:UsingSpecicalSource(engine_name, invoke_key, is_replace) abort
"{{{
  if ECY_main#IsECYWorksAtCurrentBuffer()
    let l:curren_file_type = &filetype
    let l:temp = g:ECY_file_type_info[l:curren_file_type]['filetype_using']
    if !exists('s:last_used_completor') 
          \|| a:engine_name != l:temp
      let s:last_used_completor                = {}
      let s:last_used_completor['source_name'] = l:temp
      let s:last_used_completor['file_type']   = l:curren_file_type
    endif
    let l:available_sources = g:ECY_file_type_info[l:curren_file_type]['available_sources']
    if ECY#utility#IsInList(a:engine_name, l:available_sources)
      let g:ECY_file_type_info[l:curren_file_type]['filetype_using']
            \ = a:engine_name

      " replace invoke_key in buffer.
      if a:is_replace
        let g:ECY_file_type_info[l:curren_file_type]['special_position'] = 
              \ECY#utility#GetCurrentBufferPosition()
      else
        let g:ECY_file_type_info[l:curren_file_type]['special_position'] = {}
      endif

      " send buffer context to new engine.
      call ECY_main#AfterUserChooseASource()
    endif
  endif
  call ECY#utility#SendKeys(a:invoke_key)
  return ''
"}}}
endfunction

function! s:SetVariable() abort
"{{{ 

  " this debug option will start another server with socket port 1234 and
  " HMAC_KEY 1234, and output logging to file where server dir is. 
  let g:ECY_debug
        \= get(g:, 'ECY_debug', v:false)

  let g:ECY_select_items
        \= get(g:, 'ECY_select_items',['<Tab>','<S-TAB>'])

  let g:ECY_show_switching_source_popup
        \= get(g:,'ECY_show_switching_source_popup','<Tab>')

  " ECY have special key for triggering snippets, but the mapping of jumping to 
  " next or previous item is same as the snippets-plugin.
  let g:ECY_expand_snippets_key
        \= get(g:,'ECY_expand_snippets_key','<CR>')

  let g:ECY_choose_special_source_key
        \= get(g:,'ECY_choose_special_source_key',
        \[{'source_name':'snippets','invoke_key':'@', 'is_replace': v:true},
        \{'source_name':'path','invoke_key':'/', 'is_replace': v:false}])

  if executable('python2')
    " user have python2
    let g:ECY_python3_cmd                               
          \= get(g:,'ECY_python3_cmd','python3')
  else
    let g:ECY_python3_cmd                               
          \= get(g:,'ECY_python3_cmd','python')
  endif

  let g:ECY_file_type_info
        \= get(g:,'ECY_file_type_info',{})

  let g:ECY_triggering_length
        \= get(g:,'ECY_triggering_length',1)

  if exists('g:ycm_disable_for_files_larger_than_kb')
    let g:ECY_disable_for_files_larger_than_kb = g:ycm_disable_for_files_larger_than_kb
  else
    let g:ECY_disable_for_files_larger_than_kb
          \= get(g:,'ECY_disable_for_files_larger_than_kb', 300000)
  endif

  let g:ECY_rolling_key_of_floating_windows
        \= get(g:,'ECY_rolling_key_of_floating_windows',['<C-h>', '<C-l>'])

  let g:ECY_log_msg = []
  let g:has_ultisnips_support = v:false

  if get(g:,'UltiSnipsExpandTrigger', "<tab>") == "<tab>" 
    let g:UltiSnipsExpandTrigger = "<F1>"
  endif

  let g:ECY_use_text_differ
        \= get(g:,'ECY_use_text_differ', v:false)
  if g:ECY_use_text_differ
    let g:has_text_prop_event = exists('*listener_add')
    if g:has_text_prop_event
      let g:ECY_server_cached_buffer     = []
      let g:ECY_buffer_need_to_update    = {}
      let g:ECY_cached_buffer_nr_to_path = {}
    endif
  endif

  let s:isSelecting          = v:false
  let s:completeopt_temp     = &completeopt
  let s:back_to_source_key   = get(s:,'back_to_source_key',['<Space>'])
  let s:completion_text_id   = 0
  let s:completeopt_fuc_temp = &completefunc

  " we suggest to use socket, because we the results of testing the job is 
  " too slow.
  let  s:is_using_stdio = v:false
  " if has('patch-8.1.0818')
  "   let  s:is_using_stdio = v:true
  " else
  "   " because there are bugs of job communication of vim before patch-8.1.0818
  "   let  s:is_using_stdio = v:false
  " endif
"}}}
endfunction

function! s:BackToLastSource(typing_key) abort
"{{{ and clear popup windows
  if exists('s:last_used_completor')
    let l:curren_file_type = s:last_used_completor['file_type']
    let g:ECY_file_type_info[l:curren_file_type]['filetype_using'] =
          \s:last_used_completor['source_name']
    unlet s:last_used_completor
    let g:ECY_file_type_info[l:curren_file_type]['special_position'] = {}
  endif
  if a:typing_key != -1
    call ECY#utility#SendKeys(a:typing_key)
    return ''
  endif
  if g:has_floating_windows_support == 'vim' && 
        \g:ECY_use_floating_windows_to_be_popup_windows == v:true
      " reset
      call ECY#color_completion#ClosePrompt()
      call ECY#utility#RecoverIndent()
      let s:isSelecting = v:false
  endif
"}}}
endfunction

function! s:SetUpPython() abort
"{{{
  if !s:is_using_stdio
    call ECY_main#Do("import os", v:false)
    let l:temp =  g:ECY_python_script_folder_path."/client"
    let l:temp = "sys.path.append('" . l:temp . "')"
    call ECY_main#Do(l:temp, v:false)
    call ECY_main#Do("import Main_client", v:false)
    call ECY_main#Do("ECY_Client_ = Main_client.ECY_Client()", v:false)

  else
    " TODO
    " don't need to use python as client.
  endif
"}}}
endfunction

function! ECY_main#CompleteFunc( findstart, base ) abort
"{{{
  if a:findstart
    return s:show_item_position
  endif
  return {'words': s:show_item_list}
"}}}
endfunction

function! s:ShowPopup(fliter_words,list_info) abort
"{{{
  if len(s:show_item_list) == 0
    " have no items to show
    return
  endif
  if g:has_floating_windows_support == 'vim' && 
        \g:ECY_use_floating_windows_to_be_popup_windows == v:true && 
        \g:ECY_PreviewWindows_style != 'preview_windows'
    call ECY#color_completion#ShowPrompt(a:list_info, a:fliter_words)
  else 
    " have no color
    let g:ECY_current_popup_windows_info = s:show_item_list
    call ECY#utility#SendKeys( "\<C-X>\<C-U>\<C-P>" )
  endif

"}}}
endfunction

function! s:YCMCompatible(is_YCM) abort
"{{{ switch to YCM or ECY
  if a:is_YCM
    set completefunc=youcompleteme#CompleteFunc
    set completeopt-=menu
    set completeopt+=menuone
    for key in g:ycm_key_list_select_completion
      " With this command, when the completion window is visible, the tab key
      " (default) will select the next candidate in the window. In vim, this also
      " changes the typed-in text to that of the candidate completion.
      exe 'inoremap <expr>' . key .
            \ ' pumvisible() ? "\<C-n>" : "\' . key .'"'
    endfor
    " tell ECY's server to save the setting
    call ECY_main#Do("OnBufferEnter", v:true)
  else
    call s:SetUpCompleteopt()
    call s:MappingSelection()
  endif
"}}}
endfunction

function! s:DefaultSourcesCheck(current_sources_list) abort
"{{{
  if !ECY_main#IsECYWorksAtCurrentBuffer()
    return
  endif
  " to make ECY more out of the box.
  " check if snippets is installed
  if g:has_ultisnips_support == v:true && !exists('g:ECY_is_installed_snippets')
    let l:is_has = v:false
    for item in a:current_sources_list
      " snippet work at all filetype, so it's ok to check at here
      if item == 'snippets'
        let l:is_has = v:true
        break
      endif
    endfor
    if l:is_has == v:false
      " only install once
      call ECY_main#Install('snippets')
    endif
    " only check once
    let g:ECY_is_installed_snippets = v:true
  endif

  if ECY#utility#HasYCM() && !exists('g:ECY_is_working_with_YCM')
    let l:is_has = v:false
    for item in a:current_sources_list
      if item == 'youcompleteme'
        let l:is_has = v:true
        break
      endif
    endfor
    if l:is_has == v:false
      " only install once
      call ECY_main#Install('youcompleteme')
    endif
    " only check once
    let g:ECY_is_working_with_YCM = v:true
  endif
"}}}
endfunction

function! s:GetCurrentBufferAvailableSources() abort
"{{{ will do something in callback.
  call ECY_main#Do("GetAvailableSources", v:true)
"}}}
endfunction

function! s:MappingSelection() abort
"{{{ Make mapping for ECY
  if g:ECY_use_floating_windows_to_be_popup_windows == v:false
    exe 'inoremap <expr>' . g:ECY_select_items[0] .
          \ ' pumvisible() ? "\<C-n>" : "\' . g:ECY_select_items[0] .'"'
    exe 'inoremap <expr>' . g:ECY_select_items[1] .
          \ ' pumvisible() ? "\<C-p>" : "\' . g:ECY_select_items[1] .'"'
  else
    exe 'inoremap <silent> ' . g:ECY_select_items[0].' <C-R>=ECY_main#SelectItems(0,"\' . g:ECY_select_items[0] . '")<CR>'
    exe 'inoremap <silent> ' . g:ECY_select_items[1].' <C-R>=ECY_main#SelectItems(1,"\' . g:ECY_select_items[1] . '")<CR>'
  endif
"}}}
endfunction

function! ECY_main#IsECYWorksAtCurrentBuffer() abort 
"{{{
"return v:false means not working.

  if ECY#utility#IsCurrentBufferBigFile()
    return v:false
  endif

  let l:current_source = ECY_main#GetCurrentUsingSourceName()
  if l:current_source == ''
    " ask the server to get available source, firstly
    call s:GetCurrentBufferAvailableSources()
    return v:false
  endif

  if ECY#utility#HasYCM() &&  l:current_source == 'youcompleteme'
    "if user have no ycm, so ecy will work at that file
    return v:false
  endif
  if l:current_source == 'disabled'
    return v:false
  endif
  return v:true
"}}}
endfunction

function! ECY_main#GetCurrentUsingSourceName() abort
"{{{
  let l:filetype = &filetype
  if l:filetype == ''
    let &filetype  = 'nothing'
    let l:filetype = 'nothing'
  endif
  if !exists("g:ECY_file_type_info[".string(l:filetype)."]")
    return ''
  endif
  return g:ECY_file_type_info[l:filetype]['filetype_using']
"}}}
endfunction

function! ECY_main#ChooseSource(file_type, next_or_pre) abort
"{{{ this will call by 'user_ui.vim'
  let l:filetype = &filetype
  if !exists("g:ECY_file_type_info[".string(l:filetype)."]")
    " server should init it first
    return
  endif
  let l:available_sources = g:ECY_file_type_info[l:filetype]['available_sources']
  let l:current_using     = g:ECY_file_type_info[l:filetype]['filetype_using']
  let l:available_sources_len = len(l:available_sources)
  let l:index             = 0
  for item in l:available_sources
    if l:current_using == item
      break 
    endif
    let l:index += 1
  endfor
  let l:choosing_source_index = 0

  if a:next_or_pre == 'next'
    let l:choosing_source_index = (l:index+1) % l:available_sources_len
  else
    let l:choosing_source_index = (l:index-1) % l:available_sources_len
  endif
  let l:choosing_source_index = l:available_sources[l:choosing_source_index]
  let g:ECY_file_type_info[l:filetype]['filetype_using'] = l:choosing_source_index
"}}}
endfunction

function! ECY_main#AfterUserChooseASource() abort
"{{{ a callback for pressing <ESC> at choosing sources or firstly get sources
" lists
  " order matters
  call ECY#diagnosis#CleanAllSignHighlight()
  call ECY#diagnosis#ClearAllSign()
  if ECY#utility#HasYCM()
    " according the user's settings to optionally complete.
    let l:filetype = &filetype
    if ECY_main#GetCurrentUsingSourceName() == 'youcompleteme'
      if exists('g:ycm_filetype_blacklist[l:filetype]')
        unlet g:ycm_filetype_blacklist[l:filetype]
      endif
      call s:YCMCompatible(v:true)
      doautocmd <nomodeline> youcompleteme BufEnter
      " Returning make YCM work, so we will not call ECY's event.
      return
    endif
    if !exists('g:ycm_filetype_blacklist[l:filetype]')
      let g:ycm_filetype_blacklist[l:filetype] = 1
      call s:YCMCompatible(v:false)
      " YCM are not available at current buffer, so we don't return
    endif
  endif
  doautocmd <nomodeline> EasyCompleteYou BufEnter
"}}}
endfunction

" callback{{{

function! s:ErroCode_cb(msg) abort
"{{{
  if a:msg['ErroCode'] != 1
    let l:engine_name = a:msg['EngineName']
    let l:temp = ['[ECY] [' . l:engine_name . ' - ' . a:msg['ErroCode'] ."]"]
    if type(a:msg['Description']) == 3
      " is a list
      call extend(l:temp, a:msg['Description'])
    else
      call add(l:temp, a:msg['Description'])
    endif
    call ECY#utility#ShowMsg(l:temp, 2)
  endif
"}}}
endfunction

function! s:SetFileTypeSource_cb(msg) abort
"{{{
  let g:ECY_file_type_info[a:msg['FileType']] = {}
  let l:available_sources = a:msg['Dicts']['available_sources']
  let g:ECY_file_type_info[a:msg['FileType']]['available_sources'] =
        \l:available_sources
  let g:ECY_file_type_info[a:msg['FileType']]['filetype_using']    =
        \a:msg['Dicts']['using_source']
  let g:ECY_file_type_info[a:msg['FileType']]['special_position']  =
        \{}
  " trigger events again.
  call ECY_main#AfterUserChooseASource()

  call s:DefaultSourcesCheck(l:available_sources)
"}}}
endfunction

function! s:CachedBufferList_cb(msg) abort
"{{{
  let g:ECY_server_cached_buffer = a:msg['Lists']
"}}}
endfunction

function! s:Restart_cb(msg) abort
"{{{
  call ECY#utility#ShowMsg("[ECY] restared :" . a:msg['EngineName'], 2)
  call ECY_main#AfterUserChooseASource()
"}}}
endfunction

function! s:Completion_cb(msg) abort
"{{{
  if ECY_main#GetVersionID() != a:msg['Version_ID'] || mode() != 'i'
    " stop a useless poll
    return
  endif

  " adjust source
  let s:show_item_name     = a:msg['EngineName']
  " let s:show_item_position = a:msg['StartPosition']['Colum']
  let s:show_item_position = strlen(a:msg['PreviousWords'])
  let l:temp = g:ECY_file_type_info[&filetype]['special_position']
  if l:temp != {}
    if l:temp['Line'] == (line('.') - 1)
      let s:show_item_position = l:temp['Colum']
    else
      call s:BackToLastSource(-1)
    endif
  endif

  " build a format of vim's completion items
  let g:ECY_completion_data = {}
  let s:show_item_list = []
  let l:results_list = a:msg['Lists']
  let l:i = 0
  while l:i < len(l:results_list)
    let l:temp = {}
    let l:item = l:results_list[l:i]

    let l:temp['abbr']      = l:item['abbr']
    let l:temp['word']      = l:item['word']
    let l:temp['kind']      = l:item['kind']
    let l:temp['user_data'] = string(l:i)
    let g:ECY_completion_data[string(l:i)] = l:item

    let l:results_list[l:i]['user_data'] = string(l:i)
    if g:has_floating_windows_support == 'has_no'
      try
        let l:temp['info'] = join(l:item['info'],"\n")
      catch
        let l:temp['info'] = ''
      endtry
      let l:temp['menu'] = l:item['menu']
    else
      let l:temp['info'] = ''
      let l:temp['menu'] = ''
    endif
    call add(s:show_item_list, l:temp)
    let l:i += 1
  endwhile

  " invoke
  call s:ShowPopup(a:msg['Filter_words'], l:results_list)
"}}}
endfunction

function! s:Integration_cb(msg) abort
"{{{

  if ECY_main#GetVersionID() != a:msg['ID'] || mode() == 'i'
    " stop a useless poll
    call ECY#utility#ShowMsg('[ECY] An event: '.a:msg['Integration_event'] .
          \' was abandoned. Trigger it again if you really want it.', 2)
    return
  endif
  let l:event = a:msg['Integration_event']
  if l:event == 'go_to_declaration_or_definition'
    call ECY#user_ui#CheckGoto(a:msg['Results'], &filetype)
  elseif l:event == 'GoToDefinition'
    " TODO
  elseif l:event == 'get_symbols' || l:event == 'get_workspace_symbols'
    call ECY#symbols#ReturingResults_cb(a:msg['Results'])
  elseif l:event == 'diagnostics'
    call ECY#diagnosis#PlaceSign(a:msg['Results'])
  endif
"}}}
endfunction

"}}}

function! ECY_main#GetVersionID() abort
"{{{ mainly for completion
  let l:temp = "ECY_Client_.GetCompletionVersionID_NotChanging()"
  return s:PythonEval(l:temp)
"}}}
endfunction

function! ECY_main#ChangeVersionID() abort
"{{{ mainly for completion
  let l:temp = "ECY_Client_.GetCompletionVersionID_Changing()"
  return s:PythonEval(l:temp)
"}}}
endfunction

function! ECY_main#GetDocumentVersionID() abort
"{{{ change while buffer had changes
  let l:temp = "ECY_Client_.GetDocumentVersionID_NotChanging()"
  return s:PythonEval(l:temp)
"}}}
endfunction

function! ECY_main#ChangeDocumentVersionID() abort
"{{{
  let l:temp = "ECY_Client_.GetDocumentVersionID_Changing()"
  return s:PythonEval(l:temp)
"}}}
endfunction

function! ECY_main#EventSort(id, data, event) abort
  "{{{ classify events.
  " a:data is a list that every item was divided into a decodable json
  " try
    for item in a:data
      if item == ''
        " an additional part when splitting line with '\n'
        continue
      endif
      let l:data_dict = json_decode(item)
      if exists("l:data_dict['ErroCode']")
        " the source have no process for this event
        call s:ErroCode_cb(l:data_dict)
        continue
      endif
      let l:Event = l:data_dict['Event']
      if l:Event == 'do_completion'
        call s:Completion_cb(l:data_dict)
      elseif l:Event == 'set_file_type_available_source'
        call s:SetFileTypeSource_cb(l:data_dict)
      elseif l:Event == 'integration'
        call s:Integration_cb(l:data_dict)
      elseif l:Event == 'install_source'
        call ECY#install#Install_cb(l:data_dict)
      elseif l:Event == 'diagnosis'
        call ECY#diagnosis#PlaceSign(l:data_dict)
      elseif l:Event == 'goto'
        call ECY#goto#Go_cb(l:data_dict)
      elseif l:Event == 'document_help'
        call ECY#document_help#cb(l:data_dict)
      elseif l:Event == 'all_engine_info'
        call timer_start(1, function('ECY#install#ListEngine_cb', [l:data_dict]))
      elseif l:Event == 'CachedBufferList'
        call s:CachedBufferList_cb(l:data_dict)
      elseif l:Event == 'restart'
        call s:Restart_cb(l:data_dict)
      endif
    endfor
  " catch
  " endtry

  "}}}
endfunction

function! ECY_main#SelectItems(next_or_pre, send_key) abort
"{{{ will only be trrigered when there are floating windows and
  " g:ECY_use_floating_windows_to_be_popup_windows is true in vim.
  " only for floating windows, every typing event will close the pre floating 
  " windows first, so it just need to create a new one diretly.
  " a:next_or_pre is 0 meaning next one

  if ECY#color_completion#IsPromptOpen()
    let s:isSelecting = v:true
    call ECY#utility#DisableIndent()

    " select it, then complete it into buffer
    call ECY#color_completion#SelectItems(a:next_or_pre,s:show_item_position)

    " a callback
    call s:OnSelectingMenu_vim()
  else
    call ECY#utility#SendKeys(a:send_key)
  endif
  return ''
"}}}
endfunction

function! ECY_main#ExpandSnippet() abort
"{{{ this function will not tirgger when there are no UltiSnips plugin.
  if ECY_main#IsECYWorksAtCurrentBuffer() && ECY#color_completion#IsPromptOpen() 
    " we can see that we require every item of completion must contain full
    " infos which is a dict with all key.
    if g:has_floating_windows_support == 'vim' && 
          \g:ECY_use_floating_windows_to_be_popup_windows == v:true
      let l:selecting_item_nr = 
            \g:ECY_current_popup_windows_info['selecting_item']
      if l:selecting_item_nr != 0
        let l:item_info = 
              \g:ECY_current_popup_windows_info['items_info'][l:selecting_item_nr - 1]
        let l:item_kind          = l:item_info['kind']
        let l:user_data_index    = l:item_info['user_data']
        let l:item_name_selected = l:item_info['word']
      endif
    else
      let l:item_kind          = v:completed_item['kind']
      let l:user_data_index    = v:completed_item['user_data']
      let l:item_name_selected = v:completed_item['word']
    endif
    " the user_data_index is a number that can index the g:ECY_completion_data which is
    " a dict to get more than just a string msg.
    try
      if l:user_data_index != ''
        " maybe, some item have no snippet. so we try.
        let l:snippet   = g:ECY_completion_data[l:user_data_index]['snippet']
        let g:abc = l:snippet
        call UltiSnips#Anon(l:snippet,l:item_name_selected,'have no desriction','w')
        return ''
      endif
    catch
    endtry
    try
      if l:item_kind == '[Snippet]'
        call UltiSnips#ExpandSnippet() 
        return ''
      endif
    catch
    endtry
  endif
  call ECY#utility#SendKeys(g:ECY_expand_snippets_key)
  return ''
"}}}
endfunction

function! s:SetMapping() abort
"{{{

  call s:MappingSelection()

  exe 'nmap ' . g:ECY_show_switching_source_popup .
        \ ' :call ECY#choose_sources#Start()<CR>'

  for key in g:ECY_choose_special_source_key
    exe 'inoremap <expr>' . key['invoke_key'] . 
          \' <SID>UsingSpecicalSource( "'.key['source_name'].'","\' . key['invoke_key'] . '",' . string(key['is_replace']) . ' )'
  endfor

  for key in s:back_to_source_key
    exe 'inoremap <expr>' . key . ' <SID>BackToLastSource( "\' . key . '" )'
  endfor

  if g:has_floating_windows_support != 'has_no'
    exe 'inoremap <expr>' . g:ECY_rolling_key_of_floating_windows[0] . ' ECY#utility#RollFloatingWindows(1)'
    exe 'inoremap <expr>' . g:ECY_rolling_key_of_floating_windows[1] . ' ECY#utility#RollFloatingWindows(-1)'
    exe 'nmap ' . g:ECY_rolling_key_of_floating_windows[0] . ' :call ECY#utility#RollFloatingWindows(1)<CR>'
    exe 'nmap ' . g:ECY_rolling_key_of_floating_windows[1] . ' :call ECY#utility#RollFloatingWindows(-1)<CR>'
  endif

"}}}
endfunction

function! s:StartCommunication() abort
"{{{
  let s:server_exe_path = g:ECY_python_script_folder_path . '/server/Main_server.py'
  let l:start_cmd = g:ECY_python3_cmd.' '.s:server_exe_path
  if !s:is_using_stdio
    " let s:HMAC_KEY = s:PythonEval("ECY_Client_.CreateHMACKey()")
    let s:HMAC_KEY = "1235"
    let s:port     = s:PythonEval("ECY_Client_.GetUnusedLocalhostPort()")
    let l:start_cmd = l:start_cmd . ' --hmac ' . s:HMAC_KEY . ' --port ' . s:port 
  endif
  if g:ECY_debug
    let l:start_cmd .= ' --debug_log'
  endif
  call ECY_main#Log(l:start_cmd)
  try
    let s:server_job_id = ECY#jobs#Create(l:start_cmd, {
        \ 'on_stdout': function('ECY_main#EventSort')
        \ })
    if !s:is_using_stdio
      call s:PythonEval("ECY_Client_.ConnectSocketServer()")
      call s:StartClient('')
      " if g:ECY_debug
      "   " this is a another socket server that inputed with socket
      "   call s:PythonEval("ECY_Client_.StartDebugServer()")
      " endif
    endif
  catch
    call ECY_main#Log("EasyCompletion unavailable: Can not start a necessary communication server of python.")
    call s:ShowErroAndFinish("[ECY] Can not start a necessary communication Server of python.")
  endtry
"}}}
endfunction

function! s:StartClient(timer_id) abort
"{{{
  if !exists('s:is_connected')
    let s:is_connected = 0
    call timer_start(1000, function('s:StartClient'))
  else
    if s:PythonEval('ECY_Client_.socket_connection.is_connected')
      call ECY_main#Log('Connected; Starting timer end.')
      return
    elseif s:is_connected == 5
      let l:temp = "[ECY] Can't connect a Server. Maybe this a bug."
      call ECY_main#Log(l:temp)
      call ECY#utility#ShowMsg(l:temp, 2)
      return
    endif
    let s:is_connected += 1
    call s:PythonEval("ECY_Client_.socket_connection.ConnectSocket()")
    call timer_start(1000, function('s:StartClient'))
  endif
"}}}
endfunction

function! s:ShowErroAndFinish(msg) abort
"{{{
  echohl WarningMsg |
        \ echomsg a:msg |
        \ echohl None
  call s:restore_cpo()
  finish
"}}}
endfunction

function! ECY_main#Log(msg) abort
"{{{
  try
    let g:ECY_log_msg = string(a:msg)
    call s:PythonEval("ECY_Client_.Log()")
  catch 
  endtry
"}}}
endfunction

function! ECY_main#Uninstall(name) abort
"{{{ TODO
"}}}
endfunction

function! ECY_main#Install(name) abort
"{{{
"check source's requires
  if !exists("g:ECY_available_engine_installer[a:name]")
    call ECY#utility#ShowMsg('[ECY] have no "'.a:name.'" support.', 3)
    return
  endif
  let l:Fuc = g:ECY_available_engine_installer[a:name]
  if l:Fuc == ''
    call ECY#utility#ShowMsg('[ECY] This is buildin engine. You already installed it.', 3)
    return
  endif

  let l:install_return = l:Fuc()
  if l:install_return['status'] == 0
    " refleshing all the running completor to make new completor work at every
    " where.
    call ECY#utility#ShowMsg('[ECY] checked the requires of "'.a:name.'" successfully.', 3)
  else
    "failed while check.
    call ECY#utility#ShowMsg(l:install_return['description'], 3)
    return
  endif

  let l:engine_info = g:ECY_server_info[a:name]
  let g:ecy_source_name_2_install = {'EngineLib': l:engine_info['lib'],
        \'EnginePath': l:engine_info['path'],
        \'EngineName': a:name}
  call ECY_main#Do("InstallSource", v:true)
  " call ECY#utility#ShowMsg('[ECY] installing "'.l:engine_name.'".', 3)
"}}}
endfunction

function! ECY_main#Do(cmd, is_event) abort
"{{{ask the server to do something with python3
if a:is_event
  if s:is_using_stdio
    " stdio is under TODO
    let l:Fuc  = function('genernal' . '#'. a:cmd)
    let l:temp = l:Fuc()
    let l:temp = "{'Method': 'receive_all_msg','Msg':".l:temp."}\n"
    call ECY#job#ECY_Send(s:server_job_id, l:temp)
  else
    let l:temp = "ECY_Client_.Exe('" . a:cmd . "')"
    call s:PythonEval(l:temp)
  endif
else
  exe "py3 " . a:cmd
endif
"}}}
endfunction

function! ECY_main#Execute(event) abort
"{{{
  let g:ECY_do_something_event = a:event
  call ECY_main#Do("Integration", v:true)
"}}}
endfunction

function! ECY_main#Check() abort
"{{{
  if exists('g:loaded_easycomplete') && g:loaded_easycomplete == v:true
    return v:true
  endif
  return v:false
"}}}
endfunction

function! ECY_main#Start() abort
  call s:SetVariable()
  call s:SetUpPython()
  call s:SetUpEvent()
  call s:StartCommunication()
  call s:SetMapping()
endfunction
