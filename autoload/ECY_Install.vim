" Author: Jimmy Huang (1902161621@qq.com)
" License: WTFPL

" python, label and path are buildin.
let g:ECY_available_sources_lists = ['HTML_LSP', 'Snippets', 'YCM', 'Pygment']

function! ECY_Install#HTML_LSP()
"{{{
  " options: 1. cmd for starting Server
  " let l:temp = get(g:,'ECY_html_lsp_starting_cmd','html-languageserver --stdio') 
  if !executable('html-languageserver')
    if !executable('npm')
      return {'status':'-1','description':"ECY failed to install it by NPM. You missing server's implement and NPM."}
    endif
    call s:ExeCMD("npm install --global vscode-html-languageserver-bin")
  endif
  try
    call UltiSnips#SnippetsInCurrentScope(1)
  catch
    echo "[Suggestion] We hightly recommend you to install UltiSnips plugin for better experience of HTML's source."
  endtry
  return {'status':'0','description':"ok",'name':'lib.sources.lsp_servers.html'}
"}}}
endfunction

function! ECY_Install#Snippets()
"{{{
  " requeirs: 1. plugin of UltiSnips
  try
    call UltiSnips#SnippetsInCurrentScope( 1 )
  catch
    return {'status':'-1','description':"ECY failed to install it. You missing vim-snippets plugin. Please install that plugin, firstly. "}
  endtry
  return {'status':'0','description':"ok",'name':'lib.sources.snippets.snippets'}
"}}}
endfunction

function! ECY_Install#YCM()
"{{{
  if !utility#HasYCM()
    return {'status':'-1','description':"ECY failed to install it. You missing YCM. Please install that plugin, firstly. "}
  endif
  return {'status':'0','description':"ok",'name':'lib.sources.youcompleteme.ycm'}
"}}}
endfunction

function! ECY_Install#Pygment()
"{{{
  try
    call s:ExeCMD("pip install Pygments")
  catch
    return {'status':'-1','description':"ECY failed to install it. You missing Pygment. Please install that plugin, firstly. "}
  endtry
  return {'status':'0','description':"ok",'name':'lib.sources.pygment.pygment'}
"}}}
endfunction

function! s:ExeCMD(cmd) abort
  " synchronous in vim
   execute "normal! :!" . a:cmd . "\<cr>" 
endfunction
