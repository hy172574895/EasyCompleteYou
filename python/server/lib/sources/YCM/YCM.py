# local lib
import utils.interface as scope_

# we do nothing
class Operate(scope_.Source_interface):
    def __init__(self):
        self._name = 'youcompleteme'

    def GetInfo(self):
        # WhiteList must be 'all'
        return {'Name': self._name, 'WhiteList': ['all'],
                'Regex': r'[\w]', 'TriggerKey': []}
