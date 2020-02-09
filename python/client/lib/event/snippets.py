# Author: Jimmy Huang (1902161621@qq.com)
# License: WTFPL

import lib.scope as scope_
import lib.vim_or_neovim_support as vim_lib


class SnippetsEvent(scope_.Event):
    def __init__(self, source_name):
        scope_.Event.__init__(self, source_name)

    def _pack(self, msg, event_name):
        msg = self._basic(msg)
        msg['Event'] = event_name
        msg['Additional'] = self._get_snippets()
        return msg
