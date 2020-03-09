" Author: Jimmy Huang (1902161621@qq.com)
" License: WTFPL

function! ECY#install#Init() abort
"{{{ must be called before setupPython()
   " put buildin engine name into Client
   " when Client finding no Clent event will omit it to genernal
  call ECY#install#AddEngineInfo('html_lsp',
        \'lib.event.html_lsp','lib.sources.lsp_servers.html',
        \function('ECY#install#html_lsp'), '', 'buildin')

  call ECY#install#AddEngineInfo('snippets',
        \'lib.event.vim','lib.sources.snippets.snippets',
        \function('ECY#install#Snippets'), '', 'buildin')

  call ECY#install#AddEngineInfo('youcompleteme',
        \'','lib.sources.youcompleteme.ycm',
        \function('ECY#install#YCM'), '', 'buildin')

  call ECY#install#AddEngineInfo('go_langserver',
        \'lib.event.go_langserver','lib.sources.lsp_servers.go_langserver',
        \function('ECY#install#Go_langserver'), '', 'buildin')

  call ECY#install#AddEngineInfo('go_gopls',
        \'lib.event.go_gopls','lib.sources.lsp_servers.go_gopls',
        \function('ECY#install#Go_gopls'), '', 'buildin')

  call ECY#install#AddEngineInfo('vim_lsp',
        \'lib.event.vim','lib.sources.lsp_servers.vim',
        \function('ECY#install#vim_lsp'), '', 'buildin')

  call ECY#install#AddEngineInfo('path',
        \'lib.event.path','lib.sources.path.path',
        \'', '', 'buildin')
"}}}
endfunction

function! ECY#install#AddEngineInfo(engine_name, client_module_path,
      \server_module_path, install_fuc, uninstall_fuc, ...) abort
"{{{
  if !exists('g:ECY_all_engine_info')
    let g:ECY_all_engine_info = {}
  endif
  if a:server_module_path == ''
    throw '[ECY] server module can not be empty.'
  endif
  if a:0 == 1 " a:0 means length of param.
    " buildin engine
    call ECY#install#RegisterClient(a:engine_name, a:client_module_path)
    call ECY#install#RegisterServer(a:engine_name, a:server_module_path)
  else
    " plugin, client_module_path is full path
    if a:client_module_path != ''
      let l:client = ECY#install#ParseModuleInfo(a:client_module_path)
      call ECY#install#RegisterClient(a:engine_name, l:client['lib'], l:client['path'])
    else
      " user can dertermine to use the default client.
      call ECY#install#RegisterClient(a:engine_name, '')
    endif
    " server module can not be empty
    let l:server = ECY#install#ParseModuleInfo(a:server_module_path)
    call ECY#install#RegisterServer(a:engine_name, l:server['lib'], l:server['path'])
  endif
  call ECY#install#RegisterInstallFunction(a:engine_name, a:install_fuc)
  call ECY#install#RegisterUnInstallFunction(a:engine_name, a:uninstall_fuc)

  let g:ECY_all_engine_info[a:engine_name]                 = {}
  let g:ECY_all_engine_info[a:engine_name]['name']         = a:engine_name
  let g:ECY_all_engine_info[a:engine_name]['client']       = a:client_module_path
  let g:ECY_all_engine_info[a:engine_name]['server']       = a:server_module_path
  let g:ECY_all_engine_info[a:engine_name]['install_fuc']  = a:install_fuc
  let g:ECY_all_engine_info[a:engine_name]['unintall_fuc'] = a:uninstall_fuc
  if a:0 == 1
    let g:ECY_all_engine_info[a:engine_name]['is_buildin'] = v:true
  else
    let g:ECY_all_engine_info[a:engine_name]['is_buildin'] = v:false
  endif
"}}}
endfunction

function! ECY#install#ParseModuleInfo(module_full_path) abort
"{{{
  let l:module_full_path = tr(a:module_full_path, '\', '/')
  " remove '.py'
  let l:module_full_path = fnamemodify(l:module_full_path, ':r')

  let i = 0
  let l:lib = ''
  while i < 3
    if i == 0
      let l:lib = fnamemodify(l:module_full_path, ':t')
    else
      let l:lib = fnamemodify(l:module_full_path, ':t') . '.' . l:lib
    endif
    let l:module_full_path = fnamemodify(l:module_full_path, ':h')
    let i += 1
  endw

  let l:module_full_path .= '/'
  return {'path': l:module_full_path, 'lib': l:lib}
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
  for [key, info] in items(g:ECY_all_engine_info)
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
    if info['is_buildin']
      let l:temp .= ' BuiltIn  '
    else
      let l:temp .= ' Plugin   '
    endif
    let l:temp .= key

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

function! ECY#install#RegisterServer(engine_name, server_lib, ...) abort
  if !exists('g:ECY_server_info')
    let g:ECY_server_info = {}
  endif
  let g:ECY_server_info[a:engine_name] = {}
  if a:0 == 1
    let g:ECY_server_info[a:engine_name] = {'lib': a:server_lib, 'path': a:1}
  else
    let g:ECY_server_info[a:engine_name] = {'lib': a:server_lib, 'path': ''}
  endif
endfunction

function! ECY#install#RegisterClient(engine_name, client_lib, ...) abort
"{{{
  if !exists('g:ECY_engine_client_info')
    let g:ECY_engine_client_info = {}
  endif

  if a:0 == 1
    call s:ImportClientLib(a:1)
    try
      let l:temp = "py3 'import " . a:client_lib . "'"
      execute l:temp
    catch 
      throw "[ECY-".a:engine_name."] can not import Client module."
    endtry
    let g:ECY_engine_client_info[a:engine_name] = {'lib': a:client_lib, 'path': a:1}
  else
    " buildin engine
    let g:ECY_engine_client_info[a:engine_name] = {'lib': a:client_lib, 'path': ''}
  endif
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
