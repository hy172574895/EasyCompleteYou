# Author: Jimmy Huang (1902161621@qq.com)
# License: WTFPL
import re


class Operate(object):

    def GetDocument(self, engine_obj,  version):
        current_colum = version['StartPosition']['Colum']
        current_line_text = version['CurrentLineText']
        pre_words = current_line_text[:current_colum]
        after_words = current_line_text[current_colum:]
        word = ''

        i = len(pre_words)
        while i > 0 :
            i -= 1
            temp = pre_words[i]
            if re.match(r'[\w]', temp) is None:
                break
            word = temp + word

        for item in after_words:
            if re.match(r'[\w]', item) is None:
                break
            word += item
        version['CursorWord'] = word

        results = engine_obj.OnDocumentHelp(version)
        source_info = engine_obj.GetInfo()
        engine_name = source_info['Name']
        if results is not None and 'ErroCode' not in results:
            results['Event'] = 'document_help'
            results['EngineName'] = engine_name
        return results
