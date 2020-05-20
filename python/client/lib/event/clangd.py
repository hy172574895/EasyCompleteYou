# Author: Jimmy Huang (1902161621@qq.com)
# License: WTFPL

import ECY.utils.scope as scope_
import ECY.utils.vim_or_neovim_support as vim_lib


class Operate(scope_.Event):
    def __init__(self, source_name):
        self._starting_server_cmd = None
        self._limit_results = None
        scope_.Event.__init__(self, source_name)

    def _get_starting_cmd(self):
        if self._starting_server_cmd is None:
            self._starting_server_cmd = vim_lib.CallEval(
                "get(g:,'ECY_clangd_starting_cmd','clangd')")
        return self._starting_server_cmd

    def _get_limit_results(self):
        if self._limit_results is None:
            self._limit_results = vim_lib.CallEval(
                "get(g:,'ECY_clangd_results_limitation', 500)")
        return self._limit_results

    def _pack(self, msg, event_name):
        msg['StartingCMD'] = self._get_starting_cmd()
        msg['ResultsLimitation'] = self._get_limit_results()
        return self._generate(msg, event_name)
