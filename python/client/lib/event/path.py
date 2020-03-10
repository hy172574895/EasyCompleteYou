# Author: Jimmy Huang (1902161621@qq.com)
# License: WTFPL

import logging
global g_logger
g_logger = logging.getLogger('ECY_client')

import lib.scope as scope_
import lib.vim_or_neovim_support as vim_lib


class Operate(scope_.Event):
    def __init__(self, source_name):
        self._ignore_dict= None
        scope_.Event.__init__(self, source_name)

    def _get_ignore(self):
        if self._ignore_dict is None:
            self._ignore_dict = vim_lib.CallEval(
                "get(g:,'ECY_file_path_ignore',{'dir': ['.svn','.git','.hg', '__pycache__'],'file': ['*.sw?','~$*','*.bak','*.exe','*.o','*.so','*.py[co]','~$','swp$']})")
        return self._ignore_dict

    def _pack(self, msg, event_name):
        msg['Ignore'] = self._get_ignore()
        if self._workspace is None:
            self._workspace = self.GetCurrentWorkSpace()
        return self._generate(msg, event_name)
