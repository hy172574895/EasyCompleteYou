" Author: Jimmy Huang (1902161621@qq.com)
" License: WTFPL

" can only have one preview windows
function! ECY#completion_preview_windows#Init() abort
"{{{ 
  let g:ECY_windows_are_showing['completion_preview_windows'] = -1
  let g:ECY_enable_preview_snippet = get(g:,'ECY_enable_preview_snippet', v:true)
  let g:ECY_preview_windows_size = 
        \get(g:,'ECY_preview_windows_size',[[30, 50], [2, 14]])
  " TODO:
  " g:ECY_PreviewWindows_style = 'append'
  " g:ECY_PreviewWindows_style = 'preview_windows'
  let g:ECY_PreviewWindows_style = 
        \get(g:,'ECY_PreviewWindows_style','append')

  let g:ycm_autoclose_preview_window_after_completion
        \= get(g:,'ycm_autoclose_preview_window_after_completion',v:true)
"}}}
endfunction

function! ECY#completion_preview_windows#Show(msg, using_highlight) abort
"{{{ won't be triggered when there are no floating windows features.
  if g:has_floating_windows_support == 'vim'
    let g:ECY_windows_are_showing['completion_preview_windows'] = s:PreviewWindows_vim(a:msg,a:using_highlight)
  else
    let g:ECY_windows_are_showing['completion_preview_windows'] = s:PreviewWindows_neovim(a:msg,a:using_highlight)
  endif
"}}}
endfunction

function! ECY#completion_preview_windows#Close() abort
"{{{
  if g:has_floating_windows_support == 'vim'
    if g:ECY_windows_are_showing['completion_preview_windows'] != -1
      call popup_close(g:ECY_windows_are_showing['completion_preview_windows'])
      let g:ECY_windows_are_showing['completion_preview_windows'] = -1
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

function s:PreviewWindows_neovim(items,using_highlight) abort
" TODO
endfunction

function s:InsertKey(timer_id) abort
  call UltiSnips#ExpandSnippet()
  let l:temp = getbufline(bufnr(),1, "$")
  execute 'close!'
  " call feedkeys("\<ESC>". a:name, 'i')
  let g:abc = l:temp
endfunction

function ECY#completion_preview_windows#GetPreviewSnippet(name, file_type) abort
  execute 'new'
  let &filetype = a:file_type
  " call timer_start(100, function('s:InsertKey', ['i']))
  " call timer_start(1, function('s:InsertKey', [a:name]))
  call feedkeys('i'. a:name, 'i')
  call timer_start(1, function('s:InsertKey'))
endfunction

function s:PreviewWindows_vim(msg, using_highlight) abort
"{{{ return a floating_win_nr

  " TODO
  " if a:msg['kind'] == '[Snippet]' && g:ECY_enable_preview_snippet
  "   call ECY#completion_preview_windows#GetPreviewSnippet(a:msg['word'], &filetype)
  " endif

"{{{ this two keys will be contained in the formmat whether it's None or not.
  let l:item_info   = a:msg['info']
  " info is a list and can be split by python.
  let l:item_menu   = a:msg['menu']
  " menu should be one line.
"}}}

  let l:toShow_list = []
  if l:item_menu != ''
    let l:toShow_list = split(l:item_menu, "\n")
    call add(l:toShow_list,'----------------')
  endif
  for item in l:item_info
    call add(l:toShow_list, item)
  endfor
  if l:toShow_list == []
    return -1
  endif
  if g:ECY_PreviewWindows_style == 'append'
    if g:ECY_use_floating_windows_to_be_popup_windows == v:true
      let l:col = g:ECY_current_popup_windows_info['floating_windows_width'] 
            \+ g:ECY_current_popup_windows_info['opts']['col']
      let l:line = g:ECY_current_popup_windows_info['opts']['line']
    else
      " has floating windows, but user don't want to use it to be popup window
      let l:event = copy(v:event)
      let l:col  = l:event['col'] + l:event['width'] + 1
      let l:line = l:event['row'] + 1
    endif

    let l:opts = {
        \ 'minwidth': g:ECY_preview_windows_size[0][0],
        \ 'maxwidth': g:ECY_preview_windows_size[0][1],
        \ 'pos': 'topleft',
        \ 'col': l:col,
        \ 'line': l:line,
        \ 'minheight': g:ECY_preview_windows_size[1][0],
        \ 'maxheight': g:ECY_preview_windows_size[1][1],
        \ 'border': [],
        \ 'close': 'click',
        \ 'scrollbar': 1,
        \ 'firstline': 1,
        \ 'padding': [0,1,0,1],
        \ 'zindex': 2000}
  else
    " TODO:
    " waitting for vim to support more operation of floating windows
  endif

  let l:nr = popup_create(l:toShow_list,l:opts)
  call setbufvar(winbufnr(l:nr), '&syntax', a:using_highlight)
  return l:nr
"}}}
endfunction
