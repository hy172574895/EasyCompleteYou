" Author: Jimmy Huang (1902161621@qq.com)
" License: WTFPL

function! ECY_Install#Init() abort
"{{{ must be called before setupPython()
   " put buildin engine name into Client
   " when Client finding no Clent event will omit it to genernal
   let s:ECY_buildin_engine = {'html_lsp': 'lib.event.html_lsp','snippets': 'lib.event.snippets','vim_lsp': 'lib.event.vim'}
  for [key,lib] in items(s:ECY_buildin_engine)
    call ECY_Install#RegisterClient(key, lib)
  endfor
"}}}
endfunction

function! ECY_Install#RegisterClient(engine_name, client_lib)
  if !exists('g:ECY_available_sources_lists')
    let g:ECY_available_sources_lists = {}
  endif
  let g:ECY_available_sources_lists[a:engine_name] = a:client_lib
endfunction

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
  return {'status':'0','description':"ok",'lib': {'html_lsp':'lib.sources.lsp_servers.html'}, 'name':'html_lsp'}
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
  return {'status':'0','description':"ok",'lib': {'snippets':'lib.sources.snippets.snippets'}, 'name':'snippets'}
"}}}
endfunction

function! ECY_Install#YCM()
"{{{
  if !utility#HasYCM()
    return {'status':'-1','description':"ECY failed to install it. You missing YCM. Please install that plugin, firstly. "}
  endif
  return {'status':'0','description':"ok",'lib': {'youcompleteme':'lib.sources.youcompleteme.ycm'}, 'name':'youcompleteme'}
"}}}
endfunction

function! ECY_Install#Pygment()
"{{{
  try
    call s:ExeCMD("pip install Pygments")
  catch
    return {'status':'-1','description':"ECY failed to install it. You missing Pygment. Please install that plugin, firstly. "}
  endtry
  return {'status':'0','description':"ok",'lib': {'pygment':'lib.sources.pygment.pygment'}, 'name':'pygment'}
"}}}
endfunction

function! ECY_Install#Install_cb(dict) abort
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
  call utility#ShowMsg('[ECY]' . string(a:dict['Name']) . a:dict['Description'], 2)
"}}}
endfunction

function! s:ExeCMD(cmd) abort
  " synchronous in vim
   execute "normal! :!" . a:cmd . "\<cr>" 
endfunction
