# Document for `rust_analyzer`
## Installation
Download `rust_analyzer` and put it into your [OS's global variable](https://en.wikipedia.org/wiki/Global_variable).
Make sure you can index rust_analyzer in your PC's shell.  

Execute the following command in normal mode in vim.
> `:ECYInstall rust_analyzer`

### Requires:
| Name          | Kind          | WebSite                                     |
| ------------- | ------------- | -------                                     |
| rust_analyzer | Necessary     | [->](https://github.com/rust-analyzer/rust-analyzer)   |

## Options
#### 1. g:ECY_rust_analyzer_starting_cmd  
default value: "clangd"  
Command to run bin of clangd Language server.

for example, put the code into your vimrc:  
`let g:ECY_rust_analyzer_starting_cmd = '/home/xxx/yyyy/zzz/bin/rust-analyzer.exe'`

## Usages
You should make sure you have `Cargo.toml` in your project. Check [here]( https://doc.rust-lang.org/cargo/reference/manifest.html ) more about Cargo.  
Where is your `Cargo.toml` where your `workspace` is. Check also about [ Root.vim ](https://github.com/airblade/vim-rooter).
