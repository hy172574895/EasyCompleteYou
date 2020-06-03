# Author: Jimmy Huang (1902161621@qq.com)
# License: WTFPL

# local lib
import ECY.utils.interface as scope_

# we do nothing
class Operate(scope_.Source_interface):
    def __init__(self):
        self._name = 'youcompleteme'

    def GetInfo(self):
        # WhiteList must be 'all'
        return {'Name': self._name, 'WhiteList': ['all'],
                'Regex': r'[a-z0-9\_]', 'TriggerKey': []}
