# Author: Jimmy Huang (1902161621@qq.com)
# License: WTFPL

import utils.fuzzy_match as fm


class Operate(object):
    def __init__(self):
        self.symbols_cache_list = []
        self.fuzzy_match = fm.FuzzyMatch()

    def HandleIntegration(self, obj_, version):
        event_ = version['Integration_event']
        return_ = None
        # returning  None will send nothing to client
        if event_ == 'go_to_definition':
            return_ = obj_.GotoDefinition(version)

        elif event_ == 'go_to_declaration_or_definition':
            return_ = obj_.GoToDeclarationOrDefinition(version)

        elif event_ == 'get_symbols':
            return_ = obj_.GetSymbol(version)

        if return_ is None:
            return_ = {'Results': 'ok',
                       'ErroCode': 3,
                       'Event': 'erro_code',
                       'Description': 'have no "' + event_ + '" event'}
        else:
            return_['Event'] = 'integration'
            return_['Integration_event'] = event_
        return return_
