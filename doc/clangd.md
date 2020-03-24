# Document for `clangd`
## Installation
Download `clangd` and put it into your [OS's global variable](https://en.wikipedia.org/wiki/Global_variable).
Make sure you can index clangd in your PC's shell.

### Requires:
| Name          | Kind          | WebSite                                     |
| ------------- | ------------- | -------                                     |
| clangd7.0+    | Necessary     | [->](https://github.com/clangd/clangd/releases)   |

## Options
#### 1. g:ECY_clangd_starting_cmd  
default value: "clangd"  
Command to run bin of clangd Language server.

for example, put the code into your vimrc:  
`let g:ECY_clangd_starting_cmd = '/home/xxx/yyyy/zzz/bin/clangd.exe'`

## Usages
