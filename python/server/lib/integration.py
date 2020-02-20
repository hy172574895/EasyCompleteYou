# Author: Jimmy Huang (1902161621@qq.com)
# License: WTFPL

import utils.fuzzy_match as fm


class Operate(object):
    def __init__(self):
        self.symbols_cache_list = []
        self.fuzzy_match = fm.FuzzyMatch()

    def HandleIntegration(self, engine_obj, version):
        event_ = version['Integration_event']
        return_ = None
        source_info = engine_obj.GetInfo()
        engine_name = source_info['Name']
        # returning  None will send nothing to client
        if event_ == 'go_to_definition':
            return_ = engine_obj.GotoDefinition(version)

        elif event_ == 'go_to_declaration_or_definition':
            return_ = engine_obj.GoToDeclarationOrDefinition(version)

        elif event_ == 'get_symbols':
            return_ = engine_obj.GetSymbol(version)

        if return_ is None:
            return_ = {'Results': 'ok',
                       'ErroCode': 3,
                       'Event': 'erro_code',
                       'Description': 'have no "' + event_ + '" event'}
        elif 'ErroCode' not in return_:
            return_['Event'] = 'integration'
            return_['EngineName'] = engine_name
            return_['Integration_event'] = event_
        return return_
