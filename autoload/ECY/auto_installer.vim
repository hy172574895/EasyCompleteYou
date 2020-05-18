function ECY#auto_installer#Init() abort
  let g:ECY_auto_install_engines = get(g:,'ECY_auto_install_engines', [])
  let s:can_be_auto_installed = ['clangd']
  call ECY#auto_installer#ReadAutoInstalled() " init
endfunction

function ECY#auto_installer#AutoInstall() abort
"{{{
  if len(g:ECY_auto_install_engines) == 0
    let l:temp = ['[ECY] g:ECY_auto_install_engines is empty.']
    call ECY#utility#ShowMsg(l:temp, 2)
    return
  endif

  let l:to_install = []
  " check
  for item in g:ECY_auto_install_engines
    if !ECY#utility#IsInList(item, s:can_be_auto_installed)
      let l:temp = ["[ECY] Have no " . item, 'Please install it manually.']
      call ECY#utility#ShowMsg(l:temp, 2)
      continue
    endif
    call add(l:to_install, item)
  endfor
  call s:RunInstaller(l:to_install)
  call ECY#auto_installer#ReadAutoInstalled()
"}}}
endfunction

function s:RunInstaller(to_install) abort
"{{{
  if type(a:to_install) != 3 || len(a:to_install) <= 0
    return
  endif
  " s:installer_script = 'python3 /EXY_home/python/third_party/auto_installer.py --xxx'
  let s:installer_script = g:ECY_python3_cmd . ' ' . 
        \g:ECY_python_script_folder_path . '/third_party/auto_installer.py'
  let l:flags = ''
  for item in a:to_install
    let l:flags .= ' --' . item
  endfor
  let s:installer_script .= l:flags
  let l:temp = ['Auto Installing' . l:flags]
  call ECY#utility#ShowMsg(l:temp, 2)
  call ECY#utility#ExeCMD(s:installer_script)
"}}}
endfunction

function ECY#auto_installer#ReadAutoInstalled() abort
"{{{ read installed engines that installed by auto installing script.
  let s:installed_engines_path = g:ECY_python_script_folder_path . '/third_party/installed_engines.json'
  let s:installed_engines = {}
  if !filereadable(s:installed_engines_path)
    return s:installed_engines
  endif
  try
    let l:read_content_list = readfile(s:installed_engines_path)
    let l:read_content_list = l:read_content_list[0]
    " the 'installed_engines.json' might not be init yet.
    let s:installed_engines = json_decode(l:read_content_list)
    call s:InitEnginesVariable(s:installed_engines)
  catch 
  endtry
  return s:installed_engines
"}}}
endfunction

function s:InitEnginesVariable(installed_engines) abort
"{{{
  for [key, value] in l:installed_engines
    try
      let l:Fuc = function('ECY#auto_installer#' . key)
      call l:Fuc(value)
    catch 
      call ECY_main#Log('auto installer failed. ' . key)
    endtry
  endfor
"}}}
endfunction

function ECY#auto_installer#clangd(dependences) abort
"{{{
  let g:ECY_clangd_starting_cmd = dependences['clangd'] . 'clangd'
"}}}
endfunction
