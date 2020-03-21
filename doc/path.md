# Document for `path`
## Installation
This engine is buildin, and will install automatically.  

### Requires:
None

## Usages
1. You need to understand what [workspace](https://www.computerhope.com/jargon/w/workspace.htm) is.
ECY will automatically detect the `workspace` in your project by searching some files which is defined in `g:rooter_patterns`. 
Basically, it's totally same as [Rooter](https://github.com/airblade/vim-rooter), you should check its doc.

2. You can show current buffer's `workspace` by `:echo ECY#rooter#GetCurrentBufferWorkSpace()` 

3. You can change current buffer's `workspace` by `Root` command, such as `:Root /home/jjjj/iii/mmm/yyy`

4. You will trigger this engine while typing `/` in Insert mode.
