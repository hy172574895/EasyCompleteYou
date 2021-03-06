# Author: Jimmy Huang (1902161621@qq.com)
# License: WTFPL

import ECY.utils.scope as scope_
import ECY.utils.vim_or_neovim_support as vim_lib


class Operate(scope_.Event):
    def __init__(self, source_name):
        self._starting_server_cmd = None
        self._HTMLHint_cmd = None
        scope_.Event.__init__(self, source_name)

    def _get_starting_cmd(self):
        ''' After open a new filetype in Vim, ECY will ask the server what sources
        are available in that filetype, so 
        '''
        if self._starting_server_cmd is None:
            self._starting_server_cmd = vim_lib.CallEval(
                "get(g:,'ECY_html_lsp_starting_cmd','html-languageserver --stdio')")
        return self._starting_server_cmd

    def _get_HTMLHint_cmd(self):
        if self._HTMLHint_cmd is None:
            self._HTMLHint_cmd = vim_lib.CallEval(
                "get(g:,'ECY_html_lsp_HtmlHint_cmd','htmlhint')")
        return self._HTMLHint_cmd

    def DoCompletion(self):
        msg = {}
        msg['Additional'] = self._get_snippets()
        return self._pack(msg, 'DoCompletion')

    def _pack(self, msg, event_name):
        msg['HTMLHintCMD'] = self._get_HTMLHint_cmd()
        msg['StartingCMD'] = self._get_starting_cmd()
        return self._generate(msg, event_name)
