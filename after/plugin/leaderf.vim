" Author: Jimmy Huang (1902161621@qq.com)
" License: WTFPL

function! s:SetUpLeaderf() abort
"{{{
  " In order to be listed by :LeaderfSelf
  call g:LfRegisterSelf("ECY_selecting", "Plugin for EasyCompleteYou")

  " In order to make this plugin in Leaderf available 
  let s:extension = {
              \   "name": "ECY_selecting",
              \   "help": "check out Doc of ECY",
              \   "registerFunc": "leaderf_ECY#items_selecting#register",
              \   "arguments": [
              \   ]
              \ }
  call g:LfRegisterPythonExtension(s:extension.name, s:extension)
"}}}
endfunction

try
  if g:loaded_easycomplete
    call s:SetUpLeaderf()
  endif
catch 
  call ECY#utility#ShowMsg("[ECY] You have no Leaderf.", 2)
endtry
