# Author: Jimmy Huang (1902161621@qq.com)
# License: WTFPL

# standard lib
import re
# local lib
import utils.interface as scope_
# from utils import vim_or_neovim_support as vim_lib


class Operate(scope_.Source_interface):
    def __init__(self):
        self._name = 'label'

    def GetInfo(self):
        return {'Name': self._name, 'WhiteList': ['all'],
                'Regex': r'[\w]', 'TriggerKey': []}

    def DoCompletion(self, version):
        return_ = {'ID': version['VersionID'], 'Server_name': self._name}
        line_text = version['AllTextList']
        # line_text = '\n'.join(line_text)
        # get the items and filter the repeat one.
        items_list = list(set(re.findall(r'\w+', line_text)))
        results_list = []
        for item in items_list:
            # the results_format must at least contain the following keys.
            results_format = {'abbr': '', 'word': '', 'kind': '',
                    'menu': '', 'info': '','user_data':''}
            results_format['abbr'] = item
            results_format['word'] = item
            results_format['kind'] = '[ID]'
            results_list.append(results_format)
        return_['Lists'] = results_list
        return return_
