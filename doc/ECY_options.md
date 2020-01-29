Options for ECY
===============================================================================
Note-1: All the options of setting a key can be only set as '<xx>' such as '<F8>'
not "\<F8>", because there are different between that two styles in vim, check
vim's doc for more (:h key).
Example: 
  let g:ECY_show_switching_source_popup = '<C-g>'    √
  let g:ECY_show_switching_source_popup = "\<C-g>"   ×

-------------------------------------------------------------------------------

1. g:ECY_select_items
  default: ['<Tab>','<S-TAB>']

Must be a list containing 2 item, the first item is shifting down the items, 
the second one is shifting up the items.
Example(not default): 
  let g:ECY_select_items = ['<C-j>','<C-k>']



2. g:ECY_show_switching_source_popup
  default: '<Tab>'

Show a prompting board for current buffer's available sources.
Example(not default): 
  let g:ECY_select_items = '<F6>'



3. g:ECY_expand_snippets_key
  default: '<CR>' a.k.a '<Enter>'

Expand a snippet in Insert mode through ultsnippes while the popup 
windows is showing and there are snippet that can be expanded. 
Otherwise key will input into buffer.
Example(not default): 
  let g:ECY_expand_snippets_key = '<F2>'


4. g:ECY_choose_special_source_key
  default: [{'source_name':'snippets','invoke_key':'@', 'is_replace': v:true},
          {'source_name':'path','invoke_key':'/', 'is_replace': v:false},
          {'source_name':'label','invoke_key':'^', 'is_replace': v:true}]

Must be a list. Use xx sources when input xx key. After user leave Insert mode,
ECY will back to last source you using, such as you inputing '/' in Insert mode
, ECY will ask the source 'path' to provide items.
Note: before you seting this, make sure there are such source in the buffer you
using.
Example(not default): 
let g:ECY_choose_special_source_key = [{'source_name':'snippets','invoke_key':'~', 'is_replace': v:true}]



5. g:ECY_python3_cmd
  default: 'python'

CMD of executing python3. Pointing to python3 in your computer.
Example(not default): 
  let g:ECY_python3_cmd = 'd:/gvim/vimfiles/python3/python.exe'



6. g:ycm_autoclose_preview_window_after_completion
  default: v:true
Boolean. Same as YCM. Close preview windows after popup windows closed.



7. g:ECY_triggering_length
  default: 1

Must be a numbers. ECY show popup windows only when there are more 
than xx character.
Example(not default): 
  let g:ECY_triggering_length = 3



8. g:ECY_disable_for_files_larger_than_kb
  default: 1000     same as g:ycm_disable_for_files_larger_than_kb

Current buffer size more than xxx KB, then ECY won't work.
Example(not default): 
  let g:ECY_disable_for_files_larger_than_kb = 200


9. g:ECY_update_diagnosis_mode
  default: 1

When to update diagnosis.
1 means updating when text has changed but not in Insert mode.
2 means updating when text has changed in all mode.
Example(not default): 
  let g:ECY_update_diagnosis_mode = 2

10. g:ECY_rolling_key_of_floating_windows
  default: ['<C-h>', '<C-l>']

Available only when your vim support floating windows (popup windows).
the first one is rolling down, the second one is rolling up.
Example(not default): 
  let g:ECY_rolling_key_of_floating_windows = ['<C-j>', '<C-k>']


11. g:ECY_disable_diagnosis
  default: v:false

Wether to show diagnosis.
Example(not default): 
  let g:ECY_disable_diagnosis = v:true


12. g:ECY_use_floating_windows_to_be_popup_windows
  default: v:true

If your vim support floating windows, but you don't want to use it.
You can set to v:false.
Example(not default): 
  let g:ECY_use_floating_windows_to_be_popup_windows = v:false

13. g:ECY_preview_windows_size
  default: [[30, 50], [2, 14]]

Available only when your vim support floating windows.
Size of preview windows like:
[[minwidth, maxwidth], [minheight, maxheight]]
Example:
  let g:ECY_preview_windows_size = get(g:,'ECY_preview_windows_size',[[40, 60], [7, 14]])

14. g:ECY_PreviewWindows_style
  default: 'append'; only for now
on TODO

15. g:ECY_highlight_normal_matched_word   default: 'ECY_normal_matched_word'
    g:ECY_highlight_normal_items          default: 'ECY_normal_items'
    g:ECY_highlight_selected_matched_word default: 'ECY_selected_matched_word'
    g:ECY_highlight_selected_item         default: 'ECY_selected_item'
Color of popup windows.  you can ':hi ECY_normal_matched_word' to preview color.

Example:
You can define a highlight, and then set that variable.
hi your_highlight1		guifg=#945596	guibg=#073642	ctermfg=red	  ctermbg=darkBlue gui=bold
hi your_highlight2		guifg=#839496	guibg=#073642	ctermfg=white	ctermbg=darkBlue
let g:ECY_normal_matched_word    = 'your_highlight1'
let g:ECY_highlight_normal_items = 'your_highlight2'

16. g:ECY_diagnosis_erro       default: 'ECY_diagnosis_erro'
    g:ECY_diagnosis_warn       default: 'ECY_diagnosis_warn'
    g:ECY_diagnosis_highlight  default: 'ECY_diagnosis_highlight'

Color or Styles of diagnosis.
Example:
hi your_highlight1	guifg=#945596	guibg=#073642	ctermfg=red	  ctermbg=darkBlue gui=bold
hi your_highlight2  term=undercurl gui=undercurl guisp=DarkRed cterm=underline
let g:ECY_diagnosis_erro      = 'your_highlight1'
let g:ECY_diagnosis_highlight = 'your_highlight2'


17. g:ECY_erro_sign_highlight       default: 'ECY_erro_sign_highlight'
    g:ECY_warn_sign_highlight       default: 'ECY_warn_sign_highlight'

Styles of sign.
Example:
hi your_highlight1	guifg=#945596	guibg=#073642	ctermfg=red	  ctermbg=darkBlue gui=bold
hi your_highlight2  term=undercurl gui=undercurl guisp=DarkRed cterm=underline
let g:ECY_diagnosis_erro      = 'your_highlight1'
let g:ECY_diagnosis_highlight = 'your_highlight2'

