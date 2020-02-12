# Author: Jimmy Huang (1902161621@qq.com)
# License: WTFPL

import re
import logging
global g_logger
g_logger = logging.getLogger('ECY_server')
# local lib
import utils.fuzzy_match as fm


class Operate(object):
    def __init__(self):
        self.fuzzy_match = fm.FuzzyMatch()
        self.start_position = {}
        self.completion_items = {'Server_name': 'nothing', 'Lists': []}

    def DoCompletion(self, source_obj, version, buffer_cache):
        # we get regex from instance
        source_info = source_obj.GetInfo()

        # get full items
        current_colum = version['StartPosition']['Colum']
        current_line_text = version['CurrentLineText']
        pre_words = current_line_text[:current_colum]
        current_colum, filter_words, last_key = \
            self.FindStart(pre_words, source_info['Regex'])
        current_start_postion = \
            {'Line': version['StartPosition']['Line'], 'Colum': current_colum}
        version['Filter_words'] = filter_words
        version['Filter_start_position'] = current_start_postion

        if source_info['Name'] not in self.start_position:
            # init
            self.start_position[source_info['Name']] = {'Line': 0, 'Colum': 0}

        if current_start_postion != self.start_position[source_info['Name']]\
                or self.completion_items['Server_name'] != source_info['Name']:
            # reflesh cache
            return_ = source_obj.DoCompletion(version)
            if return_ is None or 'ErroCode' in return_:
                return return_
            self.completion_items = return_
            self.start_position[source_info['Name']] = current_start_postion

        # filter the items with keywords
        all_list = self.completion_items['Lists']
        current_start_postion = self.start_position[source_info['Name']]
        trigger_len = int(version['TriggerLength'])
        return_ = []
        if len(filter_words) > trigger_len or \
                last_key in source_info['TriggerKey']:
            if 'ReturnMatchPoint' in version:
                isIndent = version['ReturnMatchPoint']
            else:
                isIndent = False
            return_ = self.fuzzy_match.FilterItems(filter_words,
                                                   all_list,
                                                   isreturn_match_point=isIndent,
                                                   isindent=isIndent)
            if return_ == []:
                all_text = ''
                for key, content in buffer_cache.items():
                    all_text += content
                all_text = self._return_label(all_text)
                g_logger.debug('using _return_label')
                return_ = self.fuzzy_match.FilterItems(filter_words,
                                                       all_text,
                                                       isreturn_match_point=isIndent,
                                                       isindent=isIndent)

        addtional_data = None
        if 'AddtionalData' in self.completion_items.keys():
            addtional_data = self.completion_items['AddtionalData']
        return {'Event': 'do_completion', 'Version_ID': version['VersionID'],
                'Lists': return_, 'StartPosition': current_start_postion,
                'Server_name': source_info['Name'],
                'AddtionalData': addtional_data,
                'Filter_words': filter_words}

    def FindStart(self, text, reg):
        # {{{
        """ 0 of lsp is means complete on the very first character
        e.g '|abc' where the | means the start-position equal 0.
        """
        start_position = len(text)
        text_len = start_position-1
        last_key = ''
        match_words = ''
        if text_len < 300:
            while text_len >= 0:
                temp = text[text_len]
                if (re.match(reg, temp) is not None):
                    match_words = temp+match_words
                    start_position -= 1
                    if text_len == 0:
                        break
                    text_len = text_len-1
                    continue
                break
            if start_position != 0:
                last_key = text[start_position-1]
            elif text_len >= 0:
                last_key = text[0]
        return start_position, match_words, last_key
# }}}

    def _return_label(self, all_text_list, reg=r'[\w\-]+'):
        items_list = list(set(re.findall(reg, all_text_list)))
        results_list = []
        for item in items_list:
            # the results_format must at least contain the following keys.
            results_format = {'abbr': '', 'word': '', 'kind': '',
                    'menu': '', 'info': '','user_data':''}
            results_format['abbr'] = item
            results_format['word'] = item
            results_format['kind'] = '[Buffer]'
            results_list.append(results_format)
        return results_list

