" Author: Jimmy Huang (1902161621@qq.com)
" License: WTFPL

let s:job_id = 0
let s:job_info = {}
let g:is_vim = !has('nvim')
let s:requires_ok = (g:is_vim && has('job') && has('channel') ) || 
      \(!g:is_vim && has('nvim-0.2.0'))

function! ECY#jobs#Create(cmd, opts) abort
  if !s:requires_ok
    throw "[Jobs] Missing requires."
  endif
  let s:job_id += 1
  if g:is_vim
    let l:job_id = s:Create_vim(a:cmd, a:opts)
  else
    let l:job_id = s:Create_nvim(a:cmd, a:opts)
  endif
  return l:job_id
endfunction

function! s:Create_vim(cmd, opts)
  let l:jobopt = {
      \ 'out_cb': function('s:out_cb', [s:job_id]),
      \ 'err_cb': function('s:err_cb', [s:job_id]),
      \ 'exit_cb': function('s:exit_cb', [s:job_id]),
      \ 'mode': 'raw',
  \ }
  if has('patch-8.1.889')
    let l:jobopt['noblock'] = 1
  endif
  let l:job  = job_start(a:cmd, l:jobopt)
  if job_status(l:job) !=? 'run'
    throw "Failed to run a job."
  endif
  let s:job_info[s:job_id] = a:opts
  return s:job_id
endfunction

"{{{ vim's cb
function! s:out_cb(job_id, job, data) abort
  if exists("s:job_info[a:job_id]['on_stdout']")
    let l:Fuc = s:job_info[a:job_id]['on_stdout']
    call l:Fuc(a:job_id, split(a:data, "\n", 1), 'stdout')
  endif
endfunction

function! s:err_cb(job_id, job, data) abort
  if exists("s:job_info[a:job_id]['on_stderr']")
    let l:Fuc = s:job_info[a:job_id]['on_stderr']
    call l:Fuc(a:job_id, split(a:data, "\n", 1), 'on_stderr')
  endif
endfunction

function! s:exit_cb(job_id, job, status) abort
  if exists("s:job_info[a:job_id]['on_exit']")
    let l:Fuc = s:job_info[a:job_id]['on_exit']
    call l:Fuc(a:job_id, a:status, 'exit')
  endif
  if exists("s:job_info[a:job_id]")
    call remove(s:job_info, a:job_id)
  endif
endfunction
"}}}

function! s:Create_nvim(cmd, opts)
  let l:job = jobstart(a:cmd, {
      \ 'on_stdout': function('s:on_stdout', [s:job_id]),
      \ 'on_stderr': function('s:on_stderr', [s:job_id]),
      \ 'on_exit': function('s:on_exit', [s:job_id]),
  \})
  if l:job <= 0
    throw "Failed to run a job."
  endif
  let s:job_info[s:job_id] = a:opts
  return s:job_id
endfunction

"{{{ nvim's cb
function! s:on_stdout(job_id, job, data, event) abort
  if exists("s:job_info[a:job_id]['on_stdout']")
    let l:Fuc = s:job_info[a:job_id]['on_stdout']
    call l:Fuc(a:job_id, a:data, 'on_stdout')
  endif
endfunction

function! s:on_stderr(job_id, job, data, event) abort
  if exists("s:job_info[a:job_id]['on_stderr']")
    let l:Fuc = s:job_info[a:job_id]['on_stderr']
    call l:Fuc(a:job_id, a:data, 'on_stderr')
  endif
endfunction

function! s:on_exit(job_id, job, status, event) abort
  if exists("s:job_info[a:job_id]['exit']")
    let l:Fuc = s:job_info[a:job_id]['exit']
    call l:Fuc(a:job_id, a:data, 'exit')
  endif
  if exists("s:job_info[a:job_id]")
    call remove(s:job_info, a:job_id)
  endif
endfunction
"}}}
