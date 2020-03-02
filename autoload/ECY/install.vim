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
         \'html_lsp': function('ECY#install#html_lsp'),
         \'snippets': function('ECY#install#Snippets'),
         \'youcompleteme': function('ECY#install#YCM'),
         \'go_langserver': function('ECY#install#Go_langserver'),
         \'go_gopls': function('ECY#install#Go_gopls'),
         \'vim_lsp': function('ECY#install#vim_lsp')
         \}

  for [key, lib] in items(s:ECY_buildin_engine_client)
    " if a new engine did not register a client, ECY will use the default one
    " instead.
    call ECY#install#RegisterClient(key, lib)
  endfor

  for [key, Fuc] in items(s:ECY_buildin_engine_installer)
    call ECY#install#RegisterInstallFunction(key, Fuc)
  endfor

  " TODO
  let s:ECY_available_engine_uninstaller = {}
  for [key, Fuc] in items(s:ECY_available_engine_uninstaller)
    call ECY#install#RegisterUnInstallFunction(key, Fuc)
  endfor
"}}}
endfunction

function! ECY#install#RegisterInstallFunction(engine_name, Installer) abort
  if !exists('g:ECY_available_engine_installer')
    let g:ECY_available_engine_installer = {}
  endif
  let g:ECY_available_engine_installer[a:engine_name] = a:Installer
endfunction

fun! s:ImportClientLib(dirs) abort
py3 "import sys"
let l:temp = "py3 sys.path.append('" . a:dirs . "')"
execute l:temp
endf

function! ECY#install#ListEngine_cb(msg, timer_id) abort
"{{{
  let g:abcd = a:msg
  let l:to_show = []
  call add(l:to_show, '[ECY] Engine lists:')
  call add(l:to_show, '-------------------')
  call add(l:to_show, '√ installed; × disabled.')
  call add(l:to_show, ' ')
  let i = 1
  for [key, lib] in items(g:ECY_available_engine_lists)
    let l:temp  = ''
    let l:installed = v:false
    for item in a:msg['EngineInfo']
      let l:temp = ' ×'
      if item['Name'] == key
        let l:installed = v:true
        let l:installed_info = item
        let l:temp = ' √'
        break
      endif
    endfor
    let l:temp .= ' ' . string(i). '.'
    if has_key(s:ECY_buildin_engine_client, key)
      let l:temp .= ' BuiltIn  '
    else
      let l:temp .= ' Plugin   '
    endif
    let l:temp .= key

    " if l:installed
    "   let l:temp .= key
    " endif

    call add(l:to_show, l:temp)
    let i += 1
  endfor
  let l:showing = ''
  for item in l:to_show
    let l:showing .= item . "\n"
  endfor
  echo l:showing
"}}}
endfunction

function! ECY#install#RegisterUnInstallFunction(engine_name, Uninstalller) abort
  if !exists('g:ECY_available_engine_uninstaller')
    let g:ECY_available_engine_uninstaller = {}
  endif
  let g:ECY_available_engine_uninstaller[a:engine_name] = a:Uninstalller
endfunction

function! ECY#install#RegisterClient(engine_name, client_lib, ...) abort
"{{{
  if !exists('g:ECY_available_engine_lists')
    let g:ECY_available_engine_lists = {}
  endif
  if a:0 == 1
    call s:ImportClientLib(a:1)
    try
      let l:temp = "py3 'import " . a:client_lib . "'"
      execute l:temp
    catch 
      throw "[ECY-".a:engine_name."] can not import Client module."
    endtry
  endif
  let g:ECY_available_engine_lists[a:engine_name] = a:client_lib
"}}}
endfunction

function! ECY#install#html_lsp() abort
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

function! ECY#install#vim_lsp() abort
"{{{
  " options: 1. cmd for starting Server
  " let l:temp = get(g:,'ECY_html_lsp_starting_cmd','html-languageserver --stdio') 
  " if !executable('vim-language-server')
  "   if !executable('npm')
  "     return {'status':'-1','description':"ECY failed to install it by NPM. You missing server's implement and NPM."}
  "   endif
  "   call s:ExeCMD("npm i vim-language-server")
  " endif
  try
    call UltiSnips#SnippetsInCurrentScope(1)
  catch
    echo "[ECY] We hightly recommend you to install UltiSnips plugin for better experience."
  endtry
  return {'status':'0','description':"ok",'lib': 'lib.sources.lsp_servers.vim', 'name':'vim_lsp', 'path': ''}
"}}}
endfunction

function! ECY#install#Go_gopls() abort
"{{{
  if !executable('gopls')
    return {'status':'-1','description':"ECY failed to install it. You missing go-langserver Server. Please install that plugin, firstly. "}
  endif
  return {'status':'0','description':"ok",'lib': 'lib.sources.lsp_servers.go_gopls', 'name':'go_gopls', 'path': ''}
"}}}
endfunction

function! ECY#install#Go_langserver() abort
"{{{
  if !executable('go-langserver')
    return {'status':'-1','description':"ECY failed to install it. You missing go-langserver Server. Please install that plugin, firstly. "}
  endif
  return {'status':'0','description':"ok",'lib': 'lib.sources.lsp_servers.go_langserver', 'name':'go_langserver', 'path': ''}
"}}}
endfunction

function! ECY#install#Snippets() abort
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

function! ECY#install#YCM() abort
"{{{
  if !ECY#utility#HasYCM()
    return {'status':'-1','description':"ECY failed to install it. You missing YCM. Please install that plugin, firstly. "}
  endif
  return {'status':'0','description':"ok",'lib':'lib.sources.youcompleteme.ycm', 'name':'youcompleteme', 'path': ''}
"}}}
endfunction

function! ECY#install#Pygment() abort
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
