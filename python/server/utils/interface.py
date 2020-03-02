# Author: Jimmy Huang (1902161621@qq.com)
# License: WTFPL

import re


class Source_interface(object):
    def __init__(self):
        self._name = 'nothing'

    def _return(self, _id, is_slience=True, content='not implemented'):
        if is_slience:
            # 'ErroCode' 1 means engine did not impletment that method
            # and don't show description to user
            erro_code = 1
        else:
            # show description to user
            erro_code = 2

        return {'ID': _id, 'Results': 'ok', 'ErroCode': erro_code,
                'Event': 'erro_code',
                'EngineName': self._name,
                'Description': content}

    def GetInfo(self):
        return {'Name': 'nothing', 'WhiteList': ['nothing']}

    def DoCompletion(self, version):
        return self._return(version['VersionID'])

    def CleanAllCache(self, version):
        return self._return(version['VersionID'])

    def Exit(self, version):
        return self._return(version['VersionID'])

    def OnBufferEnter(self, version):
        return self._return(version['VersionID'])

    def OnBufferTextChanged(self, version):
        return self._return(version['VersionID'])

    def OnInsertModeLeave(self, version):
        return self._return(version['VersionID'])

    def GetSymbol(self, version):
        return self._return(version['VersionID'],
                            is_slience=False,
                            content='Current Engine Have No GetSymbol Ability.')

    def Goto(self, version):
        return self._return(version['VersionID'],
                            is_slience=False,
                            content='Current Engine Have No Goto Ability.')

    def FindStart(self, text, reg):
        # {{{
        """ 0 of lsp is means complete on the very firsr character
        e.g '|abc' where the | means the start-position equal 0.
        """
        start_position = len(text)
        text_len = start_position-1
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
        return start_position, match_words
        # }}}

    def IsInsideQuotation(self, current_line, column):
        # {{{
        if column == 0 or len(current_line) > 1000:
            return False
        if len(current_line) > 1000:
            return True
        after = current_line[column:]
        pre = current_line[:column]
        pre_i = 0
        pre_j = 0
        after_i = 0
        after_j = 0
        for word in pre:
            if word in ['\"']:
                pre_i += 1
            elif word in ['\'']:
                pre_j += 1

        for word in after:
            if word in ['\"']:
                after_i += 1
            elif word in ['\'']:
                after_j += 1

        if pre_i != 0 and after_i != 0:
            if pre_i % 2 != 0 and after_i % 2 != 0:
                return True
        if pre_j != 0 and after_j != 0:
            if pre_j % 2 != 0 and after_j % 2 != 0:
                return True
        return False
        # }}}
