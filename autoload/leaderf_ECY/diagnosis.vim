
if !exists('g:leaderf_loaded')
  let g:ECY_load_leaderf_plugin = v:false
  finish
endif
let g:ECY_load_leaderf_plugin = v:true

if leaderf#versionCheck() == 0
    " this check is necessary
    finish
endif

" the ECY_leaderf_diagnosis is from "~/python/client/leaderf_plugin/"
" ==============================================================================
function! leaderf_ECY#diagnosis#register(name)
"{{{
exec g:Lf_py "<< EOF"
from leaderf.anyExpl import anyHub
anyHub.addPythonExtension(vim.eval("a:name"), ECY_leaderf_diagnosis)
EOF
"}}}
endfunction

function! leaderf_ECY#diagnosis#Maps()
"{{{
    nmapclear <buffer>
    nnoremap <buffer> <silent> <CR>          :exec g:Lf_py "ECY_leaderf_diagnosis.accept()"<CR>
    nnoremap <buffer> <silent> o             :exec g:Lf_py "ECY_leaderf_diagnosis.accept()"<CR>
    nnoremap <buffer> <silent> <2-LeftMouse> :exec g:Lf_py "ECY_leaderf_diagnosis.accept()"<CR>
    nnoremap <buffer> <silent> x             :exec g:Lf_py "ECY_leaderf_diagnosis.accept('h')"<CR>
    nnoremap <buffer> <silent> v             :exec g:Lf_py "ECY_leaderf_diagnosis.accept('v')"<CR>
    nnoremap <buffer> <silent> t             :exec g:Lf_py "ECY_leaderf_diagnosis.accept('t')"<CR>
    nnoremap <buffer> <silent> p             :exec g:Lf_py "ECY_leaderf_diagnosis._previewResult(True)"<CR>
    nnoremap <buffer> <silent> q             :exec g:Lf_py "ECY_leaderf_diagnosis.quit()"<CR>
    nnoremap <buffer> <silent> i             :exec g:Lf_py "ECY_leaderf_diagnosis.input()"<CR>
    nnoremap <buffer> <silent> <F1>          :exec g:Lf_py "ECY_leaderf_diagnosis.toggleHelp()"<CR>
    if has_key(g:Lf_NormalMap, "Marks")
        for i in g:Lf_NormalMap["Marks"]
            exec 'nnoremap <buffer> <silent> '.i[0].' '.i[1]
        endfor
    endif
"}}}
endfunction

function! leaderf_ECY#diagnosis#Start()
    call leaderf#LfPy("ECY_leaderf_diagnosis.startExplorer('".g:Lf_WindowPosition."')")
endfunction
