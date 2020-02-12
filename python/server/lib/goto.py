# Author: Jimmy Huang (1902161621@qq.com)
# License: WTFPL


class Operate(object):
    """
    """

    def __init__(self):
        pass

    def Goto(self, obj_,  version):
        results = obj_.Goto(version)
        if results is not None:
            results['Event'] = 'goto'
        return results
