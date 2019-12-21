# local lib
import utils.interface as scope_


class Operate(scope_.Source_interface):
    def __init__(self):
        self._name = 'snippets'

    def GetInfo(self):
        return {'Name': self._name, 'WhiteList': ['all'],
                'Regex': r'[\w]', 'TriggerKey': []}

    def DoCompletion(self, version):
        return_ = {'ID': version['VersionID'], 'Server_name': self._name}
        # ECY will show nothing when the list is None
        results_list = []
        
        if version['Additional']['HasSnippetSupport']:
            snippets = version['Additional']['UltisnipsSnippets'].items()
            for trigger, snippet in snippets:
                results_format = {'abbr': '', 'word': '', 'kind': '',
                        'menu': '', 'info': '','user_data':''}
                results_format['word'] = trigger
                results_format['abbr'] = trigger
                results_format['kind'] = '[Snippet]'
                results_format['menu'] = snippet['description']
                results_list.append(results_format)
        return_['Lists'] = results_list
        return return_
