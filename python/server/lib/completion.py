# Author: Jimmy Huang (1902161621@qq.com)
# License: WTFPL

import re
import logging
global g_logger
g_logger = logging.getLogger('ECY_server')
# local lib
import ECY.utils.fuzzy_match as fm


class Operate(object):
    def __init__(self):
        self.fuzzy_match = fm.FuzzyMatch()
        self.start_position = {}
        self.completion_items = {'EngineName': 'nothing', 'Lists': []}
        self.version_id = -1
        self.buffer_cache_list = []
        self.buffer_cache_item = []

    def UpdateBufferCache(self, version, reg=r'[\w\-]+'):
        items_list = version['AllTextList']
        items_list = list(set(re.findall(reg, items_list)))
        items_list.extend(self.buffer_cache_list)
        self.buffer_cache_list = list(set(items_list))
        self.buffer_cache_item = []
        for item in self.buffer_cache_list:
            # the results_format must at least contain the following keys.
            results_format = {'abbr': '', 'word': '', 'kind': '',
                    'menu': '', 'info': '','user_data':''}
            results_format['abbr'] = item
            results_format['word'] = item
            results_format['kind'] = '[Buffer]'
            self.buffer_cache_item.append(results_format)

    def DoCompletion(self, engine_obj, version):
        if self.version_id > version['VersionID']:
            g_logger.debug('filter a completion request.')
            return None
        self.version_id = version['VersionID']
        # we get regex from instance
        source_info = engine_obj.GetInfo()

        # get full items
        original_colum = version['StartPosition']['Colum']
        current_line = version['StartPosition']['Line']
        current_line_text = version['CurrentLineText']
        pre_words = current_line_text[:original_colum]
        current_colum, filter_words, last_key = \
            self.FindStart(pre_words, source_info['Regex'])
        current_start_postion = \
                {'Line': current_line, 'Colum': current_colum, 'OriginalColum': original_colum}
        version['Filter_words'] = filter_words
        version['Filter_start_position'] = current_start_postion
        pre_words = current_line_text[:current_colum]

        engine_name = source_info['Name']
        if engine_name not in self.start_position:
            # init
            self.start_position[engine_name] = {'Line': 0, 'Colum': 0, 'OriginalColum': 0}

        cache_position = self.start_position[engine_name]
        g_logger.debug(cache_position)
        g_logger.debug(current_start_postion)
        if current_start_postion['Line'] != cache_position['Line']\
                or current_start_postion['Colum'] != cache_position['Colum']\
                or cache_position['OriginalColum'] >= original_colum\
                or self.completion_items['EngineName'] != engine_name\
                or ('NotCache' in source_info and source_info['NotCache']):
            # reflesh cache
            return_ = engine_obj.DoCompletion(version)
            g_logger.debug('reflesh cache')
            if return_ is None:
                return None
            return_['EngineName'] = engine_name
            if 'ErroCode' in return_:
                return return_
            self.completion_items = return_
            self.start_position[engine_name] = current_start_postion

        # filter the items with keywords
        all_list = self.completion_items['Lists']
        current_start_postion = self.start_position[engine_name]
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
                g_logger.debug('using _return_buffer_cache')
                return_ = self.fuzzy_match.FilterItems(filter_words,
                                                       self.buffer_cache_item,
                                                       isreturn_match_point=isIndent,
                                                       isindent=isIndent)

        addtional_data = None
        if 'AddtionalData' in self.completion_items.keys():
            addtional_data = self.completion_items['AddtionalData']
        return {'Event': 'do_completion', 'Version_ID': version['VersionID'],
                'Lists': return_, 'StartPosition': current_start_postion,
                'EngineName': engine_name,
                'PreviousWords': pre_words,
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
