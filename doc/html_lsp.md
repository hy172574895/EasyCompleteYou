Doc for LSP of HTML
===============================================================================
Installation

requires:
  1.LSP of HTML              necessary
  2.nodejs (for LSP server)  necessary
  3.npm (for nodejs)         necessary
  4.HTMLHint (for diagnosis) optional

ECY will check that all, and will ask user to install when one of them 
are missing.

===============================================================================
*For users:*

1. Options Variable

g:ECY_html_lsp_starting_cmd
default: "html-languageserver --stdio"

g:ECY_html_lsp_HtmlHint_cmd
default: "htmlhint"
