# Author: Jimmy Huang (1902161621@qq.com)
# License: WTFPL

import os
import queue
import threading
import time
import logging
global g_logger
g_logger = logging.getLogger('ECY_server')

try:
    import jedi
    has_jedi = True
except:
    has_jedi = False
try:
    from pyflakes import api as pyflakes_api, messages
    has_pyflake = True
except:
    has_pyflake = False

import utils.interface as scope_

if has_pyflake:
    PYFLAKES_ERROR_MESSAGES = (
        messages.UndefinedName,
        messages.UndefinedExport,
        messages.UndefinedLocal,
        messages.DuplicateArgument,
        messages.FutureFeatureNotDefined,
        messages.ReturnOutsideFunction,
        messages.YieldOutsideFunction,
        messages.ContinueOutsideLoop,
        messages.BreakOutsideLoop,
        messages.ContinueInFinally,
        messages.TwoStarredExpressions,
    )



class Operate(scope_.Source_interface):
    def __init__(self):
        # a jedi bug:
        # check https://github.com/davidhalter/jedi-vim/issues/870
        # revert to 0.9 of jedi can fix this

        # FIXME:when completing the last line of a method or a class will
        # show only a few of items, mabye, because the cache's system position
        # don't match with jedi
        # revert to 0.9 of jedi can also fix this
        self._name = 'python_jedi'
        self._deamon_queue = None
        g_logger.debug('python_jedi has pyflakes:' + str(has_pyflake))
        self._jedi_cache = None
        if has_pyflake:
            self._diagnosis_queue = queue.LifoQueue()
            threading.Thread(target=self._output_diagnosis,
                             daemon=True).start()

    def GetInfo(self):
        return {'Name': self._name, 'WhiteList': ['python'], 'Regex': r'[\w]',
                'TriggerKey': ['.']}

    def _GetJediScript(self, version):
        try:
            path = version['FilePath']
            line_nr = version['StartPosition']['Line'] + 1
            line_text = version['AllTextList']
            current_colum = version['StartPosition']['Colum']
            temp = jedi.Script(line_text,
                               line_nr,
                               current_colum,
                               path)
            self._jedi_cache = temp
            return temp
        except:
            return self._jedi_cache

    def _check(self, version):
        self._deamon_queue = version['DeamonQueue']
        if not has_jedi:
            return False
        return True

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
        # if version['ReturnDiagnosis']:
        if not self._check(version):
            return None

        return_ = {'ID': version['VersionID']}
        current_colum = version['StartPosition']['Colum']
        current_line = version['CurrentLineText']
        if self.IsInsideQuotation(current_line, current_colum)\
                or self._is_comment(current_line, current_colum):
            return_['Lists'] = []
            return return_

        try:
            # sometimes, jedi will fail, so we try.
            temp = self._GetJediScript(version).completions()
        except:
            g_logger.exception("jedi bug:")
            temp = []
        if len(temp) == 0:
            return_['Lists'] = []
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
                if item.type in ['function', 'class']:
                    params = self._analyze_params(temp)
                    snippet = self._build_func_snippet(item.name, params)
                    results_format['snippet'] = snippet
                    results_format['kind'] += '~'
            except:
                pass
            results_list.append(results_format)
        return_['Lists'] = results_list
        return return_
        # }}}

    def GetSymbol(self, version):
        if not self._check(version):
            return None
        return_ = {'ID': version['VersionID']}
        try:
            # in embed python, some of this can not find module path.
            # So we try
            definitions = jedi.api.names(source=version['AllTextList'],
                                         all_scopes=True, definitions=True,
                                         references=False, path=version['FilePath'])
        except:
            definitions = []
            g_logger.exception('')
        lists = []
        for item in definitions:
            position = item._name.tree_name.get_definition()
            # start_column is 0-based
            (start_line, start_column) = position.start_pos
            items = [{'name': '1', 'content': {'abbr': item.name, 'highlight': 'ECY_blue'}},
                     {'name': '2', 'content': {
                         'abbr': item.type, 'highlight': 'ECY_green'}},
                     {'name': '3', 'content': {'abbr': str(position.start_pos),  'highlight': 'ECY_yellow'}}]
            position = {'line': start_line, 'colum': start_column,
                        'path': version['FilePath']}
            temp = {'items': items,
                    'type': 'symbol',
                    'position': position}
            lists.append(temp)
        return_['Results'] = lists
        return return_

    def OnBufferEnter(self, version):
        self._diagnosis(version)
        if self._check(version):
            return None
        return {'ID': version['VersionID'], 'Results': 'ok', 'ErroCode': 3,
                'Event': 'erro_code',
                'Description': 'You are missing jedi. So this engine can not work.'}

    def Goto(self, version):
        if not self._check(version):
            return None
        return_ = {'ID': version['VersionID']}
        result_lists = []
        for item in version['GotoLists']:
            try:
                # in embed python, some of this can not find module path.
                # So we try
                if item == 'definition':
                    result_lists = self._goto_definition(version, result_lists)
                if item == 'declaration':
                    result_lists = self._goto_declaration(
                        version, result_lists)
                if item == 'references':
                    result_lists = self._goto_reference(version, result_lists)
            except:
                # will return []
                g_logger.exception('')
        return_['Results'] = result_lists
        return return_

    def _goto_definition(self, version, results):
        # can return mutiple definitions
        definitions = self._GetJediScript(version).goto_definitions()
        return self._build_goto(definitions, results, 'goto_definitions')

    def _goto_declaration(self, version, results):
        assisment = self._GetJediScript(version).goto_assignments()
        return self._build_goto(assisment, results, 'goto_declaration')

    def _goto_reference(self, version, results):
        usages = self._GetJediScript(version).usages()
        return self._build_goto(usages, results, 'goto_reference')

    def _build_goto(self, goto_sources, results, kind):
        for item in goto_sources:
            if item.in_builtin_module():
                path = " "
                file_size = " "
                pos = 'Buildin'
                position = {}
            else:
                path = str(item.module_path)
                file_size = str(int(os.path.getsize(path)/1000)) + 'KB'
                pos = '[' + str(item.line) + ', ' + str(item.column) + ']'
                position = {'line': item.line,
                            'colum': item.column, 'path': path}

            items = [{'name': '1', 'content': {'abbr': item.description}},
                     {'name': '2', 'content': {'abbr': kind}},
                     {'name': '3', 'content': {'abbr': pos}},
                     {'name': '4', 'content': {'abbr': path}},
                     {'name': '5', 'content': {'abbr': file_size}}]

            temp = {'items': items,
                    'type': kind,
                    'position': position}
            results.append(temp)
        return results

    def OnBufferTextChanged(self, version):
        self._diagnosis(version)

    def _diagnosis(self, version):
        if has_pyflake and self._deamon_queue is not None:
            self._diagnosis_queue.put(version)
        return None

    def _output_diagnosis(self):
        reporter = PyflakesDiagnosticReport('')
        self.document_id = -1
        while 1:
            try:
                version = self._diagnosis_queue.get()
                if version['DocumentVersionID'] <= self.document_id:
                    g_logger.debug(version['DocumentVersionID'])
                    continue
                self.document_id = version['DocumentVersionID']
                return_ = {'ID': version['VersionID']}
                return_['Event'] = 'diagnosis'
                return_['EngineName'] = self._name
                return_['DocumentID'] = self.document_id
                reporter.SetContent(version['AllTextList'])
                pyflakes_api.check(
                    version['AllTextList'],
                    version['FilePath'],
                    reporter=reporter)
                return_['Lists'] = reporter.GetDiagnosis()
                self._deamon_queue.put(return_)
                time.sleep(1)
            except:
                g_logger.exception('diagnosis of python_jedi')


class PyflakesDiagnosticReport(object):

    def __init__(self, _):
        self.lines = ''
        self.results_list = []

    def GetDiagnosis(self):
        return self.results_list

    def SetContent(self, lines):
        self.lines = lines
        self.results_list = []

    def unexpectedError(self, file_path, msg):  # pragma: no cover
        position = {'line': 1, 'range': {
            'start': {'line': 1, 'colum': 0},
            'end': {'line': 1, 'colum': 0}}}
        diagnosis = 'unexpected Error'
        pos_string = '[1, 0]'
        kind = 1
        kind_name = 'unexpectedError'
        temp = [{'name': '1', 'content': {'abbr': diagnosis}},
                {'name': '2', 'content': {'abbr': kind_name}},
                {'name': '3', 'content': {'abbr': file_path}},
                {'name': '4', 'content': {'abbr': pos_string}}]
        temp = {'items': temp,
                'type': 'diagnosis',
                'file_path': file_path,
                'kind': kind,
                'diagnosis': diagnosis,
                'position': position}
        self.results_list.append(temp)

    def _genarate_position(self, line, colum):
        return '[' + str(line) + ', ' + str(colum)+']'

    def syntaxError(self, file_path, diagnosis, lineno, offset, text):
        # We've seen that lineno and offset can sometimes be None
        lineno = lineno or 1
        offset = offset or 0

        erro_line_nr = lineno
        position = {'line': erro_line_nr, 'range': {
            'start': {'line': erro_line_nr, 'colum': offset},
            'end': {'line': erro_line_nr, 'colum': offset + len(text)}}}
        pos_string = self._genarate_position(erro_line_nr, offset)
        kind = 1
        kind_name = 'syntaxError1'
        temp = [{'name': '1', 'content': {'abbr': diagnosis}},
                {'name': '2', 'content': {'abbr': kind_name}},
                {'name': '3', 'content': {'abbr': file_path}},
                {'name': '4', 'content': {'abbr': pos_string}}]

        temp = {'items': temp,
                'type': 'diagnosis',
                'file_path': file_path,
                'kind': kind,
                'diagnosis': diagnosis,
                'position': position}
        self.results_list.append(temp)

    def flake(self, message):
        """ Get message like <filename>:<lineno>: <msg> """
        # 0-based
        erro_line_nr = message.lineno
        position = {'line': erro_line_nr, 'range': {
            'start': {'line': erro_line_nr, 'colum': message.col},
            'end': {
                'line': erro_line_nr,
                'colum': message.col}}}
        pos_string = self._genarate_position(erro_line_nr, message.col)

        kind_name = 'syntaxWarning'
        kind = 2
        diagnosis = message.message % message.message_args
        file_path = message.filename
        for message_type in PYFLAKES_ERROR_MESSAGES:
            if isinstance(message, message_type):
                kind_name = 'syntaxError2'
                kind = 1
                break
        temp = [{'name': '1', 'content': {'abbr': diagnosis}},
                {'name': '2', 'content': {'abbr': kind_name}},
                {'name': '3', 'content': {'abbr': file_path}},
                {'name': '4', 'content': {'abbr': pos_string}}]

        temp = {'items': temp,
                'type': 'diagnosis',
                'file_path': file_path,
                'kind': kind,
                'diagnosis': diagnosis,
                'position': position}
        self.results_list.append(temp)
