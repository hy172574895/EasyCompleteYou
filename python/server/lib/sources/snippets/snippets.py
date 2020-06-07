# Author: Jimmy Huang (1902161621@qq.com)
# License: WTFPL
import logging
global g_logger
g_logger = logging.getLogger('ECY_server')

# local lib
import ECY.utils.interface as scope_


class Operate(scope_.Source_interface):
    def __init__(self):
        self._name = 'snippets'

    def GetInfo(self):
        return {'Name': self._name, 'WhiteList': ['all'],
                'Regex': r'[A-Za-z0-9\_]', 'TriggerKey': []}

    def DoCompletion(self, version):
        return_ = {'ID': version['VersionID']}
        # ECY will show nothing when the list is None
        results_list = []
        if version['Additional']['HasSnippetSupport']:
            snippets = version['Additional']['UltisnipsSnippets'].items()
            for trigger, snippet in snippets:
                results_format = {'abbr': '', 'word': '', 'kind': '',
                        'menu': '', 'info': '', 'user_data':''}
                results_format['word'] = trigger
                results_format['abbr'] = trigger
                results_format['kind'] = '[Snippet]'
                description = snippet['description']
                if not snippet['description'] == '':
                    results_format['menu'] = description
                results_format['info'] = snippet['preview']
                results_list.append(results_format)
        return_['Lists'] = results_list
        return return_
