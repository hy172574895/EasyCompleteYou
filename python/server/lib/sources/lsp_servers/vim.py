# Author: Jimmy Huang (1902161621@qq.com)
# License: WTFPL

import logging
import threading
global g_logger
g_logger = logging.getLogger('ECY_server')

import ECY.utils.interface as scope_
import ECY.utils.lsp.language_server_protocol as lsp


class Operate(scope_.Source_interface):
    def __init__(self):
        self._name = 'vim_lsp'
        self._did_open_list = {}
        self._lsp = lsp.LSP()
        self.is_server_start = 'not_started'
        self._deamon_queue = None

    def GetInfo(self):
        return {'Name': self._name, 'WhiteList': ['vim'],
                'Regex': r'[a-z0-9\#\&\:]',
                'TriggerKey': ['.', ':', '#', '[', '&', '$', '<', '"', "'"]}

    def _output_queue(self, msg):
        if self._deamon_queue is not None and msg is not None:
            msg['EngineName'] = self._name
            self._deamon_queue.put(msg)

    def _check(self, version):
        self._deamon_queue = version['DeamonQueue']
        self._start_server(version['StartingCMD'],
                version['Vimruntime'], version['Runtimepath'])
        if self.is_server_start == 'started':
            return True
        return False

    def _build_erro_msg(self, code, msg):
        """and and send it
        """
        temp = {'ID': -1, 'Results': 'ok', 'ErroCode': code,
                'Event': 'erro_code',
                'Description':msg}
        self._output_queue(temp)

    def _start_server(self, starting_cmd, vimruntime="", runtimepath=""):
        try:
            if self.is_server_start == 'not_started':
                # such as : node C:/Windows/SysWOW64/node_modules/vim-language-server/bin/index.js --stdio
                starting_cmd = 'node C:/Windows/SysWOW64/node_modules/vim-language-server/bin/index.js --stdio'
                capabilities = self._lsp.BuildCapabilities()
                capabilities['workspace']['configuration'] = True
                self._lsp.StartJob(starting_cmd)
                init_opts = {
                    "iskeyword": "@,48-57,_,192-255,-#",
                    "vimruntime": vimruntime,
                    "runtimepath": runtimepath,
                    "diagnostic": {
                        "enable": True
                    },
                    "indexes": {
                        "runtimepath": True,
                        "gap": 100,
                        "count": 3,
                        "projectRootPatterns": ["strange-root-pattern",
                                                ".git",
                                                "autoload",
                                                "plugin"]
                    },
                    "suggest": {
                        "fromVimruntime": True,
                        "fromRuntimepath": True
                    }
                }
                temp = self._lsp.initialize(initializationOptions=init_opts,
                        capabilities=capabilities)
                # if time out will raise, meanning can not start a job.
                self._lsp.GetResponse(temp['Method'])
                self.is_server_start = 'started'
                threading.Thread(target=self._get_diagnosis, daemon=True).start()
        except: # noqa
            self.is_server_start = 'started_error'
            g_logger.exception('vim_lsp: can not start Sever.' )
            self._build_erro_msg(2,
                    'Failed to start LSP server. Check Log file of server to get more details.')

    def _did_open_or_change(self, uri, text):
        # {{{
        # LSP require the edit-version
        if uri not in self._did_open_list:
            return_id = self._lsp.didopen(uri, 'vim', text, version=0)
            self._did_open_list[uri] = {}
            self._did_open_list[uri]['change_version'] = 0
        else:
            self._did_open_list[uri]['change_version'] += 1
            return_id = self._lsp.didchange(
                uri, text, version=self._did_open_list[uri]['change_version'])
        return return_id
        # }}}

    def _waitting_for_response(self, method_, version_id):
        # {{{
        while 1:
            try:
                # GetTodo() will only wait for 5s,
                # after that will raise an erro
                self.return_data = None
                self.return_data = self._lsp.GetResponse(method_)
                if self.return_data['id'] == version_id:
                    break
            except: # noqa
                return None
        return self.return_data
        # }}}

    def OnBufferEnter(self, version):
        self._update_text(version)
        return None

    def OnBufferTextChanged(self, version):
        self._update_text(version)
        return None

    def DoCompletion(self, version):
        if not self._check(version):
            return None
        return_ = {'ID': version['VersionID']}
        uri_ = self._lsp.PathToUri(version['FilePath'])
        current_start_postion = \
            {'line': version['StartPosition']['Line'],
             'character': version['StartPosition']['Colum']}
        temp = self._lsp.completion(uri_, current_start_postion)

        # we can set this raising a erro when it is timeout.
        _return_data = self._waitting_for_response(temp['Method'], temp['ID'])

        if _return_data is None:
            items_list = []
        else:
            if _return_data['result'] is None:
                items_list = []
            else:
                items_list = _return_data['result']

        results_list = []
        if items_list == []:
            if 'UltisnipsSnippets' in version:
                for trigger, snippet in version['UltisnipsSnippets'].items():
                    results_format = {'abbr': '', 'word': '', 'kind': '',
                                      'menu': '', 'info': '', 'user_data': ''}
                    results_format['word'] = trigger
                    results_format['abbr'] = trigger+'~'
                    results_format['kind'] = '[Snippet]'
                    results_format['menu'] = snippet['description']
                    results_list.append(results_format)
        else:
            for item in items_list:
                results_format = {'abbr': '', 'word': '', 'kind': '',
                                  'menu': '', 'info': [], 'user_data':''}
                results_format['abbr'] = item['label']
                results_format['word'] = item['label']
                results_format['kind'] = self._lsp.GetKindNameByNumber(item['kind'])
                if 'detail' in item:
                    results_format['menu'] = item['detail']
                try:
                    if item['insertTextFormat'] == 2:
                        results_format['snippet'] = item['insertText']
                        results_format['kind'] += '~'
                except:
                    pass
                results_list.append(results_format)
        return_['Lists'] = results_list
        return return_

    def _update_text(self, version):
        if self._check(version):
            uri_ = self._lsp.PathToUri(version['FilePath'])
            line_text = version['AllTextList']
            self._did_open_or_change(uri_, line_text)

    def _get_diagnosis(self):
        return_ = {'Event': 'diagnosis'}
        while 1:
            try:
                # we alwayes Get Response after we didchange/didopen textDocument,
                # so(maybe) this safe Thread.
                temp = self._lsp.GetResponse('textDocument/publishDiagnostics',
                        timeout_=-1)
                temp = self._diagnosis_analysis(temp['params'])
                return_['Lists'] = temp
                self._output_queue(return_)
            except:
                g_logger.exception('')

    def _diagnosis_analysis(self, params):
        results_list = []
        file_path = self._lsp.UriToPath(params['uri'])
        if file_path == '':
            return results_list
        for item in params['diagnostics']:
            ranges = item['range']
            start_line = ranges['start']['line'] + 1
            start_colum = ranges['start']['character']
            end_line = ranges['end']['line'] + 1
            end_colum = ranges['end']['character']
            pos_string = '[' + str(start_line) + ', ' + str(start_colum)+']'
            position = {'line': start_line, 'range': {
                'start': {'line': start_line, 'colum': start_colum},
                'end': {'line': end_line, 'colum': end_colum}}}
            diagnosis = item['message']
            if item['severity'] == 1:
                kind = 1
            else:
                kind = 2
            kind_name = self._lsp.GetDiagnosticSeverity(item['severity'])
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
            results_list.append(temp)
        return results_list

