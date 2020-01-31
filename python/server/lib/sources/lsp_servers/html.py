# Author: Jimmy Huang (1902161621@qq.com)
# License: WTFPL

# for basic
import re

# for htmlhint
import subprocess
import queue
from socket import *
import shlex
import json
import threading
from http.server import BaseHTTPRequestHandler, HTTPServer
global hint_content
hint_content = 'ok'

import utils.interface as scope_
import utils.lsp.language_server_protocol as lsp


class Operate(scope_.Source_interface):
    def __init__(self):
        self._name = 'html_lsp'
        self._did_open_list = {}
        self._lsp = lsp.LSP()
        self.is_server_start = 'not started'
        self._deamon_queue = None
        self._starting_server_cmd = None
        self._diagnosis_queue = queue.Queue()
        self._diagnosis = HtmlHint()
        self._is_http_server_started = None
        threading.Thread(target=self._diagnosis_notification).start()

    def GetInfo(self):
        return {'Name': self._name, 'WhiteList': ['html', 'xhtml'],
                'Regex': r'[\w-]',
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
            self._start_server()
        if self.is_server_start == 'started':
            return True
        return False

    def _start_server(self):
        ''' will only start once
        '''
        try:
            if self.is_server_start == 'not started':
                # cmd = "html-languageserver --stdio"
                # cmd = "node D:/gvim/nodejs/node-v10.13.0-win-x86/node_modules/vscode-html-languageserver-bin/htmlServerMain.js --stdio"
                self._lsp.StartJob(self._starting_server_cmd)

                # you can change the capabilities of init request like this:

                # capabilities_dict = self._lsp.BuildCapabilities()
                # capabilities_dict['completion']['dynamicRegistration'] = True
                init_msg = self._lsp.initialize(
                    initializationOptions=None, rootUri=None)
                self._lsp.GetResponse(init_msg['Method'])
                self.is_server_start = 'started'
        except: # noqa
            self.is_server_start = 'failed to start'
            if self._deamon_queue is not None:
                temp = {'ID': -1, 'Results': 'ok', 'ErroCode': 2,
                        'Event': 'erro_code',
                        'Description':
                        'Failed to start LSP server. Check Log file of server to get more details.'}
                self._deamon_queue.put(temp)

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
        return None

    def _return_label(self, all_text_list):
        items_list = list(set(re.findall(r'[\w\-]+', all_text_list)))
        results_list = []
        for item in items_list:
            # the results_format must at least contain the following keys.
            results_format = {'abbr': '', 'word': '', 'kind': '',
                    'menu': '', 'info': '','user_data':''}
            results_format['abbr'] = item
            results_format['word'] = item
            results_format['kind'] = '[ID]'
            results_list.append(results_format)
        return results_list

    def DoCompletion(self, version):
# {{{
        if not self._check(version):
            return None
        return_ = {'ID': version['VersionID'], 'Server_name': self._name}
        uri_ = self._lsp.PathToUri(version['FilePath'])
        line_text = version['AllTextList']
        current_start_postion = \
            {'line': version['StartPosition']['Line'],
             'character': version['StartPosition']['Colum']}
        self._did_open_or_change(uri_, line_text)
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
                for trigger, snippet in snippets:
                    results_format = {'abbr': '', 'word': '', 'kind': '',
                                      'menu': '', 'info': '', 'user_data': ''}
                    results_format['word'] = trigger
                    # results_format['abbr'] = trigger + ' ~'
                    results_format['abbr'] = trigger
                    results_format['kind'] = '[Snippet]'
                    results_format['menu'] = snippet['description']
                    results_list.append(results_format)
            else:
                results_list = self._return_label(line_text)
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

    def Diagnosis(self, version):
        self._diagnosis_queue.put(version)
        return None

    def _diagnosis_notification(self):
        address = ('localhost', self._diagnosis.GetUnusedLocalhostPort())
        server = HTTPServer(address, Handler)
        threading.Thread(target=server.serve_forever).start()
        while 1:
            version = self._diagnosis_queue.get()
            return_ = {'ID': version['VersionID'], 'Server_name': self._name}
            return_['Event'] = 'diagnosis'
            return_['FilePath'] = version['FilePath']
            return_['DocumentID'] = version['DocumentVersionID']
            workspace = version['WorkSpace']
            # if workspace is not None:
            #     cmd += '--config ' + workspace + '/.htmlhintrc'
            diagnosis_lists = self._diagnosis.GetDiagnosis(
                    version['HTMLHintCMD'],
                    version['AllTextList'],version['FilePath'])
            return_['Lists'] = diagnosis_lists
            if diagnosis_lists is None:
                # time out or something wrong
                # and we do nothing
                # continue
                return None
            self._deamon_queue.put(return_)


class HtmlHint:
    def __init__(self):
        self._port = -1

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
        cmd += " --format=json http://localhost:"
        cmd += str(self.GetUnusedLocalhostPort())
        cmd = shlex.split(cmd)
        process = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE)
        if process.wait(timeout=5) is None:
            return None
        temp = process.stdout.read()
        process.terminate()
        return temp

    def GetDiagnosis(self, cmd, buffers, file_path):
        global hint_content
        hint_content = buffers
        results = self._get(cmd)
        if results is None:
            # time out or something wrong
            return None
        results = results.split(b'\n')
        results = results[0].decode("UTF-8")
        results = json.loads(results)
        results_list = []
        for item in results:
            for msg in item['messages']:
                msg['col'] += 1
                pos_string = '[' + str(msg['line']) + ', ' + str(msg['col']) + ']'
                position = {'line': msg['line'], 'range': {
                    'start': {'line': msg['line'], 'colum': msg['col']},
                    'end': {'line': msg['line'], 'colum': msg['col']}}}
                temp = [{'name': '1', 'content': {'abbr': msg['message']}},
                        {'name': '2', 'content': {'abbr': msg['type']}},
                        {'name': '3', 'content': {'abbr': file_path}},
                        {'name': '4', 'content': {'abbr': pos_string}}]
                temp = {'items': temp,
                        'type': 'diagnosis',
                        'diagnosis': msg['rule']['description'],
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
        pass
