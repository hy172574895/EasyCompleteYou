
" must put these outside a function
let  s:python_script_folder_path = expand( '<sfile>:p:h:h' ).'\python'
let  s:python_script_folder_path = escape( s:python_script_folder_path, '\' )

function! s:SetUpEvent() abort
"{{{
  augroup EasyCompleteYou
    autocmd!
    autocmd FileType      * call s:OnBufferEnter()
    autocmd BufEnter      * call s:OnBufferEnter()
    autocmd BufLeave      * call s:OnBufferLeave()
    autocmd InsertLeave   * call s:OnInsertModeLeave()
    autocmd TextChanged   * call s:OnTextChangedNormalMode()

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
  "{{{ won't be triggered when it has no floating windows support
  try
    call user_ui#ClosePreviewWindows()
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
    call user_ui#PreviewWindows(s:user_data[l:item_index],&filetype)
  catch
  endtry
  "}}}
endfunction

function! s:OnBufferLeave() abort 
  "{{{
  call s:Back2LastSource(-1)
  "}}}
endfunction

function! s:OnTextChangedNormalMode() abort 
  "{{{
  if !ECY_main#IsECYWorksAtCurrentBuffer()
    return
  endif
  call s:DoCompletion()
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

function! s:OnInsertModeLeave() abort 
  "{{{
  if !ECY_main#IsECYWorksAtCurrentBuffer()
    return
  endif
  call s:Back2LastSource(-1)
  call user_ui#ClosePreviewWindows()
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

  " can't format here:
  if g:has_floating_windows_support == 'vim' && 
        \g:ECY_use_floating_windows_to_be_popup_windows == v:true
    set completeopt-=menuone
    set completeopt+=menu
  else
    set completeopt-=menu
    set completeopt+=menuone
  endif
  set shortmess+=c
  set completefunc=ECY_main#CompleteFunc

  call s:Do("OnBufferEnter", v:true)

  "}}}
endfunction

function! s:OnTextChangedInsertMode() abort 
  "{{{ invoke pop menu
  if !ECY_main#IsECYWorksAtCurrentBuffer()
    return
  endif
  call s:DoCompletion()
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
    call user_ui#ClosePreviewWindows()
    let &indentexpr = s:indentexpr
    call user_ui#CloseCompletionPopup()
  endif
  call s:Do("DoCompletion", v:true)
"}}}
endfunction

function! s:OnInsertChar() abort
"{{{
  if !ECY_main#IsECYWorksAtCurrentBuffer()
    return
  endif
  if pumvisible()
    call s:SendKeys( "\<C-e>" )
  endif
"}}}
endfunction

function! s:SendKeys(keys) abort
"{{{
  call feedkeys( a:keys, 'in' )
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
    let g:abc = s:last_used_completor
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
  call s:SendKeys(a:invoke_key)
  return ''
"}}}
endfunction

function! s:SetVariable() abort
"{{{ 

  " this debug option will start another server with socket port 1234 and
  " HMAC_KEY 1234, and output logging to file where server dir is. 
  let g:ECY_debug
        \= get(g:, 'ECY_debug',0)

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
        \[{'source_name':'snippets','invoke_key':'~','is_replace': v:true},
        \{'source_name':'path','invoke_key':'/','is_replace': v:false},
        \{'source_name':'label','invoke_key':'!','is_replace': v:true}])

  let g:ECY_python3_cmd                               
        \= get(g:,'ECY_python3_cmd','python')

  let g:ECY_file_type_info
        \= get(g:,'ECY_file_type_info',{})

  let g:ycm_autoclose_preview_window_after_completion
        \= get(g:,'ycm_autoclose_preview_window_after_completion',1)

  let g:ECY_working_setting
        \= get(g:,'ECY_working_setting',
        \{'vim':'ecy','html':'ecy','css':'ecy','xhtml':'ecy','php':'ecy',
        \'md':'ecy'})

  let s:back_to_source_key
        \= get(s:,'back_to_source_key',['<Space>'])

  let g:ECY_event_and_trigger_key
        \= get(g:,'ECY_event_and_trigger_key',{'<Space>':function('s:Back2LastSource')})

  let g:ECY_triggering_length
        \= get(g:,'ECY_triggering_length',1)

  " we put this at here to accelarate the starting time
  try
    call UltiSnips#SnippetsInCurrentScope(1)
    let g:has_ultisnips_support = v:true
  catch
    let g:has_ultisnips_support = v:false
  endtry

  let  s:isSelecting          = v:false
  let  s:indentexpr           = &indentexpr
  let  s:completeopt_temp     = &completeopt
  let  s:completeopt_fuc_temp = &completefunc
  " if has('patch-8.1.0818')
  "   let  s:is_using_stdio = v:true
  " else
  "   " because there are bugs of job communication of vim before patch-8.1.0818
  "   let  s:is_using_stdio = v:false
  " endif
  " we suggest to use socket, because we the results of testing the job is 
  " too slow.
  let  s:is_using_stdio = v:false
  " let  s:is_using_stdio = v:true
"}}}
endfunction

function! s:Back2LastSource(typing_key) abort
"{{{ and clear popup windows
  if exists('s:last_used_completor')
    let l:curren_file_type = s:last_used_completor['file_type']
    let g:ECY_file_type_info[l:curren_file_type]['filetype_using']=
          \s:last_used_completor['source_name']
    unlet s:last_used_completor
    let g:ECY_file_type_info[l:curren_file_type]['special_position'] = {}
  endif
  if a:typing_key != -1
    call s:SendKeys(a:typing_key)
    return ''
  endif
  if g:has_floating_windows_support == 'vim' && 
        \g:ECY_use_floating_windows_to_be_popup_windows == v:true
      " reset
      call user_ui#CloseCompletionPopup()
      let &indentexpr = s:indentexpr
      let s:isSelecting = v:false
  endif
"}}}
endfunction

function! s:SetUpPython() abort
"{{{
  if !s:is_using_stdio
    call s:Do("import os", v:false)
    let l:temp =  s:python_script_folder_path."/client"
    let l:temp = "sys.path.append('" . l:temp . "')"
    call s:Do(l:temp, v:false)
    call s:Do("import Main_client", v:false)
    call s:Do("ECY_Client_ = Main_client.ECY_Client()", v:false)
  else
    " TODO
    " don't need to use python
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
    call user_ui#Completion(a:list_info, a:fliter_words)
  else 
    call s:SendKeys( "\<C-X>\<C-U>\<C-P>" )
  endif

"}}}
endfunction

function! ECY_main#IsECYWorksAtCurrentBuffer() abort 
  "{{{
  "if user have no ycm, so ecy will work at every file
  "return 0 means not working.
  if exists('g:loaded_youcompleteme')
    if g:loaded_youcompleteme != 1
      return 1
    endif
  else
    return 1
  endif

  " accordding the user's settings to optionally complete.
  let l:filetype = &filetype
  if has_key(g:ECY_working_setting,l:filetype)
    if g:ECY_working_setting[l:filetype]=='' || 
          \g:ECY_working_setting[l:filetype]!='ycm'
      let g:ycm_filetype_blacklist[l:filetype]=1
      return 1
    endif
  endif
  return 0
  "}}}
endfunction

function! ECY_main#GetCurrentUsingSourceName() abort
"{{{
  if !exists("g:ECY_file_type_info[".string(&filetype)."]")
    return ''
  endif
  return g:ECY_file_type_info[&filetype]['filetype_using']
"}}}
endfunction

function! ECY_main#ChooseSource(file_type,next_or_pre) abort
"{{{
  if !exists("g:ECY_file_type_info[".string(&filetype)."]")
    " server should init it first
    return
  endif
  let l:available_sources = g:ECY_file_type_info[&filetype]['available_sources']
  let l:current_using     = g:ECY_file_type_info[&filetype]['filetype_using']
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
    let l:choosing_source_index=(l:index+1)%l:available_sources_len
  else
    let l:choosing_source_index=(l:index-1)%l:available_sources_len
  endif
  let l:choosing_source_index = l:available_sources[l:choosing_source_index]
  let g:ECY_file_type_info[&filetype]['filetype_using'] = l:choosing_source_index
"}}}
endfunction

" callback{{{

function! s:ErroCode_cb(msg) abort
"{{{
  try
    if a:msg['ErroCode'] != 1
      echo '[ECY] ' . ECY_main#GetCurrentUsingSourceName() . ', ' .a:msg['Event'] . ' ' .a:msg['Description']
    endif
  endtry
"}}}
endfunction

function! s:SetFileTypeSource_cb(msg) abort
"{{{
  let g:ECY_file_type_info[a:msg['FileType']] = {}
  let g:ECY_file_type_info[a:msg['FileType']]['available_sources'] = 
        \a:msg['Dicts']['available_sources']
  let g:ECY_file_type_info[a:msg['FileType']]['filetype_using'] = 
        \a:msg['Dicts']['using_source']
  let g:ECY_file_type_info[a:msg['FileType']]['special_position'] = 
        \{}

"}}}
endfunction

function! s:Completion_cb(msg) abort
"{{{
  if ECY_main#GetVersionID() != a:msg['Version_ID'] 
        \ || mode()!='i'
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
      call s:Back2LastSource(-1)
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

  " evoke
  call s:ShowPopup(a:msg['Filter_words'], l:results_list)
"}}}
endfunction

function! ECY_main#GetVersionID() abort
  let l:temp = "ECY_Client_.GetVersionID_NotChange()"
  return s:PythonEval(l:temp)
endfunction

function! s:Integration_cb(msg) abort
"{{{

  if ECY_main#GetVersionID() != a:msg['ID'] 
        \|| mode() == 'i'
    " stop a useless poll
    echo '[ECY] An event: '.a:msg['Integration_event'] .
          \' was abandoned. Trigger it again if you really want it.'
    return
  endif
  let l:event = a:msg['Integration_event']
  if l:event == 'go_to_declaration_or_definition'
    call user_ui#CheckGoto(a:msg['Results'],&filetype)
  elseif l:event == 'GoToDefinition'
    " TODO
  elseif l:event == 'get_symbols'
    call user_ui#Search(a:msg['Results'])
  elseif l:event == 'Diagnostics'
    " if there are ale, we should make it not working, because ale will do the 
    " repeat works thar ECY had done.
    let l:curren_file_type = &filetype
    let g:ale_filetype_blacklist = get(g:, 'ale_filetype_blacklist', [])
    call add(g:ale_filetype_blacklist,l:curren_file_type)
  endif
"}}}
endfunction

"}}}

function! s:EventSort(id, data, event) abort
  "{{{ classify events.
  " a:data is a list that every item was divided into a decodable json
  " try
    for item in a:data
      if item == ''
        " an additional part when splitting line with '\n'
        return
      endif
      let l:data_dict = json_decode(item)
      if exists("l:data_dict['ErroCode']")
        " the source have no process for this event
        call s:ErroCode_cb(l:data_dict)
        return 
      endif
      let l:Event     = l:data_dict['Event']
      if l:Event == 'do_completion'
        call s:Completion_cb(l:data_dict)
      elseif l:Event == 'set_file_type_available_source'
        call s:SetFileTypeSource_cb(l:data_dict)
      elseif l:Event == 'integration'
        call s:Integration_cb(l:data_dict)
      elseif l:Event == 'install_source'
        redraw
        echo '[ECY] ' . l:data_dict['Description']
      endif
    endfor
  " catch
  " endtry

  "}}}
endfunction

function! ECY_main#SelectItems(next_or_pre) abort
"{{{ will only be trrigered when there are floating windows and
  " g:ECY_use_floating_windows_to_be_popup_windows is true in vim.
  " only for floating windows, every typing event will close the pre floating 
  " windows first, so it just need to create a new one diretly.
  " a:next_or_pre is 0 meaning next one

  if user_ui#IsCompletionPopupWindowsOpen()
    let s:isSelecting = v:true
    let &indentexpr = ''

    " select it, then complete it into buffer
    call user_ui#SelectCompletionItems(a:next_or_pre,s:show_item_position)

    " a callback
    call s:OnSelectingMenu()
  else
    call s:SendKeys(g:ECY_select_items[a:next_or_pre])
  endif
  return ''
"}}}
endfunction

function! s:ExpandSnippet() abort
"{{{
  if ECY_main#IsECYWorksAtCurrentBuffer() && user_ui#IsCompletionPopupWindowsOpen() 
    " we can see that we require every item of completion must contain full
    " infos which is a dict with all key.
    if g:has_floating_windows_support == 'vim' && 
          \g:ECY_use_floating_windows_to_be_popup_windows == v:true
      let l:selecting_item_nr = 
            \g:ECY_current_popup_windows_info['selecting_item']
      if l:selecting_item_nr == 0
        return ''
      endif
      let l:item_info = 
            \g:ECY_current_popup_windows_info['items_info'][l:selecting_item_nr - 1]
      let l:item_kind          = l:item_info['kind']
      let l:user_data_index    = l:item_info['user_data']
      let l:item_name_selected = l:item_info['word']
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
    if l:item_kind == '[Snippet]'
      call UltiSnips#ExpandSnippet() 
      return ''
    endif
  endif
  call s:SendKeys(g:ECY_expand_snippets_key)
  return ''
"}}}
endfunction

function! s:SetMapping() abort
"{{{
  if g:has_floating_windows_support == 'has_no' || 
        \g:ECY_use_floating_windows_to_be_popup_windows == v:false
    exe 'inoremap <expr>' . g:ECY_select_items[0] .
          \ ' pumvisible() ? "\<C-n>" : "\' . g:ECY_select_items[0] .'"'
    exe 'inoremap <expr>' . g:ECY_select_items[1] .
          \ ' pumvisible() ? "\<C-p>" : "\' . g:ECY_select_items[1] .'"'
  else
    exe 'inoremap <silent> ' . g:ECY_select_items[0].
        \ ' <C-R>=ECY_main#SelectItems(0)<CR>'
    exe 'inoremap <silent> ' . g:ECY_select_items[1].
        \ ' <C-R>=ECY_main#SelectItems(1)<CR>'
    exe 'let g:ECY_select_items[0] = "\'.g:ECY_select_items[0].'"'
    exe 'let g:ECY_select_items[1] = "\'.g:ECY_select_items[1].'"'
  endif

  exe 'nmap ' . g:ECY_show_switching_source_popup .
        \ ' :call user_ui#ChooseSource()<CR>'

  if g:has_ultisnips_support
  " UltiSnips' API must be called in <C-R>
    exe 'inoremap ' . g:ECY_expand_snippets_key.
        \ ' <C-R>=<SID>ExpandSnippet()<CR>'
    exe 'let g:ECY_expand_snippets_key = "\'.g:ECY_expand_snippets_key.'"'
  endif

  for key in g:ECY_choose_special_source_key
    exe 'inoremap <expr>' . key['invoke_key'] . 
          \' <SID>UsingSpecicalSource( "'.key['source_name'].'","\' . key['invoke_key'] . '",' . key['is_replace'] . ' )'
  endfor

  for key in s:back_to_source_key
    exe 'inoremap <expr>' . key . ' <SID>Back2LastSource( "\' . key . '" )'
  endfor

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
    let l:start_cmd = 
          \l:start_cmd.' --input_with_socket --hmac '.s:HMAC_KEY.' --port '.s:port
  endif
  if g:ECY_debug
    let l:start_cmd .= ' --debug_log'
  endif

  try
    let g:abc = l:start_cmd
    let s:server_job_id = job#ECY_Start(l:start_cmd, {
        \ 'on_stdout': function('s:EventSort')
        \ })
    if !s:is_using_stdio
      call s:PythonEval("ECY_Client_.ConnectSocketServer()")
      if g:ECY_debug
        " this is a another socket server that inputed with socket
        call s:PythonEval("ECY_Client_.StartDebugServer()")
      endif
    endif
  catch
    call s:ShowErroAndFinish("EasyCompletion unavailable: Can not start a necessary communication server of python.")
  endtry
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

function! ECY_main#Install(name) abort
"{{{
"check source's requires
  let l:name = 'ECY_Install#'.a:name
  try
    let l:install_return = function(l:name)()
  catch
    echo '[ECY] have no "'.a:name.'" supported.'
    return 
  endtry
  if l:install_return['status'] == 0
    " refleshing all the running completor to make new completor work at every
    " where.
    echo '[ECY] checked the requires of "'.l:install_return['name'].'" successfully.'
  else
    "failed while check.
    echo l:install_return['description']
    return
  endif
  let g:ecy_source_name_2_install = l:install_return['name']
  call s:Do("InstallSource", v:true)
  echo '[ECY] installing "'.l:install_return['name'].'".'
"}}}
endfunction

function! s:Do(cmd, is_event) abort
"{{{ask the server to do something with python3
if a:is_event
  if s:is_using_stdio
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
  call s:Do("Integration", v:true)
"}}}
endfunction

function! ECY_main#GetBufferWorkSpace(...) abort
"{{{
  if a:000 == 0
    let l:bufnr = bufnr('%')
  else
    let l:bufnr = a:1
  endif

  let l:workspace = getcwd(l:bufnr)
"}}}
endfunction

function! ECY_main#Start() abort
  call s:SetVariable()
  call s:SetUpPython()
  call s:SetUpEvent()
  call s:StartCommunication()
  call s:SetMapping()
endfunction
