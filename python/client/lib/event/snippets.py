# Author: Jimmy Huang (1902161621@qq.com)
# License: WTFPL

import ECY.utils.scope as scope_

class Operate(scope_.Event):
    def __init__(self, source_name):
        scope_.Event.__init__(self, source_name)

    def OnBufferEnter(self):
        self._get_snippets(is_reflesh=True)
        return self._pack({}, 'OnBufferEnter')

    def DoCompletion(self):
        msg = {}
        msg['Additional'] = self._get_snippets()
        temp = self._pack(msg, 'DoCompletion')
        temp['AllTextList'] = []
        return temp
