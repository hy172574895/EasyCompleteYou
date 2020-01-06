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
# Brief Introduction
1. Collaborate with ycm, can be a extend for YCM.
2. Fluently completion.
3. Write in Python3.
4. Fuzzy-find support like YCM.
5. Buildin LSP.
6. Out of the box.

# How to install

### Requires

1. Python >= 3.0  
strongly suggest to use python3 (> 3.6)  
2. Vim >= 8.0  
strongly suggest to use the newest one(Vim 8.2).  

### Install  

#### Options 1:
Using some Plugin-manager like Plug-vim or Vunble:  
Put the line into your vimrc, then install it.  
`hy172574895/EasyCompleteYou`  

#### Options 2:  
download the whole repository and put it into vim's starting dir  

# Usage  

After the install ECY successfully, there are 3 buildin completion source that
is `label`, `path` and `python`.  
Firstly ECY will detect the filetype of your buffer that you areusing.  
Knowing the filetype, then ECY asks the server what sources are available 
on this filetype.  
So if you want a specific source works on a buffer, you can change the filetype 
by the vim that `set &filetype=java` on the buffer you want to change.  

## Enable more.

there only three buildin sources which is `label`,`python`,`path`
after you installed ECY.  
If you want ECY work on `HTML`, you can activate a source by:  
`:call ECY_Installer('HTML_LSP')` in vim  
*Importance*: There are might dependence while you install a need source of ECY
So check out the Doc carefully and install the dependence before you install one.

Here the full list of sources that ECY supports. 

## Cooperate with `Ultisnips`
We are strongly suggest you to install `Ultisnips` to get better experience.
Check out doc of ultisnips, to change some default mappings such as expanding a 
snippet.
the default values of ultisnips for `g:UltiSnipsExpandTrigger` is '<tab>',  
but this values conflict with ECY that `g:ECY_select_items`.  
So you have to change one of them.  
And ECY had done that for you, after you enable ECY, it will change   
g:UltiSnipsExpandTrigger to '<F1>' automatically. you can also expand a snippet  
by `g:ECY_expand_snippets_key` that default values is '<CR>' when you are   
choosing a snippet in ECY popup windows.  

Some useful default mappings of Ultisnips.  
`g:UltiSnipsJumpForwardTrigger          <c-j>`  
`g:UltiSnipsJumpBackwardTrigger         <c-k>`  
How to change the default value to you want.  
All of them are variables of vimL, so you can put a line like    
`let g:ECY_expand_snippets_key = '<F7>'` into your vimrc.  

# Q&A
Q: Why there are a few of Snippets options to complete? I need more.
A: ECY rely on `ultisnips` which is a engine that fill in the snippets fragment.
What snippets you provide to `ultisnips`, what completion options you got in ECY.
So there are so many nice and mature snippets that made by other fellows such as
`honza/vim-snippets` `CoreyMSchafer/code_snippets`. If you want more, install 
the snippets you admire and `ultisnips` will analize that snippets then provide
to ECY and last provide to users.

Q: Why I need to install `Leaderf`, and only `Leaderf`?
A: There are so many tools like `Leaderf` such as `fzf-vim` `ctrlP`, that's true
. And the answer is same as "Why ECY only supports ultisnips?"   
Firstly, they are all rely on python same as ECY. Secondly, according to me,
they are the best solutions in vim. Thirdly, supporting so many different plugins
could be a disadvantage of ECY, that make ECY so heavy.
`Anything can be located by fuzzy search` that is one of ECY's principles, that
`Leaderf` hightly fit with ECY.
*Importance*: ECY will not support any plugin that functions resemble with `Leaderf`
and `ultisnips` unless there are critical demands.

Q: 
