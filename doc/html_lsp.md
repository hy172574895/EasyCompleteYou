# Document for LSP of HTML

## Installation
### Requires:
| Name            | Kind          | WebSite                                                         |
| -------------   | ------------- | -------                                                         |
| Language Server | Necessary     | [->](https://www.npmjs.com/package/vscode-html-languageservice) |
| Nodejs          | Necessary     | [->](https://nodejs.org/en/)                                    |
| npm             | Necessary     | [->](https://www.npmjs.com/)                                    |
| HTMLHint        | Optional      | [->](https://www.npmjs.com/package/htmlhint)                    |

### Quickly install
Execute the following command in normal mode in vim.

`:ECYInstall html_lsp`

ECY will check that all, and will ask user to install when one of them 
are missing.

### Full Installation guide
  1.make sure you have `nodejs` in your OS; [help](https://www.google.com/search?q=how%20to%20install%20nodejs)  
  2.make sure you have `npm` in your OS; [help](https://www.google.com/search?q=how%20to%20install%20nodejs)  
  3.make sure you have `html_lsp` in your OS, install `html_lsp` with npm; [help](https://www.npmjs.com/package/vscode-html-languageservice)  
  4.optionally install `HTMLHint` to your OS, for diagnosis; [help](https://www.npmjs.com/package/htmlhint)  
  5.Execute `:ECYInstall html_lsp`  

## Customized

### Options Variable

#### 1. g:ECY_html_lsp_starting_cmd  
default value: "html-languageserver --stdio"  
Command to run bin of Html Language server.

for example, put the code into your vimrc:  
`let g:ECY_html_lsp_starting_cmd = 'nodejs /home/xxx/yyyy/zzz/bin/html --stdio'`

#### 2. g:ECY_html_lsp_HtmlHint_cmd
default value: "htmlhint"  
Command to bin of htmlhint.

for example, put the code into your vimrc:  
`let g:ECY_html_lsp_HtmlHint_cmd = 'nodejs /home/xxx/node_modules/.bin/htmlhint`

## Trouble shooting.
### Showing a msg that `ECY can not start lsp server.`
You have no `html_lsp` in your OS or you set a wrong path to html server bin.

### Showing a msg that `ECY can not start htmlhint.`
You have no `htmlhint` in your OS or you set a wrong path to htmlhint bin.
