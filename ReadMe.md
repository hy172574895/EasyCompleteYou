              ──────────────────────────────────────────────────
              ─██████████████─██████████████─████████──████████─
              ─██░░░░░░░░░░██─██░░░░░░░░░░██─██░░░░██──██░░░░██─
              ─██░░██████████─██░░██████████─████░░██──██░░████─
              ─██░░██─────────██░░██───────────██░░░░██░░░░██───
              ─██░░██████████─██░░██───────────████░░░░░░████───
              ─██░░░░░░░░░░██─██░░██─────────────████░░████─────
              ─██░░██████████─██░░██───────────────██░░██───────
              ─██░░██─────────██░░██───────────────██░░██───────
              ─██░░██████████─██░░██████████───────██░░██───────
              ─██░░░░░░░░░░██─██░░░░░░░░░░██───────██░░██───────
              ─██████████████─██████████████───────██████───────
              ──────────────────────────────────────────────────

              EASILY COMPLETE YOU.
---
---
[中文版文档](https://gitee.com/Jimmy_Huang/EasyCompleteYou) | **English(currently)**
---

# Brief Introduction
1. Automatically compatible with [YCM](https://github.com/ycm-core/YouCompleteMe), can be a extension for YCM.
2. Fluent completion.
3. Wrote with Python3.
4. Fuzzy-find support like YCM.
5. Buildin [LSP](https://microsoft.github.io/language-server-protocol).
6. Out of the box.

[Screenshots of ECY -->>>>](https://github.com/hy172574895/EasyCompleteYou/issues/1)

# How to install

### Requires

1. Python >= 3.0  
strongly suggest to use python3.6+  
[How to get python support for vim?](https://vi.stackexchange.com/questions/11526/how-to-enable-python-feature-in-vim)
2. Vim >= 8.0  
strongly suggest to use the newest one(Vim 8.2).  

### Install  

#### Options 1:
Using some Plugin-manager like vim-plug or Vunble:  
Put the line into your vimrc, then install it.  

For vim-plug:
> Plug 'hy172574895/EasyCompleteYou'

For Vunble:
> Plugin 'hy172574895/EasyCompleteYou'

For Someone in fucking China. A mirror.
> Plug 'https://gitee.com/Jimmy_Huang/EasyCompleteYou'


#### Options 2:  
Download the whole repository and put it into vim's `runtimepath`.  

#### Options 3:  
Still confusing with installation? 
Check [here](https://vi.stackexchange.com/questions/613/how-do-i-install-a-plugin-in-vim-vi) for detail infomation.  

# Usage  

After successfully installed ECY, there are 3 buildin completion engine that
is `label`, `path` and `python`. 

Firstly ECY will detect the filetype of your buffer that you are using. Knowing the filetype, then ECY asks the server what engines are available on this filetype.  

So if you want a specific engine works on a buffer, you can change the filetype by the vim that `:set &filetype=java` on the buffer you want to change.

You can also check available engine of ECY by pressing `<Tab>` in normal mode.
It will show a floating windows containing all the engine you can use in current buffera. Change `<Tab>`  by `g:ECY_show_switching_source_popup`.

## How to change the default value to you want?
All of them are variables of vimL, so you can put a code such as     
`let g:ECY_expand_snippets_key = '<F7>'` into your [vimrc](https://stackoverflow.com/questions/10921441/where-is-my-vimrc-file).  

## Enable more.

there only three buildin engine which is `label`,`python` and `path` after you installed ECY. If you want ECY work on `HTML`, you can activate that engine by: `:call ECY_Installer('HTML_LSP')` in vim.  

**Importance**: There are might dependence while you installing a engine of ECY
So check out the following lists carefully and install the dependence before you install it.

**Notes: you can not use `snippets-expanding` without `Ultisnips`,  can not use`goto-definition`, `goto-declaration`, `find-symbols`, `find-reference` without `LeaderF`.**  
Here the full lists of engine that ECY supports. 

name|programming language|abilities|dependence|doc link
--|:--:|--:|--:|--:
label|all|completion|-|
snippet|all|completion<br>snippets-expanding|-|
path|all|completion|-|
python_jedi|python|completion<br>diagnosis<br> goto-definition<br> find-symbols<br> goto-declaration<br> find-reference<br> snippets-expanding|[jedi](https://pypi.org/project/jedi/)<br>[pyflakes](https://pypi.org/project/pyflakes/)|
html_lsp|html, xhtml|completion<br> diagnosis<br> snippet-expanding<br>find-symbols|nodejs<br>[html-LSP](https://www.npmjs.com/package/vscode-html-languageservice) <br> [HTMLHint](https://www.npmjs.com/package/htmlhint)|
vim_lsp|vimL|completion<br> diagnosis<br> snippet-expanding<br>find-symbols|nodejs<br>[vim-LSP](https://www.npmjs.com/package/vim-language-server)|
go_langserver|golang|completion<br>snippets-expanding|[go-langserver](https://github.com/sourcegraph/go-langserver)|
go_gopls|golang|completion<br>diagnosis<br>snippets-expanding<br>goto-definition<br>goto-reference|[gopls](https://github.com/golang/tools/blob/master/gopls/README.md)|

## Cooperate with [Ultisnips](https://github.com/SirVer/ultisnips)
`Ultisnips` is a separate plugin, so you have to install it separately.
We are strongly suggest you to install `Ultisnips` to get better experience.
---
Check out the doc of ultisnips, to change some default mappings such as expanding a snippet. the default values of ultisnips for `g:UltiSnipsExpandTrigger` is '\<Tab\>', but this values conflict with ECY that `g:ECY_select_items`.  

So you have to change one of them. And ECY had done that for you, after you enable ECY, it will change `g:UltiSnipsExpandTrigger` to '\<F1\>' automatically. you can also expand a snippet by `g:ECY_expand_snippets_key` that default values is '[\<CR\>](https://stackoverflow.com/questions/22142755/what-is-the-meaning-of-a-cr-at-the-end-of-some-vim-mappings)' when you are choosing a snippet or expandable item in ECY popup windows.  

Some useful default mappings of Ultisnips. Check doc of ultisnips for more.  
> g:UltiSnipsJumpForwardTrigger   --   default: \<c-j\>  
> g:UltiSnipsJumpBackwardTrigger  --  default: \<c-k\>   

## Cooperate with [LeaderF](https://github.com/Yggdroot/LeaderF)
`LeaderF` is a separate plugin, so you have to install it separately.
We are strongly suggest you to install `LeaderF` to get better experience.
---
What `LeaderF` can do for ECY? To help ECY to locate a position and provide selecting to users. So if you have no 
`LeaderF` you can not use some functions of ECY such as `Goto-definition`.

Some useful command of `LeaderF` are follow.  
[what is \<leader\> in vim?](https://stackoverflow.com/questions/1764263/what-is-the-leader-in-a-vimrc-file)
> :LeaderfBuffer or \<leader\>b   

> :LeaderfFile or \<leader\>f  

Especially the `ctags` support of `LeaderF`

# Configuration

## Key Variables
All the options of setting a key can be only set as '<xx>' such as '<F8>' not "\<F8>", because there are different between that two styles in vim.

For Example:   
```
  let g:ECY_show_switching_source_popup = '<C-g>'    √

  let g:ECY_show_switching_source_popup = "\<C-g>"   ×

  let g:ECY_show_switching_source_popup = "\<C-g\>"  ×


  let g:ECY_select_items = ['<C-j>', '<C-k>']         √

  let g:ECY_select_items = [<C-j>, <C-k>]             ×
```

variable name|default values|description
--|:--:|--:
`g:ECY_show_switching_source_popup`|\<Tab\>|**String**. Show a prompting board in normal mode for current buffer's available engines.
`g:ECY_expand_snippets_key`|\<CR\> a.k.a \<Enter\>|**String**. Expand a snippet in Insert mode by ultsnippes while the popup is showing and there are snippet that can be expanded. 
`g:ECY_show_switching_source_popup`|\<Tab\>|**String**. Show a prompting board for current buffer's available engines.
`g:ECY_select_items`|['\<Tab\>','\<S-TAB\>']|**String**. Must be a list containing 2 item, the first value is shifting down the items, the second one is shifting up the items.
`g:ECY_rolling_key_of_floating_windows`|['\<C-h\>', '\<C-l\>']|**String**. Available only when your vim support floating windows (popup windows). the first one is rolling down, the second one is rolling up.

## String&Int&Boolean Variables(part, check engine document for more)
For Example:   
```
  let g:ECY_python3_cmd = '/home/python38/python.exe'           √

  let g:ECY_python3_cmd = '/home/python38/python.exe --debug'   ×


  let g:ECY_preview_windows_size = [[30, 50], [2, 14]]     √

  let g:ECY_preview_windows_size = [30, 50, 2, 14]         ×


  let g:ECY_use_floating_windows_to_be_popup_windows = v:false    √

  let g:ECY_use_floating_windows_to_be_popup_windows = v:true     √

  let g:ECY_use_floating_windows_to_be_popup_windows = false      ×

  let g:ECY_use_floating_windows_to_be_popup_windows = 'v:false'  ×


  let g:ECY_disable_for_files_larger_than_kb = 200     √

  let g:ECY_disable_for_files_larger_than_kb = -1      ×

  let g:ECY_disable_for_files_larger_than_kb = 0       ×


```
variable name|default values|description
--|:--:|--:
`g:ECY_python3_cmd`|'python'|**String**. CMD of executing python3. Pointing to python3 bin in your computer.
`g:ycm_autoclose_preview_window_after_completion`|v:true|**Boolean**. Same as YCM. Close preview windows after popup windows closed.
`g:ECY_disable_diagnosis`|v:false|**Boolean**. Wether to show diagnosis.
`g:ECY_use_floating_windows_to_be_popup_windows`|v:true|**Boolean**. If your vim supports floating windows, but you don't want to use it as popup, you can set to v:false.
`g:ECY_triggering_length`|1|**Int**. ECY show popup windows only when there are more than xx character.
`g:ECY_disable_for_files_larger_than_kb`|1000|**Int**. Same as `g:ycm_disable_for_files_larger_than_kb` of YCM. Current buffer size more than xxx KB, then ECY won't work.
`g:ECY_update_diagnosis_mode`|1|**Int**. 1 means update diagnosis both in Insert mode and Normal mode. 2 means only update diagnosis in Normal mode.
`g:ECY_preview_windows_size`|[[30, 50], [2, 14]]|**Lists**. Available only when your vim support floating windows. Size of preview windows like: [[minwidth, maxwidth], [minheight, maxheight]]

## Style Variables
For Example:   
```
  hi your_highlight1  guifg=#945596	guibg=#073642	ctermfg=red	ctermbg=darkBlue gui=bold
  let g:ECY_normal_matched_word  = 'your_highlight1'  √

  let g:ECY_normal_matched_word  = 'a_hightlight_does_not_exits'  ×
```

variable name|default values|description
--|:--:|--:
`g:ECY_highlight_normal_matched_word`|'ECY_normal_matched_word'|**String**. Only available when you have floating windows.
`g:ECY_highlight_normal_items`|'ECY_normal_items'|**String**. Only available when you have floating windows.
`g:ECY_highlight_selected_matched_word`|'ECY_selected_matched_word'|**String**. Only available when you have floating windows.
`g:ECY_highlight_selected_item`|'ECY_selected_item'|**String**. Only available when you have floating windows.
`g:ECY_diagnosis_erro`|'ECY_diagnosis_erro'|**String**. Color or Styles of diagnosis error.
`g:ECY_diagnosis_warn`|'ECY_diagnosis_warn'|**String**. Color or Styles of diagnosis warning.
`g:ECY_diagnosis_highlight`|'ECY_diagnosis_highlight'|**String**. Color or Styles of diagnostic underline hint.
`g:ECY_erro_sign_highlight`|'ECY_erro_sign_highlight'|**String**. Color of error sign.
`g:ECY_warn_sign_highlight`|'ECY_warn_sign_highlight'|**String**. Color of warning sign.

# Q&A

### Q: Why there are a few of [Snippets](https://www.techopedia.com/definition/5472/snippet-programming) options to complete? I need more.  
A: ECY rely on `Ultisnips` which is a engine that fill in the snippets fragment. What snippets you provide to `Ultisnips`, what completion options you got in ECY.
So there are so many nice and mature snippets that made by other fellows such as  
 [honza/vim-snippets](https://github.com/honza/vim-snippets) or [CoreyMSchafer/code_snippets](https://github.com/CoreyMSchafer/code_snippets). If you want more, install the snippets you admire and `Ultisnips` will analize that snippets then provide to ECY and last to users.  

### Q: Why I need to install [LeaderF](https://github.com/Yggdroot/LeaderF), and only `LeaderF`?    
A: There are so many tools like `LeaderF` such as `fzf-vim` `ctrlP`, that's true. And the answer is same as "Why ECY only supports ultisnips"? Firstly, they are all rely on python same as ECY. Secondly, according to me, they are the best solutions in vim. Thirdly, supporting so many different plugins could be a disadvantage of ECY, that make ECY so heavy.  

> Anything can be located by fuzzy search.

which is one of ECY's principles, that `LeaderF` hightly fit with ECY.  
**Importance**: ECY will not support any plugin that functions resemble with `LeaderF` and `ultisnips` unless there are critical demands.  
  
### Q: I only need a engine for python, why ECY install all engine's code in my computer?
A: For out of the box, better.  You should no worry about ECY code in you computer, because it is python script(totally open source) and its size is not big and even small.

### Q: Why not use Ale to do diagnosis?
A: Ale use job(channel) feature to send data to linter, but ECY use python3 instead.
And every completion that ECY do will send data of current buffer to Server, on
the same time, ECY can return diagnosis; that will be send only once. Using Ale
will do it twice, sending to linter and ECY's Server.

# Debug & Contribution
## How to debug?
Put `let g:ECY_debug = v:true` into your vimrc and restart Vim.  
Reproduce the bug, then you can find a log file of `./python/client/ECY_client.log` and `./python/server/ECY_server.log`

## Report bug.
Thanks, and go [here]()

## How to PR?
Before pulling a request to ECY's master, make sure you had discussed that with a issuse `what your code can do for ECY`?  
We are very welcome to contribute ECY.

# Credit & Donate
**Major maintainers:** 
1. Jimmy Huang (1902161621@qq.com)
2.

**Sponsors:**  
nobody
