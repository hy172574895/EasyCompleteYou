
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
[English](https://github.com/hy172574895/EasyCompleteYou) | **中文版文档(当前)**
---

# 介绍
1. 自动兼容 [YCM](https://github.com/ycm-core/YouCompleteMe), 可以作为YCM的补充。
2. 流畅的补全.
3. 使用 Python3 编写.
4. 类似YCM的模糊匹配.
5. 内置 [LSP](https://microsoft.github.io/language-server-protocol).
6. 开箱即用.

[运行截图 -->>>>](https://gitee.com/Jimmy_Huang/EasyCompleteYou/issues/I1A5UA)

# 怎么安装

### 依赖

1. Python >= 3.0  
强烈建议使用 python3.6以上版本  
[How to get python support for vim?](https://vi.stackexchange.com/questions/11526/how-to-enable-python-feature-in-vim)
2. Vim >= 8.0  
强烈建议使用最新的vim(Vim 8.2).  

### 安装  

#### 途径 1:
使用插件管理插件 例如：Plug-vim or Vunble:  
把下面一代代码插入，然后安装即可.  
> Plug 'https://gitee.com/Jimmy_Huang/EasyCompleteYou'

#### 途径 2:  
下载整个工程，然后让vim能索引到ECY，即把ECY的工程目录放进vim的 `runtimepath`.  

#### 途径 3:  
新手?  不知道怎么安装插件？ 没关系  
去 [这里](https://vi.stackexchange.com/questions/613/how-do-i-install-a-plugin-in-vim-vi) 看看.  

# 使用  

当你成功地安装ECY后, 会有三个默认安装的引擎
： `label`, `path` 和 `python`. 

当你打开一个文件的时候，ECY会首先检测该文件的文件类型（filetype）. 得知文件类型后, ECY客户端会向服务端请求 该文件类型可以使用哪些 引擎.  

所以, 如果你想某个特定的引擎在某个文件也可以被使用的话。 你可以通过vim命令： `:set &filetype=java` 来修改文件类型，从而使ECY生效.

同样的，如果你想知道当前有什么引擎可以在当前文件使用，你可以在vim的normal mode 按下 `<Tab>` 来查看。
默认使用的是`<Tab>`  你可以通过变量 `g:ECY_show_switching_source_popup`来改变默认按键.

## 如何修改默认按键?
开箱即用是 ECY的宗旨。  
所有的默认值都可以通过修改变量来改变。     
例如：
把`let g:ECY_expand_snippets_key = '<F7>'` 放入 [vimrc](https://stackoverflow.com/questions/10921441/where-is-my-vimrc-file).  
就可以修改`展开片段按键 ` 的默认值。  

## 启用更多引擎.

三个默认引擎能满足的人太少了. 如果你想ECY也可以在前端工作 `HTML` 工作的话, 你可以在vim中通过命令: `:call ECY_Installer('HTML_LSP')` 来启用`HTML` 引擎.  
**重要提示**: 当前启用一个新的引擎的使用，请确保 对应新引擎的依赖环境已经准备好了。
所以，在你安装一个新的引擎之前，请仔细阅读对应文档.

**注意: 没有安装 `Ultisnips` 就不能使用 `snippets-expanding` ,  没有安装 `LeaderF` 就不能使用`goto-definition`, `goto-declaration`, `find-symbols`, `find-reference`。**

下列是在ECY完整的，目前可使用的引擎 ：

名字|编程语言|可用特性|运行依赖|详细文档
--|:--:|--:|--:|--:
label|all|completion|-|
snippet|all|completion<br>snippets-expanding|-|
path|all|completion|-|
python_jedi|python|completion<br>diagnosis<br> goto-definition<br> find-symbols<br> goto-declaration<br> find-reference<br> snippets-expanding|[jedi](https://pypi.org/project/jedi/)<br>[pyflakes](https://pypi.org/project/pyflakes/)|
html_lsp|html, xhtml|completion<br> diagnosis<br> snippet-expanding<br>find-symbols|nodejs<br>[html-LSP](https://www.npmjs.com/package/vscode-html-languageservice) <br> [HTMLHint](https://www.npmjs.com/package/htmlhint)|
vim_lsp|vimL|completion<br> diagnosis<br> snippet-expanding<br>find-symbols|nodejs<br>[vim-LSP](https://www.npmjs.com/package/vim-language-server)|
go_langserver|golang|completion<br>snippets-expanding|[go-langserver](https://github.com/sourcegraph/go-langserver)|
go_gopls|golang|completion<br>diagnosis<br>snippets-expanding<br>goto-definition<br>goto-reference|[gopls](https://github.com/golang/tools/blob/master/gopls/README.md)|

## 配合 [Ultisnips](https://github.com/SirVer/ultisnips) 使用
`Ultisnips` 是一个单独开发和维护的插件，所以你必须要单独地安装它.  
我们强烈建议你安装 Ultisnips 以获得最好的ECY体验
---
首先你要 查阅 `Ultisnips` 的文档, 其默认的 `g:UltiSnipsExpandTrigger` 值是 '\<Tab\>', 但是这个默认值与ECY的 `g:ECY_select_items`冲突了.  

所以 你必须二选一. 但是 ECY 已经帮你选择好了, 当你安装好ECY后, 会把 `g:UltiSnipsExpandTrigger` 自动地改变为 '\<F1\>'. 

还有更优雅的展开方式，当 ECY 正在提示的时候，你可以按下 `g:ECY_expand_snippets_key` （默认值为 '[\<CR\>](https://stackoverflow.com/questions/22142755/what-is-the-meaning-of-a-cr-at-the-end-of-some-vim-mappings)'）来展开 代码片段 .  

一些很有用的 tips of `Ultisnips`.   
> g:UltiSnipsJumpForwardTrigger   --   默认值: \<c-j\>  
> g:UltiSnipsJumpBackwardTrigger  --  默认值: \<c-k\>   

## 配合 [LeaderF](https://github.com/Yggdroot/LeaderF) 使用
`LeaderF` 是一个单独开发和维护的插件，所以你必须要单独地安装它.  
我们强烈建议你安装 Ultisnips 以获得最好的ECY体验
---
`LeaderF` 能为ECY做什么? 帮助ECY提供UI等功能给用户，让用户选择. 所以如果你没有 
`LeaderF` 的话，你可以在ECY中无法使用一些功能，例如： `Goto-definition` .

一些很有用的 tips of `LeaderF`.   

[what is \<leader\> in vim?](https://stackoverflow.com/questions/1764263/what-is-the-leader-in-a-vimrc-file)
> :LeaderfBuffer or \<leader\>b   

> :LeaderfFile or \<leader\>f  

特别是 可以使用 leaderf 的 `ctags` 功能

# 你问我答

### Q: 为什么ECY没有显示 [Snippets](https://www.techopedia.com/definition/5472/snippet-programming) 当我使用snippet引擎的时候?  
A: ECY 依赖 `Ultisnips`，而 `Ultisnips` 也仅是一个引擎.
所以，你必须提供 Snippets 给 `Ultisnips`，你可以参考这些源：   
 [honza/vim-snippets](https://github.com/honza/vim-snippets) or [CoreyMSchafer/code_snippets](https://github.com/CoreyMSchafer/code_snippets). 

### Q: 为什么一定要 [LeaderF](https://github.com/Yggdroot/LeaderF)?    
A: 有许多类似 `LeaderF` 的相同插件，例如： `fzf-vim` `ctrlP`. 我为什么只选择原因有三个： 1. 他们都依赖python. 2. 对我来说, 我只熟悉这些插件. 3. 支持各种相同的插件让ECY变得臃肿不堪.  

> 模糊搜索优先.

一切操作都只需按最少的键盘 是ECY的原则之一.  
**重要**: ECY不会再支持那些功能类似 `LeaderF` and `ultisnips` 的插件，除非地球爆炸了.  
  
### Q: 我仅需python的引擎，为什么ECY还是要把所有引擎对应的代码都放在我的电脑呢？
A：为了更好的开箱即用。例如说，YCM就像你所说的，每次要启用新的引擎都要重新编译一遍，
虽然YCM在编译C++，但同时也在下载对应引擎python的代码。相对ECY是python3脚本，
全部工程文件加起来都不足 5MB。现在一张图片的大小随随便便都可以超过ECY。

### Q: 为什么不用Ale作为代码错误提示的工具呢？
A： Ale是依赖job的插件，使用时需要把buffer的内容通过job发送给linter，而且每次
用户操作的时候，ECY都会把buffer的内容发送到Server端，如果使用Ale的话 就要发送两次相同的buffer，
去做同一件事，这是极其低效率的。
