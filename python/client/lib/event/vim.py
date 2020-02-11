# Author: Jimmy Huang (1902161621@qq.com)
# License: WTFPL

import lib.scope as scope_
import lib.vim_or_neovim_support as vim_lib


class VimEvent(scope_.Event):
    def __init__(self, source_name):
        self._starting_server_cmd = None
        self._vimruntime = None
        self._runtimepath = None
        scope_.Event.__init__(self, source_name)

    def _get_vimruntime(self):
        if self._vimruntime is None:
            self._vimruntime = vim_lib.GetVariableValue("$VIMRUNTIME")
        return self._vimruntime

    def _get_runtimepath(self):
        if self._runtimepath is None:
            self._runtimepath = vim_lib.GetVariableValue("&runtimepath")
        return self._runtimepath

    def _get_starting_cmd(self):
        ''' After open a new filetype in Vim, ECY will ask the server what sources
        are available in that filetype, so 
        '''
        if self._starting_server_cmd is None:
            self._starting_server_cmd = vim_lib.CallEval(
                "get(g:,'ECY_vim_lsp_starting_cmd','vim-language-server --stdio')")
        return self._starting_server_cmd

    def _pack(self, msg, event_name):
        msg = self._basic(msg)
        msg['Event'] = event_name
        msg['Additional'] = self._get_snippets()
        msg['Vimruntime'] = self._get_vimruntime()
        msg['StartingCMD'] = self._get_starting_cmd()
        msg['Runtimepath'] = self._get_runtimepath()
        return msg
