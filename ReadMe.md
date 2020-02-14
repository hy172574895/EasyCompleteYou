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
# Brief Introduction
1. Automatically compatible with [YCM](https://github.com/ycm-core/YouCompleteMe), can be a extension for YCM.
2. Fluent completion.
3. Wrote with Python3.
4. Fuzzy-find support like YCM.
5. Buildin [LSP](https://microsoft.github.io/language-server-protocol).
6. Out of the box.

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
> Plug 'hy172574895/EasyCompleteYou'

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

name|language|abilities|dependence|doc link
--|:--:|--:|--:|--:
label|all|completion|-|
snippet|all|completion<br>snippets-expanding|-|
path|all|completion|-|
python_jedi|python|completion<br>diagnosis<br> goto-definition<br> find-symbols<br> goto-declaration<br> find-reference<br> snippets-expanding|[jedi](https://pypi.org/project/jedi/)<br>[pyflakes](https://pypi.org/project/pyflakes/)|
html_lsp|html, xhtml|completion<br> diagnosis<br> snippet-expanding<br>find-symbols|nodejs<br>[html-LSP](https://www.npmjs.com/package/vscode-html-languageservice) <br> [HTMLHint](https://www.npmjs.com/package/htmlhint)|
vim_lsp|vimL|completion<br> diagnosis<br> snippet-expanding<br>find-symbols|nodejs<br>[vim-LSP](https://www.npmjs.com/package/vim-language-server)|

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

### Q: Whe not use Ale to do diagnosis?
A: Ale use job(channel) feature to send data to linter, but ECY use python3 instead.
And every completion that ECY do will send data of current buffer to Server, on
the same time, ECY can return diagnosis; that will be send only once. Using Ale
will do it twice, sending to linter and ECY's Server.
