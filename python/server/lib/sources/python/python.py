# Author: Jimmy Huang (1902161621@qq.com)
# License: WTFPL

import jedi
import os
import re

import utils.interface as scope_


class Operate(scope_.Source_interface):
    def __init__(self):
        # FIXME:when completing the last line of a method or a class will
        # show only a few of items, mabye, because the cache's system position
        # don't match with jedi
        self._name = 'python_jedi'

    def GetInfo(self):
        return {'Name': self._name, 'WhiteList': ['python'], 'Regex': r'[\w]',
                'TriggerKey': ['.']}

    def _GetJediScript(self, version):
        path = version['FilePath']
        line_nr = version['StartPosition']['Line'] + 1
        line_text = version['AllTextList']
        current_colum = version['StartPosition']['Colum']
        return jedi.Script(line_text,
                           line_nr,
                           current_colum,
                           path)

    def _analyze_params(self, line, show_default_value=False):
        # {{{

        # remove the first (, the last ) and the func name
        i = 0
        j = 0
        start = 0
        end = 0
        for item in line:
            if item == '(':
                if i == 0:
                    start = j
                i += 1
            elif item == ')':
                i -= 1
                end = j
                if i == 0:
                    break
            j += 1
        line = line[start+1:end] + ','

        i = 0
        j = 0
        temp = ''
        params = []
        for item in line:
            if item == '(':
                i += 1
                temp += '('
                continue
            elif item == ')':
                j += 1
                temp += ')'
                continue
            if item != ',':
                if item in ['\\', ' ', '/', '\n']:
                    pass
                else:
                    temp += item
            else:
                depth = i - j
                if depth != 0:
                    temp += item
                else:
                    if temp != '' and temp not in ['self', 'cls']:
                        # remove cls and self

                        has_default_value = False
                        if not show_default_value:
                            for litter in temp:
                                if litter in ['=']:
                                    has_default_value = True
                                    break
                        if not has_default_value:
                            params.append(temp)
                    temp = ''
        return params
    # }}}

    def _build_func_snippet(self, name, params, using_PEP8=True):
        # {{{ 
        if len(params) == 0:
            snippet = str(name) + '($1)$0'
        else:
            j = 0
            snippet = str(name) + '('
            for item in params:
                j += 1
                if j == len(params):
                    temp = '${' + str(j) + ':' + str(item) + '}'
                else:
                    temp = '${' + str(j) + ':' + str(item) + '}, '
                snippet += temp
            snippet += ')${0}'
        return snippet
    # }}}

    def _return_label(self, all_text_list):
        items_list = list(set(re.findall(r'\w+', all_text_list)))
        results_list = []
        for item in items_list:
            # the results_format must at least contain the following keys.
            results_format = {'abbr': '', 'word': '', 'kind': '',
                              'menu': '', 'info': '', 'user_data': ''}
            results_format['abbr'] = item
            results_format['word'] = item
            results_format['kind'] = '[ID]'
            results_list.append(results_format)
        return results_list

    def _is_comment(self, current_line, column):
        i = 0
        for word in current_line[:column]:
            if word in ['#']:
                if self.IsInsideQuotation(current_line, i):
                    return False
                return True
            i += 1
        return False

    def DoCompletion(self, version):
        # {{{
        return_ = {'ID': version['VersionID'], 'Server_name': self._name}

        current_colum = version['StartPosition']['Colum']
        current_line = version['CurrentLineText']
        if self.IsInsideQuotation(current_line, current_colum)\
                or self._is_comment(current_line, current_colum):
            return_['Lists'] = self._return_label(version['AllTextList'])
            return return_

        temp = self._GetJediScript(version).completions()
        if len(temp) == 0:
            return_['Lists'] = self._return_label(version['AllTextList'])
            return return_

        results_list = []
        for item in temp:
            results_format = {'abbr': '', 'word': '', 'kind': '',
                    'menu': '', 'info': '', 'user_data': ''}
            results_format['abbr'] = item.name_with_symbols
            results_format['word'] = item.name

            temp = item.type
            temp = temp[0].upper() + temp[1:]
            temp = str(temp)
            results_format['kind'] = temp

            results_format['menu'] = item.description
            temp = item.docstring()
            results_format['info'] = temp.split("\n")
            try:
                if item.type in ['function','class']:
                    params = self._analyze_params(temp)
                    snippet = self._build_func_snippet(item.name, params)
                    results_format['snippet'] = snippet
                    results_format['kind'] += '~'
            except Exception:
                pass
            results_list.append(results_format)
        return_['Lists'] = results_list
        return return_
        # }}}

    def GetSymbol(self, version):
        return_ = {'ID': version['VersionID'], 'Server_name': self._name}
        definitions = jedi.api.names(source=version['AllTextList'],
                                     all_scopes=True, definitions=True,
                                     references=False, path=version['FilePath'])
        lists = []
        for item in definitions:
            position = item._name.tree_name.get_definition()
            # start_column is 0-based
            (start_line, start_column) = position.start_pos
            item = [{'name': '1', 'content': {'abbr': item.name, 'highlight': 'ECY_blue'}},
                    {'name': '2', 'content': {'abbr': item.type, 'highlight': 'ECY_green'}},
                    {'name': '3', 'content': {'abbr': str(position.start_pos),  'highlight':'ECY_yellow'}}]
            position = {'line': start_line, 'colum': start_column, 'path': version['FilePath']}
            temp = {'items': item,
                    'type': 'symbol',
                    'position': position}
            lists.append(temp)
        return_['Results'] = lists
        return return_

    def GotoDefinition(self, version):
        return_ = {'ID': version['VersionID'], 'Server_name': self._name}
        definitions = self._GetJediScript(version).goto_definitions()
        definitions = self._GetJediScript(version)
        return_['Results'] = self._build_goto_response(definitions)
        return return_

    def GotoDeclaration(self, version):
        return_ = {'ID': version['VersionID'], 'Server_name': self._name}
        usages = self._GetJediScript(version).usages()
        return_['Results'] = self._build_goto_response(usages)
        return return_

    def GoToDeclarationOrDefinition(self, version):
        return_ = {'ID': version['VersionID'], 'Server_name': self._name}
        temp = self._GetJediScript(version)
        definitions = temp.goto_definitions()
        declarations = temp.goto_assignments()
        return_['Results'] = self._build_goto_response(definitions)
        for item in \
                self._build_goto_response(declarations, types='declaration'):
            return_['Results'].append(item)
        return return_

    def _build_goto_response(self, goto_info_list, types='definition'):
        goto = []
        for item in goto_info_list:
            # path is None when it is build in module
            temp = {'path': str(item.module_path)}

            temp['is_in_builtin_module'] = 'no'
            temp['types'] = types
            if item.in_builtin_module():
                temp['is_in_builtin_module'] = 'yes'
            else:
                temp['description'] = item.description
                temp['start_colum'] = item.column + 1
                temp['start_line'] = item.line
                temp['end_line'] = temp['start_line']
                temp['end_colum'] = temp['start_colum'] + len(temp['description'])
                temp['size'] = os.path.getsize(str(item.module_path)) # Bytes
            goto.append(temp)
        return goto
