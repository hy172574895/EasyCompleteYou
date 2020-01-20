# standard lib
import re
from  pygments import highlight
from  pygments import lex
from  pygments import lexers
from  pygments import token

# local lib
import utils.interface as scope_
# from util import vim_or_neovim_support as vim_lib

class Operate(scope_.Source_interface):
    def __init__(self):
        self._name = 'pygment'

    def GetInfo(self):
        return {'Name': self._name, 'WhiteList': ['all'],
                'Regex': r'[\w]', 'TriggerKey': []}

    def DoCompletion(self, version):
        return_ = {'ID': version['VersionID'], 'Server_name': self._name}
        line_text = version['AllTextList']
        path = version['FilePath']
        try:
            my_lexer = lexers.get_lexer_for_filename(path, stripall=True)
            items_list = lex(line_text, my_lexer)
        except Exception as e:
            raise
            items_list = []
        results_list = []
        for tup in items_list:
            if len(tup[1]) == 1:
                continue
            # the results_format must at least contain the following keys.
            results_format = {'abbr': '', 'word': '', 'kind': '',
                    'menu': '', 'info': '','user_data':''}
            results_format['word'] = tup[1]
            if len(tup[1]) > 30:
                results_format['abbr'] = str(tup[1])[:30]
            else:
                results_format['abbr'] = tup[1]
            results_format['kind'] = str(tup[0])[6:]
            results_list.append(results_format)
        return_['Lists'] = results_list
        return return_