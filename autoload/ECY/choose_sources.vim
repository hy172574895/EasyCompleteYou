" Author: Jimmy Huang (1902161621@qq.com)
" License: WTFPL

function! s:ChooseSource_Echoing() abort
"{{{ the versatitle way. could be used in many versions of vim or neovim.
  let l:filetype = &filetype
  let l:info  = g:ECY_file_type_info[l:filetype]
  while 1
    if len(l:info['available_sources']) == 0
      " show erro
      break
    endif
    let l:text1 = "Detected FileTpye--[".l:filetype."], available completor's sources:\n"
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
      call ECY_main#ChooseSource(l:filetype,'next')
    elseif l:c == "k"
      call ECY_main#ChooseSource(l:filetype,'pre')
    else
      " a callback
      call ECY_main#AfterUserChooseASource()
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
  let l:filetype = &filetype
  let l:info  = g:ECY_file_type_info[l:filetype]
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
    \ 'filter': 'g:ChooseSource_cb_vim',
    \ 'title': 'Available Sources Lists',
    \ 'zindex': 300,
    \ 'border': [],
    \ 'close': 'click',
    \ 'padding': [0,1,0,1],
    \ 'callback': 'g:ChooseSource_cb_vim',
    \ })
  call setbufvar(winbufnr(l:floating_win_nr), '&syntax','vim')
"}}}
endfunction

function! s:ChooseSource_neovim() abort
" TODO:
endfunction

function! ECY#choose_sources#Start() abort
"{{{
  call ECY_main#Log('user start a windows of selecting source')
  if exists("g:ECY_file_type_info[".string(&filetype)."]")
    if g:has_floating_windows_support == 'has_no'
      call s:ChooseSource_Echoing()
    elseif g:has_floating_windows_support == 'vim'
      call ECY_main#Log('using vim')
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
  call ECY_main#Log(l:show_text)
  echo l:show_text
  "}}}
  endif
"}}}
endfunction

function! g:ChooseSource_cb_vim(id, key) abort
"{{{popup callback in vim can't be a local function
  let l:filetype = &filetype
  if a:key == 'j' || a:key == 'k'
    if a:key == 'k'
      let l:temp = (s:using_source['current'] - 1) % len(s:using_source['list'])
      call ECY_main#ChooseSource(l:filetype,'pre')
    else
      let l:temp = (s:using_source['current'] + 1) % len(s:using_source['list'])
      call ECY_main#ChooseSource(l:filetype, 'next')
    endif
    let s:using_source['current'] = l:temp

    " have to clear it then reset the text for new.
    " maybe this a bug of vim.
    call popup_settext(a:id, '')
    call popup_settext(a:id, s:BuildLoopingList(s:using_source))
    return 1
  elseif a:key == "\<ESC>"
    " a callback
    call ECY_main#AfterUserChooseASource()
  endif
  " No shortcut, pass to generic filter. vim default to handle some keys such
  " as <Enter> <Bs> x and <Esc> for us.
  return popup_filter_menu(a:id, a:key)
"}}}
endfunction

