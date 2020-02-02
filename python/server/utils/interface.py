# Author: Jimmy Huang (1902161621@qq.com)
# License: WTFPL

import re


class Source_interface(object):
    # rewrite the method
    # ErroCode==1 is means This completor doesn't support that future.
    def _return(self, _id):
        # 'ErroCode' 1 means source did not impletment that method
        return {'ID': _id, 'Results': 'ok', 'ErroCode': 1,
                'Event': 'erro_code', 'Description': 'not implemented'}

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

    def Diagnosis(self, version):
        return self._return(version['VersionID'])

    def GetSymbol(self, version):
        return self._return(version['VersionID'])

    def Goto(self, version):
        return self._return(version['VersionID'])

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
