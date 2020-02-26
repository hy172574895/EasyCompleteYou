" Author: Jimmy Huang (1902161621@qq.com)
" License: WTFPL

function! ECY#install#Init() abort
"{{{ must be called before setupPython()
   " put buildin engine name into Client
   " when Client finding no Clent event will omit it to genernal
   let s:ECY_buildin_engine_client = {
         \'html_lsp': 'lib.event.html_lsp',
         \'go_langserver': 'lib.event.go_langserver',
         \'go_gopls': 'lib.event.go_gopls',
         \'snippets': 'lib.event.snippets',
         \'vim_lsp': 'lib.event.vim'}

   let s:ECY_buildin_engine_installer = {
         \'html_lsp': function('ECY#install#HTML_LSP'),
         \'snippets': function('ECY#install#Snippets'),
         \'youcompleteme': function('ECY#install#YCM'),
         \'go_langserver': function('ECY#install#Go_langserver'),
         \'go_gopls': function('ECY#install#Go_gopls'),
         \'vim_lsp': function('ECY#install#HTML_LSP')
         \}
  for [key, lib] in items(s:ECY_buildin_engine_client)
    " if a new engine did not register a client, ECY will use the default one
    " instead.
    call ECY#install#RegisterClient(key, lib)
  endfor
  for [key, Fuc] in items(s:ECY_buildin_engine_installer)
    call ECY#install#RegisterInstallFunction(key, Fuc)
  endfor
"}}}
endfunction

function! ECY#install#RegisterInstallFunction(engine_name, functions)
  if !exists('g:ECY_available_engine_installer')
    let g:ECY_available_engine_installer = {}
  endif
  let g:ECY_available_engine_installer[a:engine_name] = a:functions
endfunction

function! ECY#install#RegisterClient(engine_name, client_lib)
  if !exists('g:ECY_available_engine_lists')
    let g:ECY_available_engine_lists = {}
  endif
  let g:ECY_available_engine_lists[a:engine_name] = a:client_lib
endfunction

function! ECY#install#HTML_LSP()
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
  return {'status':'0','description':"ok",'lib': 'lib.sources.lsp_servers.html', 'name':'html_lsp', 'path': ''}
"}}}
endfunction

function! ECY#install#Go_gopls()
"{{{
  if !executable('gopls')
    return {'status':'-1','description':"ECY failed to install it. You missing go-langserver Server. Please install that plugin, firstly. "}
  endif
  return {'status':'0','description':"ok",'lib': 'lib.sources.lsp_servers.go_gopls', 'name':'go_gopls', 'path': ''}
"}}}
endfunction

function! ECY#install#Go_langserver()
"{{{
  if !executable('go-langserver')
    return {'status':'-1','description':"ECY failed to install it. You missing go-langserver Server. Please install that plugin, firstly. "}
  endif
  return {'status':'0','description':"ok",'lib': 'lib.sources.lsp_servers.go_langserver', 'name':'go_langserver', 'path': ''}
"}}}
endfunction

function! ECY#install#Snippets()
"{{{
  " requeirs: 1. plugin of UltiSnips
  try
    call UltiSnips#SnippetsInCurrentScope( 1 )
  catch
    return {'status':'-1','description':"ECY failed to install it. You missing vim-snippets plugin. Please install that plugin, firstly. "}
  endtry
  return {'status':'0','description':"ok",'lib': 'lib.sources.snippets.snippets', 'name':'snippets', 'path': ''}
"}}}
endfunction

function! ECY#install#YCM()
"{{{
  if !ECY#utility#HasYCM()
    return {'status':'-1','description':"ECY failed to install it. You missing YCM. Please install that plugin, firstly. "}
  endif
  return {'status':'0','description':"ok",'lib':'lib.sources.youcompleteme.ycm', 'name':'youcompleteme', 'path': ''}
"}}}
endfunction

function! ECY#install#Pygment()
"{{{
  try
    call s:ExeCMD("pip install Pygments")
  catch
    return {'status':'-1','description':"ECY failed to install it. You missing Pygment. Please install that plugin, firstly. "}
  endtry
  return {'status':'0','description':"ok",'lib': 'lib.sources.pygment.pygment', 'name':'pygment', 'path': ''}
"}}}
endfunction

function! ECY#install#Install_cb(dict) abort
"{{{
  if a:dict['Status'] == 0
    " succeed
    for item in a:dict['FileType']
      if item == 'all'
        let g:ECY_file_type_info = {}
        break
      endif
      if exists("g:ECY_file_type_info[item]")
        unlet g:ECY_file_type_info[item]
      endif
    endfor
    " trigger events again
    call ECY_main#AfterUserChooseASource()
  endif
  call ECY#utility#ShowMsg('[ECY]' . string(a:dict['Name']) . a:dict['Description'], 2)
"}}}
endfunction

function! s:ExeCMD(cmd) abort
  " synchronous in vim
   execute "normal! :!" . a:cmd . "\<cr>" 
endfunction
