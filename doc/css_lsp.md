# Document for LSP of `CSS`

## Installation
### Requires:
| Name            | Kind          | WebSite                                                         |
| -------------   | ------------- | -------                                                         |
| Language Server | Necessary     | [->](https://www.npmjs.com/package/vscode-css-languageserver-bin) |
| Nodejs          | Necessary     | [->](https://nodejs.org/en/)                                    |
| npm             | Necessary     | [->](https://www.npmjs.com/)                                    |

### Quickly install
Execute the following command in normal mode in vim.

> `:ECYInstall css_lsp`

ECY will check that all, and will ask user to install when one of them 
are missing.

### Full Installation guide
  1.make sure you have `nodejs` in your OS; [help](https://www.google.com/search?q=how%20to%20install%20nodejs)  
  2.make sure you have `npm` in your OS; [help](https://www.google.com/search?q=how%20to%20install%20nodejs)  
  3.make sure you have `css_lsp` in your OS, install `html_lsp` with npm; [help](https://www.npmjs.com/package/vscode-css-languageserver-bin)  
  5.Execute `:ECYInstall css_lsp`  

## Customized

### Options Variable

#### 1. g:ECY_css_lsp_starting_cmd  
default value: "css-language-server --stdio"  
Command to run bin of Html Language server.

for example, put the code into your vimrc:  
`let g:ECY_css_lsp_starting_cmd = 'nodejs /home/xxx/yyyy/zzz/bin/html --stdio'`

## Trouble shooting.
### Showing a msg that `ECY can not start lsp server.`
You have no `html_lsp` in your OS or you set a wrong path to html server bin.

### Showing a msg that `ECY can not start htmlhint.`
You have no `htmlhint` in your OS or you set a wrong path to htmlhint bin.
