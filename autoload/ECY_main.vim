" Author: Jimmy Huang (1902161621@qq.com)
" License: WTFPL
" Log:
" 2020-01-30 03:14  Happy birthday to me.
" 2020-02-02 22:25  Happy 2020-0202.

" must put these outside a function
let  s:python_script_folder_path = expand( '<sfile>:p:h:h' ).'/python'
let  s:python_script_folder_path = tr(s:python_script_folder_path, '\', '/')
  
function! s:SetUpEvent() abort
"{{{
  augroup EasyCompleteYou
    autocmd!
    autocmd FileType      * call s:OnBufferEnter()
    autocmd BufEnter      * call s:OnBufferEnter()
    autocmd BufLeave      * call s:OnBufferLeave()
    autocmd InsertLeave   * call s:OnInsertModeLeave()
    autocmd TextChanged   * call s:OnTextChangedNormalMode()
    autocmd VimLeavePre   * call s:OnVIMLeave()

    " invoked after typing a character into the buffer or user sept in insert mode  
    autocmd InsertEnter   * call s:OnInsertMode()
    autocmd TextChangedI  * call s:OnTextChangedInsertMode()
    autocmd InsertCharPre * call s:OnInsertChar()

    if g:has_floating_windows_support == 'vim'
      if g:ECY_use_floating_windows_to_be_popup_windows != v:true
        " has floating windows, but user don't want to use it to be popup window
        autocmd CompleteChanged * call s:OnSelectingMenu()
      endif
    elseif g:has_floating_windows_support == 'neovim'
      " neovim
      " TODO
    endif
  augroup END
"}}}
endfunction

function! s:OnSelectingMenu() abort 
"{{{ 
  try
    call completion_preview_windows#Close()
    if g:ECY_use_floating_windows_to_be_popup_windows == v:true 
          \&& g:has_floating_windows_support == 'vim'
      let l:item_index = g:ECY_current_popup_windows_info['selecting_item']
      if l:item_index == 0
        return
      endif
      let l:item_index -= 1
    else
      " v:completed_item could be none, so we try it.
      let l:item_index  = v:completed_item['user_data']
    endif
    call completion_preview_windows#Show(s:user_data[l:item_index],&filetype)
  catch
  endtry
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
  call s:AskDiagnosis('OnTextChangedNormalMode')
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
  "}}}
endfunction

function! s:OnInsertModeLeave() abort 
  "{{{
  if !ECY_main#IsECYWorksAtCurrentBuffer()
    return
  endif
  " order matters
  call s:BackToLastSource(-1)
  call s:AskDiagnosis('OnInsertModeLeave')
  call completion_preview_windows#Close()
  "}}}
endfunction

function! s:OnBufferEnter() abort 
  "{{{
  if !ECY_main#IsECYWorksAtCurrentBuffer()
    return
  endif
  let  s:indentexpr           = &indentexpr
  let  s:completeopt_temp     = &completeopt
  let  s:completeopt_fuc_temp = &completefunc
  let  s:buffer_has_changed   = 0
  call diagnosis#CleanAllSignHighlight()
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
  call s:AskDiagnosis('OnTextChangedInsertMode')
  call s:DoCompletion()
  "}}}
endfunction

" ==============================================================================
function! s:AskDiagnosis(event) abort 
"{{{
  if g:ECY_disable_diagnosis
    return
  endif
  if a:event == 'OnTextChangedInsertMode' || a:event == 'OnTextChangedNormalMode'
    call diagnosis#CleanAllSignHighlight()
    let s:buffer_has_changed = 1
  endif
  if a:event == 'OnInsertModeLeave' && s:buffer_has_changed == 1
    call diagnosis#UnPlaceAllSignInBufferName(utility#GetCurrentBufferPath())
    let s:buffer_has_changed = 0
  endif
  if a:event == 'OnInsertModeLeave' || a:event == 'OnTextChangedNormalMode'
    call ECY_main#Do("Diagnosis", v:true)
  endif
"}}}
endfunction

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
"{{{
  if g:has_floating_windows_support == 'vim' && 
        \g:ECY_use_floating_windows_to_be_popup_windows == v:true
    if s:isSelecting
      let s:isSelecting = v:false
      " this is necessary, because we don't trigger server to complete when we
      " are selecting.
      return
    endif
    " reflesh it when user typing key into buffer.
    call completion_preview_windows#Close()
    let &indentexpr = s:indentexpr
    call color_completion#ClosePrompt()
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
    call utility#SendKeys( "\<C-e>" )
  endif
"}}}
endfunction

function! s:PythonEval(eval_string) abort
"{{{
  return py3eval( a:eval_string )
"}}}
endfunction

function! s:GetCurrentPosition() abort
"{{{
    return { 'Line': line('.') - 1, 'Colum': col('.') -1 }
"}}}
endfunction

function! s:UsingSpecicalSource(completor_name,invoke_key, is_replace) abort
"{{{
  if ECY_main#IsECYWorksAtCurrentBuffer()
    let l:curren_file_type = &filetype
    let l:temp = g:ECY_file_type_info[l:curren_file_type]['filetype_using']
    if !exists('s:last_used_completor') 
          \|| a:completor_name != l:temp
      let s:last_used_completor                = {}
      let s:last_used_completor['source_name'] = l:temp
      let s:last_used_completor['file_type']   = l:curren_file_type
    endif
    for item in g:ECY_file_type_info[l:curren_file_type]['available_sources']
      if item == a:completor_name
        let g:ECY_file_type_info[l:curren_file_type]['filetype_using']
              \ = a:completor_name
        if a:is_replace
          let g:ECY_file_type_info[l:curren_file_type]['special_position'] = 
                \s:GetCurrentPosition()
        else
          let g:ECY_file_type_info[l:curren_file_type]['special_position'] = {}
        endif
      endif
    endfor
  endif
  call utility#SendKeys(a:invoke_key)
  return ''
"}}}
endfunction

function! s:SetVariable() abort
"{{{ 

  " this debug option will start another server with socket port 1234 and
  " HMAC_KEY 1234, and output logging to file where server dir is. 
  let g:ECY_debug
        \= get(g:, 'ECY_debug', v:true)

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
        \{'source_name':'path','invoke_key':'/', 'is_replace': v:false},
        \{'source_name':'label','invoke_key':'^', 'is_replace': v:true}])

  let g:ECY_python3_cmd                               
        \= get(g:,'ECY_python3_cmd','python')

  let g:ECY_file_type_info
        \= get(g:,'ECY_file_type_info',{})

  let g:ycm_autoclose_preview_window_after_completion
        \= get(g:,'ycm_autoclose_preview_window_after_completion',v:true)

  let g:ECY_triggering_length
        \= get(g:,'ECY_triggering_length',1)

  if exists('g:ycm_disable_for_files_larger_than_kb')
    let g:ECY_disable_for_files_larger_than_kb = g:ycm_disable_for_files_larger_than_kb
  else
    let g:ECY_disable_for_files_larger_than_kb
          \= get(g:,'ECY_disable_for_files_larger_than_kb',1000)
  endif

  " 1 means ask diagnosis when there are changes not including user in insert mode
  " 2 means ask diagnosis when there are changes including user in insert mode
  let g:ECY_update_diagnosis_mode
        \= get(g:,'ECY_update_diagnosis_mode',2)
  if g:ECY_update_diagnosis_mode == 2
    let g:ECY_update_diagnosis_mode = v:true
  else
    let g:ECY_update_diagnosis_mode = v:false
  endif

  let g:ECY_rolling_key_of_floating_windows
        \= get(g:,'ECY_rolling_key_of_floating_windows',['<C-h>', '<C-l>'])

  let g:ECY_disable_diagnosis
        \= get(g:,'ECY_disable_diagnosis', v:false)

  let g:ECY_log_msg = []

  " we put this at here to accelarate the starting time
  try
    call UltiSnips#SnippetsInCurrentScope(1)
    let g:has_ultisnips_support = v:true
    call ECY_main#Log('has UltiSnips')
  catch
    let g:has_ultisnips_support = v:false
    call ECY_main#Log('has no UltiSnips')
  endtry

  let  s:isSelecting          = v:false
  let  s:indentexpr           = &indentexpr
  let  s:completeopt_temp     = &completeopt
  let  s:completeopt_fuc_temp = &completefunc
  let  s:back_to_source_key   = get(s:,'back_to_source_key',['<Space>'])
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
    call utility#SendKeys(a:typing_key)
    return ''
  endif
  if g:has_floating_windows_support == 'vim' && 
        \g:ECY_use_floating_windows_to_be_popup_windows == v:true
      " reset
      call color_completion#ClosePrompt()
      let &indentexpr = s:indentexpr
      let s:isSelecting = v:false
  endif
"}}}
endfunction

function! s:SetUpPython() abort
"{{{
  if !s:is_using_stdio
    call ECY_main#Do("import os", v:false)
    let l:temp =  s:python_script_folder_path."/client"
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
        \g:ECY_use_floating_windows_to_be_popup_windows == v:true
    call color_completion#ShowPrompt(a:list_info, a:fliter_words)
  else 
    " have no color
    call utility#SendKeys( "\<C-X>\<C-U>\<C-P>" )
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
        if g:UltiSnipsExpandTrigger == g:ECY_select_items[0]
          let g:UltiSnipsExpandTrigger = '<F1>'
        endif
        break
      endif
    endfor
    if l:is_has == v:false
      " only install once
      call ECY_main#Install('Snippets')
    endif
    " only check once
    let g:ECY_is_installed_snippets = v:true
  endif

  if utility#HasYCM() && !exists('g:ECY_is_working_with_YCM')
    let l:is_has = v:false
    for item in a:current_sources_list
      if item == 'youcompleteme'
        let l:is_has = v:true
        break
      endif
    endfor
    if l:is_has == v:false
      " only install once
      call ECY_main#Install('YCM')
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
  if g:has_floating_windows_support == 'has_no' || 
        \g:ECY_use_floating_windows_to_be_popup_windows == v:false
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

  if utility#IsCurrentBufferBigFile()
    return v:false
  endif

  let l:current_source = ECY_main#GetCurrentUsingSourceName()
  if l:current_source == ''
    " ask the server to get available source, firstly
    call s:GetCurrentBufferAvailableSources()
    return v:false
  endif

  if utility#HasYCM() &&  l:current_source == 'youcompleteme'
    "if user have no ycm, so ecy will work at that file
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
  call diagnosis#CleanAllSignHighlight()
  call diagnosis#UnPlaceAllSignInBufferName(utility#GetCurrentBufferPath())
  if utility#HasYCM()
    " according the user's settings to optionally complete.
    let l:filetype = &filetype
    if ECY_main#GetCurrentUsingSourceName() == 'youcompleteme'
      if exists('g:ycm_filetype_blacklist[l:filetype]')
        unlet g:ycm_filetype_blacklist[l:filetype]
      endif
      call s:YCMCompatible(v:true)
      doautocmd <nomodeline> youcompleteme BufEnter
      " will not call ECY's Event
      return
    endif
    if !exists('g:ycm_filetype_blacklist[l:filetype]')
      let g:ycm_filetype_blacklist[l:filetype] = 1
      call s:YCMCompatible(v:false)
      " available at current buffer, so we don't return
    endif
  endif
  " exe "do BufEnter EasyCompleteYou"
  doautocmd <nomodeline> EasyCompleteYou BufEnter
"}}}
endfunction

" callback{{{

function! s:ErroCode_cb(msg) abort
"{{{
  try
    if a:msg['ErroCode'] != 1
      call utility#ShowMsg('[ECY] [' . ECY_main#GetCurrentUsingSourceName() . ' - ' . a:msg['ErroCode'] ."] " . ' ' .a:msg['Description'], 2)
    endif
  catch
  endtry
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
  " trigger events again
  call ECY_main#AfterUserChooseASource()

  call s:DefaultSourcesCheck(l:available_sources)
"}}}
endfunction

function! s:Completion_cb(msg) abort
"{{{
  if ECY_main#GetVersionID() != a:msg['Version_ID'] || mode() != 'i'
    " stop a useless poll
    return
  endif

  " adjust source
  let s:show_item_name     = a:msg['Server_name']
  let s:show_item_position = a:msg['StartPosition']['Colum']
  let l:temp = g:ECY_file_type_info[&filetype]['special_position']
  if l:temp != {}
    if l:temp['Line'] == (line('.')-1)
      let s:show_item_position = l:temp['Colum']
    else
      call s:BackToLastSource(-1)
    endif
  endif

  " build a format of vim's completion items
  let s:user_data = {}
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
    let s:user_data[string(l:i)] = l:item

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
    call add(s:show_item_list,l:temp)
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
    call utility#ShowMsg('[ECY] An event: '.a:msg['Integration_event'] .
          \' was abandoned. Trigger it again if you really want it.', 2)
    return
  endif
  let l:event = a:msg['Integration_event']
  if l:event == 'go_to_declaration_or_definition'
    call user_ui#CheckGoto(a:msg['Results'],&filetype)
  elseif l:event == 'GoToDefinition'
    " TODO
  elseif l:event == 'get_symbols'
    call symbols#ReturingResults_cb(a:msg['Results'])
  elseif l:event == 'diagnostics'
    call diagnosis#PlaceSign(a:msg['Results'])
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

function! s:EventSort(id, data, event) abort
  "{{{ classify events.
  " a:data is a list that every item was divided into a decodable json
  " try
    call ECY_main#Log("<---" . string(a:data))
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
        call ECY_Install#Install_cb(l:data_dict)
      elseif l:Event == 'diagnosis'
        call diagnosis#PlaceSign(l:data_dict)
      elseif l:Event == 'goto'
        call goto#Go_cb(l:data_dict)
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

  if color_completion#IsPromptOpen()
    let s:isSelecting = v:true
    let &indentexpr = ''

    " select it, then complete it into buffer
    call color_completion#SelectItems(a:next_or_pre,s:show_item_position)

    " a callback
    call s:OnSelectingMenu()
  else
    call utility#SendKeys(a:send_key)
  endif
  return ''
"}}}
endfunction

function! s:ExpandSnippet() abort
"{{{ this function will not tirgger when there are no UltiSnips plugin.
  if ECY_main#IsECYWorksAtCurrentBuffer() && color_completion#IsPromptOpen() 
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
    " the user_data_index is a number that can index the s:user_data which is
    " a dict to get more than just a string msg.
    try
      if l:user_data_index != ''
        " maybe, some item have no snippet. so we try.
        let l:snippet   = s:user_data[l:user_data_index]['snippet']
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
  call utility#SendKeys(g:ECY_expand_snippets_key)
  return ''
"}}}
endfunction

function! s:SetMapping() abort
"{{{

  call s:MappingSelection()

  exe 'nmap ' . g:ECY_show_switching_source_popup .
        \ ' :call choose_sources#Start()<CR>'

  if g:has_ultisnips_support
  " UltiSnips' API must be called in <C-R>
    exe 'inoremap ' . g:ECY_expand_snippets_key.
        \ ' <C-R>=<SID>ExpandSnippet()<CR>'
    exe 'let g:ECY_expand_snippets_key = "\'.g:ECY_expand_snippets_key.'"'
  endif

  for key in g:ECY_choose_special_source_key
    exe 'inoremap <expr>' . key['invoke_key'] . 
          \' <SID>UsingSpecicalSource( "'.key['source_name'].'","\' . key['invoke_key'] . '",' . string(key['is_replace']) . ' )'
  endfor

  for key in s:back_to_source_key
    exe 'inoremap <expr>' . key . ' <SID>BackToLastSource( "\' . key . '" )'
  endfor

  if g:has_floating_windows_support != 'has_no'
    exe 'inoremap <expr>' . g:ECY_rolling_key_of_floating_windows[0] . ' completion_preview_windows#Roll(1)'
    exe 'inoremap <expr>' . g:ECY_rolling_key_of_floating_windows[1] . ' completion_preview_windows#Roll(-1)'
  endif

"}}}
endfunction

function! s:StartCommunication() abort
"{{{
  let s:server_exe_path = s:python_script_folder_path.'/server/Main_server.py'
  let l:start_cmd = g:ECY_python3_cmd.' '.s:server_exe_path
  if !s:is_using_stdio
    let s:HMAC_KEY = s:PythonEval("ECY_Client_.CreateHMACKey()")
    let s:port     = s:PythonEval("ECY_Client_.GetUnusedLocalhostPort()")
    " enable 'input with socket', yet to enable 'output with socket'
    " let l:start_cmd = 
    "       \l:start_cmd.' --input_with_socket --hmac '.s:HMAC_KEY.' --port '.s:port
    let l:start_cmd = l:start_cmd . ' --hmac ' . s:HMAC_KEY . ' --port ' . s:port 
  endif
  if g:ECY_debug
    let l:start_cmd .= ' --debug_log'
  endif

  try
    let s:server_job_id = job#ECY_Start(l:start_cmd, {
        \ 'on_stdout': function('s:EventSort')
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
    call s:ShowErroAndFinish("EasyCompletion unavailable: Can not start a necessary communication server of python.")
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
      return
    elseif s:is_connected == 3
      call utility#ShowMsg("can't connect a Server. Maybe this a bug.", 2)
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
  let l:name = 'ECY_Install#'.a:name
  try
    let l:install_return = function(l:name)()
  catch
    call utility#ShowMsg('[ECY] have no "'.a:name.'" supported.', 3)
    return 
  endtry
  if l:install_return['status'] == 0
    " refleshing all the running completor to make new completor work at every
    " where.
    call utility#ShowMsg('[ECY] checked the requires of "'.l:install_return['name'].'" successfully.', 3)
  else
    "failed while check.
    call utility#ShowMsg(l:install_return['description'], 3)
    return
  endif
  let g:ecy_source_name_2_install = l:install_return['lib']
  call ECY_main#Do("InstallSource", v:true)
  call utility#ShowMsg('[ECY] installing "'.l:install_return['name'].'".', 3)
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
    call job#ECY_Send(s:server_job_id, l:temp)
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

function! ECY_main#Start() abort
  call s:SetVariable()
  call s:SetUpPython()
  call s:SetUpEvent()
  call s:StartCommunication()
  call s:SetMapping()
endfunction
