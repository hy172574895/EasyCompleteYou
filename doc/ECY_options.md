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
Must be a list. 


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


