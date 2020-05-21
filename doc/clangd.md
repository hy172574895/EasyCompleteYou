# Document for `clangd`
## Installation
Download `clangd` and put it into your [OS's global variable](https://en.wikipedia.org/wiki/Global_variable).
Make sure you can index clangd in your PC's shell.  

Execute the following command in normal mode in vim.
> `:ECYInstall clangd`

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

#### 1. g:ECY_clangd_results_limitation  
default value: 500
Show all the results if its value equal to 0.

for example, put the code into your vimrc:  
`let g:ECY_clangd_results_limitation = 0`

## Usages
You should go to check its [website](https://clangd.llvm.org/installation.html) of how it works.  
Generally, you need a project file named `compile_commands.json`, and how to configure that file bases on your knowledge of `C-language` such as how to include a `lib` or dictate where is the `lib dir`.
