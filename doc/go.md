# Document for `golang`
## Installation
Download `gopls` and put it into your [OS's global variable](https://en.wikipedia.org/wiki/Global_variable).
Make sure you can index clangd in your PC's shell.  

Execute the following command in normal mode in vim.
> `:ECYInstall gopls`

### Requires:
| Name          | Kind          | WebSite                                     |
| ------------- | ------------- | -------                                     |
| gopls    | Necessary     | [->](https://github.com/golang/tools/blob/master/gopls/README.md)   |

## Options
#### 1. g:ECY_clangd_starting_cmd  
default value: "gopls"  
Command to run bin of gopls Language server.

for example, put the code into your vimrc:  
`let g:ECY_gopls_starting_cmd = '/home/xxx/yyyy/zzz/bin/gopls.exe'`

## Usages
You should have some knowledge of how to build `golang` project.  
And you can manage your workspace by [Rooter](https://github.com/airblade/vim-rooter)(included in ECY) such as `:echo ECY#rooter#GetCurrentBufferWorkSpace()` 
