# Author: Jimmy Huang (1902161621@qq.com)
# License: WTFPL

import ECY.utils.scope as scope_
import ECY.utils.vim_or_neovim_support as vim_lib


class Operate(scope_.Event):
    def __init__(self, source_name):
        self._starting_server_cmd = None
        self._HTMLHint_cmd = None
        self._is_output_log = None
        scope_.Event.__init__(self, source_name)

    def _get_starting_cmd(self):
        if self._starting_server_cmd is None:
            self._starting_server_cmd = vim_lib.CallEval(
                "get(g:,'ECY_gopls_starting_cmd','gopls')")
        return self._starting_server_cmd

    def _get_is_save_log_file(self):
        ''' Output log file to corresponding workspace.
        '''
        if self._is_output_log is None:
            self._is_output_log = vim_lib.CallEval(
                    "get(g:,'ECY_gopls_output_log_file_to_workspace',v:false)")
        return self._is_output_log

    def _pack(self, msg, event_name):
        msg['StartingCMD'] = self._get_starting_cmd()
        msg['IsOutputLogFile'] = self._get_is_save_log_file()
        return self._generate(msg, event_name)
