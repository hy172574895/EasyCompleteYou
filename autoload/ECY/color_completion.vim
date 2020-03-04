" Author: Jimmy Huang (1902161621@qq.com)
" License: WTFPL

function ECY#color_completion#Init() abort
"{{{
  let g:ECY_use_floating_windows_to_be_popup_windows = 
        \get(g:,'ECY_use_floating_windows_to_be_popup_windows',v:true)

  let s:popup_windows_nr = get(s:,'popup_windows_nr',-1)

  if g:has_floating_windows_support == 'vim'
        \&& g:ECY_use_floating_windows_to_be_popup_windows == v:true

    let g:ECY_completion_color_style = get(g:,'ECY_completion_color_style', '1')
    " hightlight
    if g:ECY_completion_color_style == '1'
      hi ECY_normal_matched_word		guifg=#945596	guibg=#073642	ctermfg=red	  ctermbg=darkBlue gui=bold
      hi ECY_normal_items		        guifg=#839496	guibg=#073642	ctermfg=white	ctermbg=darkBlue

      hi ECY_selected_matched_word	guifg=#FFFF99	guibg=#586e75	ctermfg=red	ctermbg=Blue    gui=bold
      hi ECY_selected_item	        guifg=#eee8d5	guibg=#586e75	ctermfg=white	ctermbg=Blue
    else
      " light
      hi ECY_normal_matched_word		guifg=#282828	guibg=#689d6a	ctermfg=red	  ctermbg=darkBlue gui=bold
      hi ECY_normal_items		        guifg=#3c3836	guibg=#689d6a	ctermfg=white	ctermbg=darkBlue

      hi ECY_selected_matched_word	guifg=#FFFF99	guibg=#427b48	ctermfg=red	ctermbg=Blue
      hi ECY_selected_item	        guifg=#eee8d5	guibg=#427b48	ctermfg=white	ctermbg=Blue
    endif

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

function! s:ShowPrompt_vim(items_info, fliter_words) abort
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

  let s:popup_windows_nr = popup_create(l:to_show, l:opts)
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
      if ECY#utility#IsInList(j, l:point)
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

function! s:SelectItems_vim(next_or_pre,start_colum) abort
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
      if ECY#utility#IsInList(i, l:point)
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
      if ECY#utility#IsInList(i, l:point)
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

function! ECY#color_completion#IsPromptOpen() abort
"{{{
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
"}}}
endfunction

function! ECY#color_completion#ClosePrompt() abort
  if g:has_floating_windows_support == 'vim'
    call popup_close(s:popup_windows_nr)
    let s:popup_windows_nr = -1
  else
    "TODO: neovim
  endif
endfunction

function! ECY#color_completion#ShowPrompt(items_info, fliter_words) abort
  if g:has_floating_windows_support == 'vim'
    call s:ShowPrompt_vim(a:items_info, a:fliter_words)
  else
    "TODO: neovim
  endif
endfunction

function! ECY#color_completion#SelectItems(next_or_pre, start_colum) abort
  if g:has_floating_windows_support == 'vim'
    call s:SelectItems_vim(a:next_or_pre, a:start_colum)
  else
    "TODO: neovim
  endif
endfunction

