# Author: Jimmy Huang (1902161621@qq.com)
# License: WTFPL

# same as ycm.py
# we do nothing

# local lib
import ECY.utils.interface as scope_
class Operate(scope_.Source_interface):
    def __init__(self):
        self._name = 'disabled'

    def GetInfo(self):
        # WhiteList must be 'all'
        return {'Name': self._name, 'WhiteList': ['all'],
                'Regex': r'[A-Za-z0-9\_]', 'TriggerKey': []}
