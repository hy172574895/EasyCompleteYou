function user_ui#Init() abort
  "{{{ var init
  let s:is_vim = !has('nvim')
  let s:preview_windows_nr = get(s:,'preview_windows_nr',-1)
  let s:goto_preview_windows_nr = get(s:,'goto_preview_windows_nr',-1)
  let s:search_windows_nr_1 = get(s:,'search_windows_nr_1',-1)
  let s:search_windows_nr_2 = get(s:,'search_windows_nr_2',-1)
  let s:popup_windows_nr = get(s:,'search_windows_nr_2',-1)
  let g:ecy_fileter_search_items_keyword = 
        \get(g:,'ecy_fileter_search_items_keyword','')
  let g:ECY_use_floating_windows_to_be_popup_windows = 
        \get(g:,'ECY_use_floating_windows_to_be_popup_windows',v:true)
  " TODO:
  let g:ECY_PreviewWindows_style = 
        \get(g:,'ECY_PreviewWindows_style','append')

  if !s:is_vim && exists('*nvim_win_set_config')
    let g:has_floating_windows_support = 'nvim'
  elseif has('textprop')
    let g:has_floating_windows_support = 'vim'
  else
    let g:has_floating_windows_support = 'has_no'
    let g:ECY_use_floating_windows_to_be_popup_windows = v:false
  endif

  if g:has_floating_windows_support == 'vim'
        \&& g:ECY_use_floating_windows_to_be_popup_windows == v:true
    " hightlight
    hi ECY_normal_matched_word		guifg=#945596	guibg=#073642	ctermfg=red	  ctermbg=darkBlue gui=bold
    hi ECY_normal_items		        guifg=#839496	guibg=#073642	ctermfg=white	ctermbg=darkBlue

    hi ECY_selected_matched_word	guifg=#FFFF99	guibg=#586e75	ctermfg=red	ctermbg=Blue    gui=bold
    hi ECY_selected_item	        guifg=#eee8d5	guibg=#586e75	ctermfg=white	ctermbg=Blue

    let g:ECY_highlight_normal_matched_word   = get(g:,'ECY_highlight_normal_matched_word', 'ECY_normal_matched_word')
    let g:ECY_highlight_normal_items          = get(g:,'ECY_highlight_normal_items', 'ECY_normal_items')

    let g:ECY_highlight_selected_matched_word = get(g:,'ECY_highlight_selected_matched_word','ECY_selected_matched_word')
    let g:ECY_highlight_selected_item         = get(g:,'ECY_highlight_selected_item', 'ECY_selected_item')

    call prop_type_add('item_normal_matched', {'highlight': g:ECY_highlight_normal_matched_word})
    call prop_type_add('item_normal', {'highlight': g:ECY_highlight_normal_items})
    call prop_type_add('item_selected_matched', {'highlight': g:ECY_highlight_selected_matched_word})
    call prop_type_add('item_selected', {'highlight': g:ECY_highlight_selected_item})

    call prop_type_add('symbol_matched', {'highlight': 'DiffAdd'})
    call prop_type_add('symbol_name', {'highlight': 'Keyword'})
    call prop_type_add('symbol_position', {'highlight': 'NonText'})
    call prop_type_add('symbol_kind', {'highlight': 'Normal'})
  endif
  "}}}
endfunction

function! user_ui#ClosePreviewWindows() abort
"{{{
  if g:has_floating_windows_support == 'vim' && 
        \g:ECY_use_floating_windows_to_be_popup_windows == v:true
    if s:preview_windows_nr != -1
      call popup_close(s:preview_windows_nr)
      let s:preview_windows_nr = -1
    endif
  elseif g:has_floating_windows_support == 'neovim'
    " TODO
  elseif g:has_floating_windows_support == 'has_no'
"{{{
    if !g:ycm_autoclose_preview_window_after_completion
      return
    endif
    " this function was copied from ycm and the variable option is same as ycm.
    let l:current_buffer_name = bufname('')

    " We don't want to try to close the preview window in special buffers like
    " "[Command Line]"; if we do, Vim goes bonkers. Special buffers always start
    " with '['.
    if l:current_buffer_name[ 0 ] == '['
      return
    endif

    " This command does the actual closing of the preview window. If no preview
    " window is shown, nothing happens.
    pclose
"}}}
  endif
"}}}
endfunction

function! user_ui#PreviewWindows(msg,using_filetype) abort
"{{{ won't be triggered when there are no floating windows features.
  if g:has_floating_windows_support == 'vim'
    let s:preview_windows_nr = s:PreviewWindows_vim(a:msg,a:using_filetype)
  else
    let s:preview_windows_nr = s:PreviewWindows_neovim(a:msg,a:using_filetype)
  endif
"}}}
endfunction

function! user_ui#ChooseSource() abort
"{{{
  if exists("g:ECY_file_type_info[".string(&filetype)."]")
    if g:has_floating_windows_support == 'has_no'
      call s:ChooseSource_Echoing()
    elseif g:has_floating_windows_support == 'vim'
      call s:ChooseSource_vim()
    else
      call s:ChooseSource_neovim()
    endif
  else
"show something Erro{{{
  let l:line_1 = "Detected FileTpye--[".&filetype."].\n"
  if ECY_main#IsECYWorksAtCurrentBuffer()
    let l:show_text = l:line_1."  But there are no available source at this type of language.\n  Maybe it's a bug or that you need, please, report to us on Github."
  else
    let l:show_text = l:line_1."  Maybe you set this FileType making ECY not to work."
  endif
  echo l:show_text
  "}}}
  endif
"}}}
endfunction

"{{{completion
function! g:Completion_cb(id,key) abort
"{{{legacy code
	if a:key =~# "\\v[a-z0-9]"
    call popup_close(a:id)
  endif
	if a:key =~# "\\v\<Esc>|\<C-c>|\<C-g>|\<C-u>|\<C-w>|\<C-[>"
    call popup_close(a:id)
    return 1
  endif
  if a:key == g:ECY_select_items[0] || a:key == g:ECY_select_items[1]
    if a:key == g:ECY_select_items[0] 
      " next
    else
      
    endif
    return 1
  endif
"}}}
endfunction

function! user_ui#IsCompletionPopupWindowsOpen() abort
  if g:has_floating_windows_support == 'vim'
    if g:ECY_use_floating_windows_to_be_popup_windows == v:false
      return pumvisible()
    endif
    if s:popup_windows_nr != -1
      return v:true
    endif
    return v:false
  elseif g:has_floating_windows_support == 'has_no'
    return pumvisible()
  endif
endfunction

function! user_ui#CloseCompletionPopup() abort
  call popup_close(s:popup_windows_nr)
  let s:popup_windows_nr = -1
endfunction

function! s:IsInList(item,list) abort
  let i = 0
  while i < len(a:list)
    if a:item == a:list[i]
      return v:true
    endif
    let i += 1
  endw
  return v:false
endfunction

function! user_ui#Completion(items_info, fliter_words) abort
"{{{vim only
  if s:popup_windows_nr != -1
    return -1
  endif
  let l:offset_of_cursor = len(a:fliter_words)
  let l:col  = 'cursor-' . l:offset_of_cursor
  let l:opts = {'pos': 'topleft',
        \'zindex':1000,
        \'line':'cursor+1',
        \'col': l:col}
  let l:to_show = []
  let l:to_show_matched_point = []
  let l:max_len_of_showing_item = 1
  for value in a:items_info
    let l:showing = value['abbr'].value['kind']
    call add(l:to_show, l:showing)
    call add(l:to_show_matched_point, value['match_point'])
    if len(l:showing) > l:max_len_of_showing_item
      let l:max_len_of_showing_item = len(l:showing)
    endif
  endfor

  let j = 0
  while j < len(l:to_show)
    let l:temp = l:max_len_of_showing_item - len(l:to_show[j])
    let i = 0
    while i < l:temp
      let l:to_show[j] .= ' '
      let i += 1
    endw
    let j += 1
  endw

  let s:popup_windows_nr = popup_create(l:to_show,l:opts)
  let g:ECY_current_popup_windows_info = {'windows_nr': s:popup_windows_nr,
        \'selecting_item':0,'items_info':a:items_info,
        \'opts': popup_getoptions(s:popup_windows_nr)}
  " In vim, there are no API to get the floating windows' width, we calculate
  " it at here.
  " it must contain at least one item of list, so we set 0 at here.
  let g:ECY_current_popup_windows_info['floating_windows_width'] = 
        \l:max_len_of_showing_item

  let g:ECY_current_popup_windows_info['keyword_cache'] = a:fliter_words

  " hightlight it
  let i = 0
  while i < len(l:to_show_matched_point)
    let j = 0
    let l:point = l:to_show_matched_point[i]
    while j < len(l:to_show[i])
      if s:IsInList(j, l:point)
        let l:hightlight = 'item_normal_matched'
      else
        let l:hightlight = 'item_normal'
      endif
      let l:line  = i + 1
      let l:start = j + 1
      let l:exe = "call prop_add(".l:line.",".l:start.", {'length':1,'type': '".l:hightlight."'})"
      call win_execute(s:popup_windows_nr, l:exe)
      let j += 1
    endw
    let i += 1
  endw

  return s:popup_windows_nr
"}}}
endfunction

function! user_ui#SelectCompletionItems(next_or_pre,start_colum) abort
"{{{vim only
  if a:next_or_pre == 0
    let l:round = 1
  else
    let l:round = -1
  endif

  " loop
  let l:current_item     = g:ECY_current_popup_windows_info['selecting_item']
  let l:showing_item_len = len(g:ECY_current_popup_windows_info['items_info'])
  let l:next_item        = (l:current_item + l:round) % (l:showing_item_len + 1)
  if l:next_item == -1
    let l:next_item = l:showing_item_len
  endif
  let g:ECY_current_popup_windows_info['selecting_item'] = l:next_item
  let l:items_info = g:ECY_current_popup_windows_info['items_info']


  " complete and hightlight the new one 
  " let l:exe = "call prop_remove({'type':'item_selected','all':v:true})"
  " call win_execute(s:popup_windows_nr, l:exe)
  if l:next_item == 0
    let l:to_complete =  g:ECY_current_popup_windows_info['keyword_cache']
    " don't need to hightlight at here
  else
    let l:to_complete =  l:items_info[l:next_item - 1]['word']

    let l:exe = "call prop_clear(". l:next_item .")"
    call win_execute(s:popup_windows_nr, l:exe)
    let l:info = g:ECY_current_popup_windows_info['items_info'][l:next_item-1]
    let l:temp = len(l:info['abbr'].l:info['kind'])
    let l:point = l:info['match_point']
    let i = 0
    while i < g:ECY_current_popup_windows_info['floating_windows_width']
      if s:IsInList(i, l:point)
        let l:hightlight = 'item_selected_matched'
      else
        let l:hightlight = 'item_selected'
      endif
      if l:temp > i
        let l:start = i + 1
        let l:length = 1
      else
        let l:length = 100
      endif
      let l:exe = "call prop_add(".l:next_item.",".l:start.", {'length':".l:length.",'type': '".l:hightlight."'})"
      call win_execute(s:popup_windows_nr, l:exe)
      let i += 1
    endw
  endif

  " unhighlight the old one.
  if l:current_item != 0
    let l:exe = "call prop_clear(". l:current_item .")"
    call win_execute(s:popup_windows_nr, l:exe)
    let l:info = g:ECY_current_popup_windows_info['items_info'][l:current_item-1]
    let l:temp = len(l:info['abbr'].l:info['kind'])
    let l:point = l:info['match_point']
    let i = 0
    while i < g:ECY_current_popup_windows_info['floating_windows_width']
      if s:IsInList(i, l:point)
        let l:hightlight = 'item_normal_matched'
      else
        let l:hightlight = 'item_normal'
      endif
      if l:temp > i
        let l:start = i + 1
        let l:length = 1
      else
        let l:length = 100
      endif
      let l:exe = "call prop_add(".l:current_item.",".l:start.", {'length':".l:length.",'type': '".l:hightlight."'})"
      call win_execute(s:popup_windows_nr, l:exe)
      let i += 1
    endw
  endif

  " this function will trigger the insert event, and don't want it to 
  " be triggered when this is completing.
  " IMPORTANCE: when comment this function, vim will not highlight the
  " selected item, because we filter the key of <Tab> that is selecting
  " mapping, then the s:isSelecting in ECY_main.vim can not be reset.
  call complete(a:start_colum+1,[l:to_complete])
"}}}
endfunction

"}}}

function! user_ui#Search(items_2_show) abort
"{{{ handle a symbol event.
"a symbol's infos must contain a line to show

" this will invoke leaderf plugin in python to handle g:ECY_items_data
  let g:ECY_items_data = a:items_2_show
  call timer_start(100, 'CallLeaderF')
  return
"}}}
endfunction

function! CallLeaderF(timer)
  call leaderf_ECY#diagnosis#Start()
endfunction

function! user_ui#MoveTo(line, colum, path, modes)
"{{{
  if a:modes == 'h'
    " new a windows
  elseif a:modes == 'v'
    " new a windows
  elseif a:modes == 't'
    " new a windows and a tab
  else
    " do nothing
    " work at current windows
  endif
  exe "hide edit " .  a:path
  exe a:line
  " exe a:colum . "|"
"}}}
endfunction

function! s:CheckResultsAtWindows(position, modes)
  call user_ui#MoveTo(a:position['line'], a:position['colum'], a:position['path'], a:modes)
endfunction

function! user_ui#LeaderF_cb(line, event, nr, ...)
  let l:data  = g:ECY_items_data[a:nr]
  if a:event == 'acceptSelection' || a:event == 'previewResult'
    if exists("l:data['position']")
      " a:1 is modes
      let l:modes = a:1
      if a:event == 'previewResult'
        " preview at current windows
        let l:modes = 'nothing'
      endif
      call s:CheckResultsAtWindows(l:data['position'],l:modes)
    endif
  endif
endfunction

function! user_ui#CheckGoto(items,using_filetype) abort
"{{{
  if len(a:items) == 0
    echo 'Nothing to show when calling Goto.'
    return 
  endif
  if g:has_floating_windows_support == 'has_no'
    call s:ShowGoto_Quickfix(a:items,a:using_filetype)
  elseif g:has_floating_windows_support == 'vim'
    call s:ShowGoto_vim(a:items,a:using_filetype)
  elseif g:has_floating_windows_support == 'neovim'
    call s:ShowGoto_neovim(a:items,a:using_filetype)
  endif
"}}}
endfunction

function! g:ChooseSource_cb(id, key) abort
"{{{popup callback in vim can't be a local function
  if a:key == 'j' || a:key == 'k'
    if a:key == 'k'
      let l:temp = (s:using_source['current']-1)%len(s:using_source['list'])
      call ECY_main#ChooseSource(&filetype,'pre')
    else
      let l:temp = (s:using_source['current']+1)%len(s:using_source['list'])
      call ECY_main#ChooseSource(&filetype,'next')
    endif
    let s:using_source['current'] = l:temp

    " have to clear it then reset the text for now.
    call popup_settext(a:id,'')
    call popup_settext(a:id,s:BuildLoopingList(s:using_source))
    return 1
  endif
  " No shortcut, pass to generic filter. vim default to handle some keys such
  " as <Enter> <Bs> x and <Esc> for us.
  return popup_filter_menu(a:id, a:key)
"}}}
endfunction

function! g:Search_cb(id, key) abort
"{{{popup callback in vim can't be a local function
  " if a:key == 'j' || a:key == 'k'
  "   return 1
  " endif
  if a:key == "\<ESC>"
    try
      let g:ecy_fileter_search_items_keyword = ''
      call popup_close(s:search_windows_nr_1)
      call popup_close(s:search_windows_nr_2)
      let s:search_windows_nr_1 = -1
    endtry
    return 1
  else
    while 1 
      let l:char = nr2char(getchar())
      if l:char == "q"
        break
      endif
      let g:ecy_fileter_search_items_keyword .=  l:char
      echo g:ecy_fileter_search_items_keyword
      call popup_settext(s:search_windows_nr_2,'')
      call popup_settext(s:search_windows_nr_2,' >> ' . g:ecy_fileter_search_items_keyword)
    endwhile 
    " call ECY_main#Execute('filter_search_items')
  endif
  " No shortcut, pass to generic filter. vim default to handle some keys such
  " as <Enter> <Bs> x and <Esc> for us.
  return popup_filter_menu(a:id, a:key)
"}}}
endfunction

function! g:Goto_cb(id, key) abort
"{{{popup callback in vim can't be a local function
  if a:key == 'j' || a:key == 'k'
    return 1
  endif
  if a:key == 'h' || a:key == "\<ESC>"
    if s:goto_preview_windows_nr != -1
      call popup_close(s:goto_preview_windows_nr)
    endif
  endif
  " No shortcut, pass to generic filter. vim default to handle some keys such
  " as <Enter> <Bs> x and <Esc> for us.
  return popup_filter_menu(a:id, a:key)
"}}}
endfunction

function s:ShowGoto_Quickfix(items,using_filetype) abort
endfunction

function s:Search_Quicfix(items_2_show) abort
" using fuzzy-match to quickly nagevate

endfunction

function s:Search_vim(items_2_show) abort
"{{{
"TODO: waitting for vim to support getting char while popup windows filttering
  " item formmat:
  " {'name':'xxxx','path':'path_to_it','kind':'definitions','', 'position':''}
  let s:search_context_list = a:items_2_show
  let l:context = []
  let l:hightlight_info = {}
  let i = 1
  for l:item in a:items_2_show
    let l:hightlight_info[i] = {}
    " line and colum are start at 1
    let l:hightlight_info[i]['name_position'] = {'start': 1,'len': len(l:item['abbr']),'hightlight':'symbol_name'}
    let l:hightlight_info[i]['kind_position'] = {'start': len(l:item['abbr']) + 1 ,'len': len(l:item['kind']),'hightlight':'symbol_kind'}
    let l:part1 = l:item['abbr'] . l:item['kind']
    let l:hightlight_info[i]['part2_position'] = {'start': len(l:part1) + 1,'len': len(string(l:item['position'])),'hightlight':'symbol_position'}
    call add(l:context, l:part1 . string(l:item['position']))
    let i += 1
  endfor
  if s:search_windows_nr_1 == -1
    let l:opts = {
        \ 'maxheight': 20,
        \ 'minwidth': 50,
        \ 'border': [],
        \ 'close': 'click',
        \ 'padding': [0,1,0,1],
        \ 'zindex': 2000}
    let s:search_windows_nr_1 = popup_create(l:context,l:opts)
    let l:part = ['name_position', 'kind_position', 'part2_position']
    for [l:line,l:value] in items(l:hightlight_info)
      for l:item in l:part
        let l:len = l:value[l:item]['len']
        let l:hightlight = l:value[l:item]['hightlight']
        let l:start = l:value[l:item]['start']
        let l:exe = "call prop_add(".l:line.",".l:start.", {'length':".l:len .",'type': '".l:hightlight."'})"
        call win_execute(s:search_windows_nr_1, l:exe)
      endfor
    endfor
    " while 1
    "   let l:char = getchar()
    "   if l:char == "\<ESC>"
    "     try
    "       let s:search_windows_nr_1 = -1
    "       let g:ecy_fileter_search_items_keyword = ''
    "       call popup_close(s:search_windows_nr_1)
    "     endtry
    "     break
    "   endif
    " endwhile
    let l:goto_windows_position = popup_getpos(s:search_windows_nr_1)
    let l:opts = {
        \ 'maxheight': 14,
        \ 'border': [],
        \ 'close': 'click',
        \ 'padding': [0,1,0,1],
        \ 'zindex': 2000}
    if l:goto_windows_position != {}
      let l:opts['col'] = l:goto_windows_position['col']
      let l:opts['line'] = l:goto_windows_position['line']
      let l:opts['pos'] = "botleft"
      " echo l:context
    endif
    let s:search_windows_nr_2 = popup_create(' >> ',l:opts)
  endif
"}}}
endfunction

function s:ShowGoto_vim(items,using_filetype) abort
"{{{
  let l:toShow_list           = []
  let l:goto_preview          = {}
  let l:loaded_file           = s:GetLoadedFile()
  let l:goto_windows_position = {}
  let l:i = 0
  for item in a:items
    if item['is_in_builtin_module'] == 'yes'
      call add(l:toShow_list,string(l:i).'.Builtin module.|'. item['types'] )
    else
      let l:position = item['start_line'].':'.item['start_colum']
      call add(l:toShow_list,string(l:i).'.'.
            \item['description'].'|'. item['types'].'|'.l:position)
      if l:goto_preview == {}
        for l:buff in l:loaded_file
          if l:buff['buf_path'] == tr(item['path'], '\', '/')
            let l:goto_preview['bufnr']    = l:buff['bufnr']
            let l:goto_preview['context']  = getbufline(l:buff['bufnr'],1,'$')
            let l:goto_preview['start_line'] = item['start_line']
            break
          endif
        endfor
      endif
    endif
    let l:i += 1
  endfor
  if l:goto_preview != {}
    let l:firstline = l:goto_preview['start_line']
    let l:opts = {
        \ 'maxheight': 20,
        \ 'firstline': l:firstline,
        \ 'border': [],
        \ 'filter': 'g:Goto_cb',
        \ 'callback': 'g:Goto_cb',
        \ 'close': 'click',
        \ 'padding': [0,1,0,1],
        \ 'zindex': 2000}
      
    " create a preview window at center
    let s:goto_preview_windows_nr = popup_create(l:goto_preview['context'],l:opts)
    call setbufvar(winbufnr(s:goto_preview_windows_nr), '&filetype',a:using_filetype)
    let l:goto_windows_position = popup_getpos(s:goto_preview_windows_nr)
  endif
  let l:opts = {
      \ 'maxheight': 14,
      \ 'border': [],
      \ 'filter': 'g:Goto_cb',
      \ 'callback': 'g:Goto_cb',
      \ 'close': 'click',
      \ 'padding': [0,1,0,1],
      \ 'zindex': 2000}
  if l:goto_windows_position != {}
    let l:opts['col'] = l:goto_windows_position['col']
    let l:opts['line'] = l:goto_windows_position['line']
    let l:opts['pos'] = "botleft"
  endif
  " Creat a genernal windows with all choices.
  " the key event will be pass to the genernal windows' callback.
  call popup_create(l:toShow_list,l:opts)
"}}}
endfunction

function! user_ui#GetLoadedFile() abort
"{{{
  "return the loaded file with path
  let l:list_of_buf = []
  for l:buff in getbufinfo()
    let l:path = tr(l:buff['name'], '\', '/')
    let l:buf_info = {'bufnr': l:buff['bufnr'],'buf_path': l:path}
    call add(l:list_of_buf,l:buf_info)
  endfor
  return l:list_of_buf
"}}}
endfunction

function s:PreviewWindows_vim(msg,using_filetype) abort
"{{{ return a floating_win_nr

"{{{ this two keys will be contained in the formmat whether it's None or not.
  let l:item_info   = a:msg['info']
  " info is a list and can be split by python.
  let l:item_menu   = a:msg['menu']
  " menu should be one line.
"}}}

  let l:toShow_list = []
  if l:item_menu != ''
    let l:toShow_list = split(l:item_menu,"\n")
    call add(l:toShow_list,'----------------')
  endif
  for item in l:item_info
    call add(l:toShow_list,item)
  endfor
  if l:toShow_list == []
    return
  endif
  if g:ECY_PreviewWindows_style == 'append'
    if g:ECY_use_floating_windows_to_be_popup_windows == v:true
      let l:col = g:ECY_current_popup_windows_info['floating_windows_width'] 
            \+ g:ECY_current_popup_windows_info['opts']['col']
      let l:line = g:ECY_current_popup_windows_info['opts']['line']
    else
      let l:event = copy(v:event)
      let l:col  = l:event['col'] + l:event['width'] + 1
      let l:line = l:event['row'] + 1
    endif

    let l:opts = {
        \ 'minwidth': 30,
        \ 'maxwidth': 50,
        \ 'pos': 'topleft',
        \ 'col': l:col,
        \ 'line': l:line,
        \ 'minheight': 2,
        \ 'maxheight': 14,
        \ 'border': [],
        \ 'close': 'click',
        \ 'padding': [0,1,0,1],
        \ 'zindex': 2000}
  else
    " TODO:
    " waitting for vim to support more operation of floating windows
  endif

  let l:nr = popup_create(l:toShow_list,l:opts)
  call setbufvar(winbufnr(l:nr), '&filetype',a:using_filetype)
  return l:nr
"}}}
endfunction


function s:ShowGoto_neovim(items,using_filetype) abort
" TODO
endfunction

function s:PreviewWindows_neovim(items,using_filetype) abort
" TODO
endfunction

function! s:ChooseSource_neovim() abort
" TODO:
endfunction

function! s:ChooseSource_Echoing() abort
"{{{ the versatitle way. could be used in many versions of vim or neovim.
  let l:info  = g:ECY_file_type_info[&filetype]
  while 1
    if len(l:info['available_sources']) == 0
      " show erro
      break
    endif
    let l:text1 = "Detected FileTpye--[".&filetype."], available completor's sources:\n"
    let l:text2 = "(Press ".'j/k'." to switch item that you want)\n------------------------------------------\n"
    let l:i     = 1
    for support_complete_name in l:info['available_sources']
      let l:item = string(l:i).".".support_complete_name."\n"
      if support_complete_name == l:info['filetype_using']
        let l:item = "  >> ".l:item
      else
        let l:item = "     ".l:item
      endif
      let l:text2 .= l:item
      let l:i += 1
    endfor
    let l:show_text = l:text1.l:text2
    echo l:show_text
    let l:c = nr2char(getchar())
    redraw!
    if l:c == "j"
      call ECY_main#ChooseSource(&filetype,'next')
    elseif l:c == "k"
      call ECY_main#ChooseSource(&filetype,'pre')
    else
      return
    endif
  endwhile
"}}}
endfunction

function! s:BuildLoopingList(info) abort
"{{{return a list with '>>' inside the items.
  let l:text = ["",'Press j/k to toggle item']
  let l:list = a:info['list']
  let l:current_using = a:info['current']
  let l:i             = 0
  for item in l:list
    if item == l:list[l:current_using]
      call add(l:text,">> ".string(l:i).".".string(item))
    else
      call add(l:text,"   ".string(l:i).".".string(item))
    endif
    let l:i += 1
  endfor
  return l:text
"}}}
endfunction

function! s:ChooseSource_vim() abort
"{{{
  let l:info  = g:ECY_file_type_info[&filetype]
  let l:i = 0
  " the g:ECY_file_type_info has no index number, but has using source's name.
  for item in l:info['available_sources']
    if l:info['filetype_using'] == item
      break
    endif
    let l:i += 1
  endfor

  let s:using_source = {'list':l:info['available_sources'],'current': l:i}
  let l:floating_win_nr = popup_create(s:BuildLoopingList(s:using_source),{
    \ 'filter': 'g:ChooseSource_cb',
    \ 'title': 'Available Sources Lists',
    \ 'zindex': 300,
    \ 'border': [],
    \ 'close': 'click',
    \ 'padding': [0,1,0,1],
    \ 'callback': 'g:ChooseSource_cb',
    \ })
  call setbufvar(winbufnr(l:floating_win_nr), '&filetype','vim')
"}}}
endfunction

