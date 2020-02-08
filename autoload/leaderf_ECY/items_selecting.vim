" Author: Jimmy Huang (1902161621@qq.com)
" License: WTFPL

if !exists('g:leaderf_loaded')
  let g:ECY_load_leaderf_plugin = v:false
  finish
endif
let g:ECY_load_leaderf_plugin = v:true

if leaderf#versionCheck() == 0
    " this check is necessary
    finish
endif

call ECY_main#Do("from leaderf_plugin.selecting import *", v:false)

" the ECY_leaderf_selecting is from "~/python/client/leaderf_plugin/"
" ==============================================================================
function! leaderf_ECY#items_selecting#register(name)
"{{{
exec g:Lf_py "<< EOF"
from leaderf.anyExpl import anyHub
anyHub.addPythonExtension(vim.eval("a:name"), ECY_leaderf_selecting)
EOF
"}}}
endfunction

function! leaderf_ECY#items_selecting#Maps()
"{{{
    nmapclear <buffer>
    nnoremap <buffer> <silent> <CR>          :exec g:Lf_py "ECY_leaderf_selecting.accept()"<CR>
    nnoremap <buffer> <silent> o             :exec g:Lf_py "ECY_leaderf_selecting.accept()"<CR>
    nnoremap <buffer> <silent> <2-LeftMouse> :exec g:Lf_py "ECY_leaderf_selecting.accept()"<CR>
    nnoremap <buffer> <silent> x             :exec g:Lf_py "ECY_leaderf_selecting.accept('h')"<CR>
    nnoremap <buffer> <silent> v             :exec g:Lf_py "ECY_leaderf_selecting.accept('v')"<CR>
    nnoremap <buffer> <silent> t             :exec g:Lf_py "ECY_leaderf_selecting.accept('t')"<CR>
    nnoremap <buffer> <silent> p             :exec g:Lf_py "ECY_leaderf_selecting._previewResult(True)"<CR>
    nnoremap <buffer> <silent> q             :exec g:Lf_py "ECY_leaderf_selecting.quit()"<CR>
    nnoremap <buffer> <silent> i             :exec g:Lf_py "ECY_leaderf_selecting.input()"<CR>
    nnoremap <buffer> <silent> <F1>          :exec g:Lf_py "ECY_leaderf_selecting.toggleHelp()"<CR>
    if has_key(g:Lf_NormalMap, "Marks")
        for i in g:Lf_NormalMap["Marks"]
            exec 'nnoremap <buffer> <silent> '.i[0].' '.i[1]
        endfor
    endif
"}}}
endfunction

function! s:LeaderfTimer_cb(timer) abort
  call leaderf#LfPy("ECY_leaderf_selecting.startExplorer('".g:Lf_WindowPosition."')")
endfunction

function! leaderf_ECY#items_selecting#Start(content, callback_name) abort
"{{{ call by viml
  " this will invoke leaderf plugin in python to handle g:ECY_items_data
  " must be called by a timer.
  let g:ECY_items_data = a:content
  let g:ECY_selecting_cb_name = a:callback_name
  " can not have some of loop-like code in event callback
  call timer_start(1, function('s:LeaderfTimer_cb'))
"}}}
endfunction

function! leaderf_ECY#items_selecting#LeaderF_cb(line, event, index, nodes, callback_name) abort
"{{{ call by python of leaderf
  try
    let l:Fuc = function(a:callback_name)
    call l:Fuc(a:line, a:event, a:index, a:nodes)
  catch 
    call utility#ShowMsg("[ECY] something wrong with selecting, maybe this is a bug.", 2)
  endtry
"}}}
endfunction
