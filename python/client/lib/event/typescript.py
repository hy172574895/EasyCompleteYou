# Author: Jimmy Huang (1902161621@qq.com)
# License: WTFPL

import lib.scope as scope_
import lib.vim_or_neovim_support as vim_lib


class Operate(scope_.Event):
    def __init__(self, source_name):
        self._starting_server_cmd = None
        scope_.Event.__init__(self, source_name)

    def _get_starting_cmd(self):
        ''' After open a new filetype in Vim, ECY will ask the server what sources
        are available in that filetype, so 
        '''
        if self._starting_server_cmd is None:
            self._starting_server_cmd = vim_lib.CallEval(
                "get(g:,'ECY_typescripte_starting_cmd', 'tsserver')")
        return self._starting_server_cmd

    def _pack(self, msg, event_name):
        msg['StartingCMD'] = self._get_starting_cmd()
        return self._generate(msg, event_name)
