# Author: Jimmy Huang (1902161621@qq.com)
# License: WTFPL


class Operate(object):
    def OnBufferEnter(self, obj_, version):
        results_ = obj_.OnBufferEnter(version)
        if results_ is not None:
            results_['Event'] = 'OnBufferEnter'
            results_['Version_ID'] = version['VersionID']
        return results_
