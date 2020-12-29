# Author: Jimmy Huang (1902161621@qq.com)
# License: WTFPL

# for basic
import logging
global g_logger
g_logger = logging.getLogger('ECY_server')

# for htmlhint
import subprocess
import os
import queue
import time
from socket import *
import shlex
import json
import threading
from http.server import BaseHTTPRequestHandler, HTTPServer
global hint_content
hint_content = 'ok'

import ECY.utils.interface as scope_
import ECY.utils.lsp.language_server_protocol as lsp


class Operate(scope_.Source_interface):
    def __init__(self):
        self._name = 'html_lsp'
        self._did_open_list = {}
        self._lsp = lsp.LSP()
        self._deamon_queue = None
        self._starting_server_cmd = None
        self._diagnosis_queue = queue.LifoQueue()
        self._htmlHint = HtmlHint()
        self._is_http_server_started = None
        self.is_server_start = 'not started'
        threading.Thread(target=self._handle_diagnosis).start()

    def GetInfo(self):
        return {'Name': self._name, 'WhiteList': ['html', 'xhtml', 'vue'],
                'Regex': r'[A-Za-z0-9\_\-]',
                'TriggerKey': ['.', ':', '"', '\'', '<', '=', '/']}

    def _check(self, version):
        ''' check Environment and start LSP server.
        Return True means that checking is pass.
        Return False means that checking is fail.
        And this 'check' make sure the server was started.
        '''
        self._deamon_queue = version['DeamonQueue']
        if self._starting_server_cmd is None:
            if 'StartingCMD' in version.keys():
                self._starting_server_cmd = version['StartingCMD']
        if self._starting_server_cmd is not None:
            self._start_lsp_server()
        if self.is_server_start == 'started':
            return True
        return False

    def _output_queue(self, msg):
        if self._deamon_queue is not None and msg is not None:
            msg['EngineName'] = self._name
            self._deamon_queue.put(msg)

    def _build_erro_msg(self, code, msg):
        """and and send it
        """
        temp = {'ID': -1, 'Results': 'ok', 'ErroCode': code,
                'Event': 'erro_code',
                'Description':msg}
        self._output_queue(temp)

    def _start_lsp_server(self):
        ''' will only start once
        '''
        try:
            if self.is_server_start == 'not started':
                # cmd = "html-languageserver --stdio"
                self._lsp.StartJob(self._starting_server_cmd)
                init_msg = self._lsp.initialize(
                    initializationOptions=None, rootUri=None)
                self._lsp.GetResponse(init_msg['Method'])
                self.is_server_start = 'started'
        except:
            g_logger.exception(self._starting_server_cmd)
            self.is_server_start = 'failed to start'
            self._build_erro_msg(2,
                    'Failed to start LSP server. Check Log file of server to get more details.')

    def _did_open_or_change(self, uri, text):
        '''update text to server
        '''
        # {{{ 
        # LSP require the edit-version
        if uri not in self._did_open_list:
            return_id = self._lsp.didopen(uri, 'html', text, version=0)
            self._did_open_list[uri] = {}
            self._did_open_list[uri]['change_version'] = 0
        else:
            self._did_open_list[uri]['change_version'] += 1
            return_id = self._lsp.didchange(
                uri, text, version=self._did_open_list[uri]['change_version'])
        return return_id
        # }}}

    def _waitting_for_response(self, method_, version_id):
        '''get the newest results
        '''
        # {{{
        while 1:
            try:
                # GetTodo() will only wait for 5s,
                # after that, it will raise an erro
                self.return_data = None
                self.return_data = self._lsp.GetResponse(method_)
                if self.return_data['id'] == version_id:
                    break
            except: # noqa
                self._log.exception("a timeout queue.")
                # return None
                break
        return self.return_data
        # }}}

    def OnBufferEnter(self, version):
        if self._check(version):
            # OnBufferEnter is a notification
            # so we return nothing
            uri_ = self._lsp.PathToUri(version['FilePath'])
            line_text = version['AllTextList']
            self._did_open_or_change(uri_, line_text)
        # every event must return something. 'None' means send nothing to client
        self._diagnosis(version)
        return None

    def OnDocumentHelp(self, version):
        if not self._check(version):
            return None
        current_start_postion = \
            {'line': version['StartPosition']['Line'],
             'character': version['StartPosition']['Colum']}
        uri_ = self._lsp.PathToUri(version['FilePath'])
        temp = self._lsp.hover(uri_, current_start_postion)
        results = self._lsp.GetResponse(temp['Method'])
        results = results['result']
        return_ = {'ID': version['VersionID'], 'Results': []}
        if results is None:
            return return_
        return_list = []
        results = results['contents']

        if type(results) == list:
            return_list.append(results[0]['value'])
            return_list.extend(results[1].split('\n'))
        elif type(results) == str:
            return_list.append(results)

        return_['Results'] = return_list
        return return_

    def Goto(self, version):
        if not self._check(version):
            return None
        return_ = {'ID': version['VersionID']}
        position = \
            {'line': version['StartPosition']['Line'],
             'character': version['StartPosition']['Colum']}
        uri_ = self._lsp.PathToUri(version['FilePath'])
        result_lists = []
        for item in version['GotoLists']:
            try:
                if item == 'references':
                    # included declaration
                    results = self._lsp.references(position, uri_)
                if item == 'definition':
                    results = self._lsp.definition(position, uri_)
                # if item == 'declaration':
                #     results = self._lsp.definition(position, uri_)
                results = self._lsp.GetResponse(results['Method'])
                result_lists = self._build_goto(results, result_lists,kind=item)
            except:
                # will return []
                g_logger.exception('')
        return_['Results'] = result_lists
        return return_

    def _build_goto(self, results, result_lists, kind="definition"):
        if 'error' not in results:
            results = results['result']
            for item in results:
                start_line = item['range']['start']['line'] + 1
                start_colum = item['range']['start']['character']
                # end_line = item['range']['end']['line'] + 1
                # end_colum = item['range']['end']['character']

                file_path = self._lsp.UriToPath(item['uri'])
                file_size = str(int(os.path.getsize(file_path)/1000)) + 'KB'
                position = {'line': start_line,
                            'colum': start_colum, 'path': file_path}
                pos = '[' + str(start_line) + ', ' + str(start_colum) + ']'
                items = [{'name': '1', 'content': {'abbr': kind}},
                         {'name': '3', 'content': {'abbr': pos}},
                         {'name': '4', 'content': {'abbr': file_path}},
                         {'name': '5', 'content': {'abbr': file_size}}]
                temp = {'items': items,
                        'type': kind,
                        'position': position}
                result_lists.append(temp)
        return result_lists

    def OnBufferTextChanged(self, version):
        if version['IsInsertMode']:
            # only for completion 
            uri_ = self._lsp.PathToUri(version['FilePath'])
            line_text = version['AllTextList']
            self._did_open_or_change(uri_, line_text)
        self._diagnosis(version)

    def _return_snippets(self, items):
        results_list = []
        for trigger, snippet in items:
            results_format = {'abbr': '', 'word': '', 'kind': '',
                              'menu': '', 'info': '', 'user_data': ''}
            results_format['word'] = trigger
            # results_format['abbr'] = trigger + ' ~'
            results_format['abbr'] = trigger
            results_format['kind'] = '[Snippet]'
            description = snippet['description']
            if not snippet['description'] == '':
                results_format['menu'] = description
            results_format['info'] = snippet['preview']
            results_list.append(results_format)
        return results_list

    def DoCompletion(self, version):
# {{{
        if not self._check(version):
            return None

        return_ = {'ID': version['VersionID']}
        uri_ = self._lsp.PathToUri(version['FilePath'])
        current_start_postion = \
            {'line': version['StartPosition']['Line'],
             'character': version['StartPosition']['Colum']}
        temp = self._lsp.completion(uri_, current_start_postion)
        _return_data = self._waitting_for_response(temp['Method'], temp['ID'])
        if _return_data is None:
            items_list = []
        else:
            if _return_data['result'] is None:
                items_list = []
            else:
                items_list = _return_data['result']['items']

        results_list = []
        if items_list == []:
            # return snippet or ID
            current_colum = version['StartPosition']['Colum']
            current_line = version['CurrentLineText']
            if version['Additional']['HasSnippetSupport']\
                    and not self.IsInsideQuotation(current_line, current_colum):
                snippets = version['Additional']['UltisnipsSnippets'].items()
                results_list = self._return_snippets(snippets)
            else:
                # return ID(buffers)
                results_list = []
        else:
            for item in items_list:
                results_format = {'abbr': '', 'word': '', 'kind': '',
                                  'menu': '', 'info': '', 'user_data':''}
                results_format['abbr'] = item['label']
                results_format['word'] = item['label']
                results_format['kind'] = self._lsp.GetKindNameByNumber(item['kind'])
                if 'documentation' in item:
                    temp = str(item['documentation'])
                    temp = temp.split('\n')
                    results_format['info'] = temp
                try:
                    if item['kind'] == 3:
                        # Function
                        results_format['kind'] += '~'
                        results_format['snippet'] = item['label'] + '($1)$0'
                    if item['insertTextFormat'] == 2:
                        # results_format['abbr'] += ' ~'
                        results_format['kind'] = '[Snippet]'
                        if 'newText' in item['textEdit']:
                            temp = item['textEdit']['newText']
                            results_format['snippet'] = temp
                except: # noqa
                    pass
                results_list.append(results_format)
        return_['Lists'] = results_list
        return return_
# }}}

    def _diagnosis(self, version):
        if self._htmlHint.is_available == 1:
            self._diagnosis_queue.put(version)
        elif self._htmlHint.is_available == 2:
            self._htmlHint.is_available = 3
            self._build_erro_msg(4, "Failed to call HtmlHint.")
        return None

    def _genarate_position(self, line, colum):
        return '[' + str(line) + ', ' + str(colum)+']'

    def GetSymbol(self, version):
        if not self._check(version):
            return None
        return_ = {'ID': version['VersionID']}
        uri_ = self._lsp.PathToUri(version['FilePath'])
        temp = self._lsp.documentSymbos(uri_)
        try:
            symbos = self._lsp.GetResponse(temp['Method'])
            symbos = symbos['result']
        except:
            symbos = []
        lists = []
        for item in symbos:
            kind = self._lsp.GetSymbolsKindByNumber(item['kind'])
            ranges = item['location']
            start_line = ranges['range']['start']['line'] + 1
            start_column = ranges['range']['start']['character']
            pos = self._genarate_position(start_line, start_column)
            position = {'line': start_line, 'colum': start_column,
                        'path': version['FilePath']}
            name = item['name']
            items = [{'name': '1', 'content': {'abbr': name}},
                     {'name': '2', 'content': {'abbr': kind}},
                     {'name': '3', 'content': {'abbr': pos}}]
            g_logger.debug(items)
            temp = {'items': items,
                    'type': 'symbol',
                    'position': position}
            lists.append(temp)
        return_['Results'] = lists
        return return_
        
    def _handle_diagnosis(self):
        address = ('localhost', self._htmlHint.GetUnusedLocalhostPort())
        server = HTTPServer(address, Handler)
        threading.Thread(target=server.serve_forever).start()
        self.document_id = -1
        return_ = {'EngineName': self._name, 'Event': 'diagnosis'}
        while 1:
            try:
                version = self._diagnosis_queue.get()
                if version['DocumentVersionID'] <= self.document_id:
                    g_logger.debug('filter a unless diagnosis')
                    continue
                self.document_id = version['DocumentVersionID']
                return_['ID'] = version['VersionID']
                return_['DocumentID'] = self.document_id
                # workspace = version['WorkSpace']
                # if workspace is not None:
                #     cmd += '--config ' + workspace + '/.htmlhintrc'
                diagnosis_lists = self._htmlHint.GetDiagnosis(
                        version['HTMLHintCMD'],
                        version['AllTextList'], version['FilePath'])
                return_['Lists'] = diagnosis_lists
                self._output_queue(return_)
                time.sleep(1)
            except:
                g_logger.exception('')

    # TODO: not well 
    # def Goto(self, version):
    #     if not self._check(version):
    #         return None
    #     # return_ = {'ID': version['VersionID'], 'EngineName': self._name}
    #     temp = self._lsp.symbos('h')
    #     temp = self._lsp.GetResponse(temp['Method'])
    #     g_logger.debug(temp)
    #     return None


class HtmlHint:
    def __init__(self):
        self._port = -1
        self.is_available = 1
        self._cmd = " --format=json http://localhost:" + \
                str(self.GetUnusedLocalhostPort())
        g_logger.debug('started html diagnosis thread.')
        g_logger.debug(self._cmd)

    def GetUnusedLocalhostPort(self):
        if self._port == -1:
            sock = socket() # noqa
            # This tells the OS to give us any free port in the
            # range [1024 - 65535]
            sock.bind(('', 0))
            port = sock.getsockname()[1]
            self._port = port
            sock.close()
        return self._port

    def _get(self, cmd):
        """start annalysis and put results to queue
        """
        cmd += self._cmd
        try:
            cmd = shlex.split(cmd)
            process = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE)
            temp = process.stdout.read()
            process.terminate()
        except:
            g_logger.exception("something wrong")
            temp = None
        return temp

    def GetDiagnosis(self, cmd, buffers, file_path):
        global hint_content
        hint_content = buffers
        results = self._get(cmd)
        if results is None:
            # time out or something wrong
            return None
        try:
            results = results.split(b'\n')
            results = results[0].decode("UTF-8")
            results = json.loads(results)
        except:
            # user may have no htmlhint
            g_logger.exception("can not call htmlhint.")
            self.is_available = 2
            return None
        results_list = []
        for item in results:
            for msg in item['messages']:
                # msg['col'] is 0-based
                pos_string = '[' + str(msg['line']) + ', ' + str(msg['col'])+']'
                position = {'line': msg['line'], 'range': {
                    'start': {'line': msg['line'], 'colum': msg['col']},
                    'end': {'line': msg['line'], 'colum': msg['col']}}}
                # can work too:
                # diagnosis = msg['rule']['description']
                diagnosis = msg['message']
                if msg['type'] == 'error':
                    kind = 1
                else:
                    # warn
                    kind = 2
                temp = [{'name': '1', 'content': {'abbr': diagnosis}},
                        {'name': '2', 'content': {'abbr': msg['type']}},
                        {'name': '3', 'content': {'abbr': file_path}},
                        {'name': '4', 'content': {'abbr': pos_string}}]
                temp = {'items': temp,
                        'type': 'diagnosis',
                        'file_path': file_path,
                        'kind': kind,
                        'diagnosis': diagnosis,
                        'position': position}
                results_list.append(temp)
        return results_list


class Handler(BaseHTTPRequestHandler):

    def do_GET(self):
        self.send_response(200)
        self.send_header('Content-type','text/html')
        self.end_headers()
        self.wfile.write(hint_content.encode())

    def log_request(self, code='-', size='-'):
        """ make server don't output msg to shell.
        """
        pass
