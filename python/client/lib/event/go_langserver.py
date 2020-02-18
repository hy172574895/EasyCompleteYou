# Author: Jimmy Huang (1902161621@qq.com)
# License: WTFPL

import lib.scope as scope_
import lib.vim_or_neovim_support as vim_lib


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
                "get(g:,'ECY_golangserver_starting_cmd','go-langserver')")
        return self._starting_server_cmd

    def _get_HTMLHint_cmd(self):
        if self._HTMLHint_cmd is None:
            self._HTMLHint_cmd = vim_lib.CallEval(
                "get(g:,'ECY_html_lsp_HtmlHint_cmd','htmlhint')")
        return self._HTMLHint_cmd

    def OnBufferEnter(self):
        self._workspace = self.GetCurrentWorkSpace()
        msg = {}
        return self._pack(msg, 'OnBufferEnter')

    def DoCompletion(self):
        msg = {}
        msg['TriggerLength'] = self._trigger_len
        msg['ReturnMatchPoint'] = self._is_return_match_point
        msg['ReturnDiagnosis'] = self._is_return_diagnosis
        return self._pack(msg, 'DoCompletion')

    def _pack(self, msg, event_name):
        msg = self._basic(msg)
        msg['Event'] = event_name
        msg['Additional'] = self._get_snippets()
        msg['HTMLHintCMD'] = self._get_HTMLHint_cmd()
        msg['StartingCMD'] = self._get_starting_cmd()
        return msg
