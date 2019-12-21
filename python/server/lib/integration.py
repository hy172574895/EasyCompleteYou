import utils.fuzzy_match as fm

class Operate(object):
    def __init__(self):
        self.symbols_cache_list = []
        self.fuzzy_match = fm.FuzzyMatch()

    def HandleIntegration(self, obj_, version):
        event_ = version['Integration_event']
        return_ = None
        if event_ == 'go_to_definition':
            return_ = obj_.GotoDefinition(version)
        elif event_ == 'go_to_declaration_or_definition':
            return_ = obj_.GoToDeclarationOrDefinition(version)
        elif event_ == 'get_symbols' or event_ == 'filter_search_items':
            # {{{
            is_filter_items = True
            if event_ == 'get_symbols':
                # reflesh
                return_ = obj_.GetSymbol(version)
                is_filter_items = False
            if 'ErroCode' not in return_:
                filter_list = []
                if is_filter_items:
                    filter_list = self.fuzzy_match.CalculateGoal(
                            version['KeyWords'], self.symbols_cache_list, 
                            isreturn_match_point=True,
                            max_len_2_show=30)
                else:
                    self.symbols_cache_list = return_['Results']
                    filter_list = self.symbols_cache_list

                # format
                name_std_len = 1
                kine_std_len = 1
                max_to_show = 30
                j = 0
                lists = []
                for item in filter_list:
                    if j > max_to_show:
                        break
                    lists.append(item)
                    length = len(item['abbr'])
                    if length > name_std_len:
                        name_std_len = length
                    length = len(item['kind'])
                    if length > kine_std_len:
                        kine_std_len = length
                    j += 1

                # make an interval with space
                name_std_len += 2
                kine_std_len += 2

                for item in lists:
                    name_cur_len = name_std_len - len(item['abbr'])
                    i = 0
                    while i < name_cur_len:
                        item['abbr'] += ' '
                        i += 1
                    name_cur_len = kine_std_len - len(item['kind'])
                    i = 0
                    while i < name_cur_len:
                        item['kind'] += ' '
                        i += 1
                return_['Results'] = lists

            # }}}
        if return_ is None:
            return return_
        return_['Event'] = 'integration'
        return_['Integration_event'] = event_
        return return_
