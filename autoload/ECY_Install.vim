function! ECY_Install#HTML_LSP()
  if !executable('html-languageserver')
    if !executable('npm')
      return {'status':'-1','description':"ECY failed to install it by NPM. You missing server's implement and NPM."}
    endif
  execute "normal! :!npm install --global vscode-html-languageserver-bin\<cr>"
  " call feedkeys(':!npm install --global vscode-html-languageserver-bin', 'n')
  endif
  try
    call UltiSnips#SnippetsInCurrentScope(1)
  catch
    echo "[Suggestion] We hightly recommend you to install UltiSnips plugin for better experience of HTML's source."
  endtry
  return {'status':'0','description':"ok",'name':'lib.sources.lsp_servers.html'}
endfunction

function! ECY_Install#Snippets()
  try
    call UltiSnips#SnippetsInCurrentScope( 1 )
  catch
    return {'status':'-1','description':"ECY failed to install it. You missing vim-snippets plugin. Please install that plugin, firstly. "}
  endtry
  return {'status':'0','description':"ok",'name':'lib.sources.snippets.snippets'}
endfunction

function! ECY_Install#YCM()
  if !ECY_main#HasYCM()
    return {'status':'-1','description':"ECY failed to install it. You missing YCM. Please install that plugin, firstly. "}
  endif
  return {'status':'0','description':"ok",'name':'lib.sources.youcompleteme.ycm'}
endfunction

function! ECY_Install#Pygment()
  return {'status':'0','description':"ok",'name':'lib.sources.pygment.pygment'}
endfunction
