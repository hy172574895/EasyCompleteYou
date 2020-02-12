" Author: Jimmy Huang (1902161621@qq.com)
" License: WTFPL

function! s:SetUpLeaderf() abort
"{{{
  " In order to be listed by :LeaderfSelf
  call g:LfRegisterSelf("ECY_selecting", "Plugin for EasyCompleteYou")

  " In order to make this plugin in Leaderf available 
  let l:extension = {
              \   "name": "ECY_selecting",
              \   "help": "check out Doc of ECY",
              \   "registerFunc": "leaderf_ECY#items_selecting#register",
              \   "arguments": [
              \   ]
              \ }
  call g:LfRegisterPythonExtension(l:extension.name, l:extension)
  let s:is_init_leaderf_support = v:true
"}}}
endfunction

call s:SetUpLeaderf()
