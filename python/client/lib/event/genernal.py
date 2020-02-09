# Author: Jimmy Huang (1902161621@qq.com)
# License: WTFPL

import lib.scope as scope_


class GenernalEvent(scope_.Event):
    def __init__(self, source_name):
        scope_.Event.__init__(self, source_name)
