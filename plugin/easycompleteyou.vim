" This is basic vim plugin boilerplate
let s:save_cpo = &cpo
set cpo&vim

function! s:Finish(is_quit, msg)
  if  a:msg != ''
    echohl WarningMsg |
          \ echomsg a:msg |
          \ echohl None
  endif

  let &cpo = s:save_cpo
  unlet s:save_cpo

  if a:is_quit
    finish
  endif
endfunction

function! s:CheckRequires() abort
"{{{
  if exists( "g:loaded_easycomplete" )
    call s:Finish(v:true, '')
  elseif v:version < 704 || (v:version == 704 && !has( 'patch1578' ))
    echohl WarningMsg |
          \ echomsg "EasyCompletion unavailable: requires Vim 7.4.1578+." |
          \ echohl None
    call s:Finish(v:true, 'EasyCompletion unavailable: requires Vim 7.4.1578+.')
    if v:version == 704 && has( 'patch8056' )
      " Very very special case for users of the default Vim on macOS. For some
      " reason, that version of Vim contains a completely arbitrary (presumably
      " custom) patch '8056', which fools users (but not our has( 'patch1578' )
      " check) into thinking they have a sufficiently new Vim. In fact they do
      " not and ECY fails to initialise. So we give them a more specific warning.
      call s:Finish(v:true, 
            \ "Info: You appear to be running the default system Vim on macOS. "
            \ . "It reports as patch 8056, but it is really older than 1578. "
            \ . "Please consider MacVim, homebrew Vim or a self-built Vim that "
            \ . "satisfies the minimum requirement.")
    endif
  elseif &encoding !~? 'utf-\?8'
    call s:Finish(v:true, "EasyCompletion unavailable: supports UTF-8 encoding only. "
          \ ."Put the line 'set encoding=utf-8' into your vimrc.")
  elseif !has('python3')
    call s:Finish(v:true,"EasyCompletion unavailable: has no python3 support. " .
          \ "python3 only, python2 is abandomed.")
  endif
  let g:loaded_easycomplete = v:true
"}}}
endfunction

call s:CheckRequires()
call ECY_main#Start()

" This is basic vim plugin boilerplate
call s:Finish(v:false)
