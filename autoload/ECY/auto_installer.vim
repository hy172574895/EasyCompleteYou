function ECY#auto_installer#Init() abort
  let g:ECY_auto_install_engines = get(g:,'ECY_auto_install_engines', ['clangd'])
  let s:can_be_auto_installed = ['clangd']

  " call ECY#auto_installer#AutoInstall()
endfunction

function ECY#auto_installer#AutoInstall() abort
"{{{
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
"}}}
endfunction


