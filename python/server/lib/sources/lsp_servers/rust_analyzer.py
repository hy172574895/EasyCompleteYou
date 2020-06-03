# Author: Jimmy Huang (1902161621@qq.com)
# License: WTFPL

import ECY.utils.lsp.language_server_protocol as lsp
import ECY.utils.interface as scope_
import logging
import os
import threading
global g_logger
g_logger = logging.getLogger('ECY_server')


class Operate(scope_.Source_interface):
    def __init__(self):
        """ notes: 
        """
        self._name = 'rust_analyzer'
        self._did_open_list = {}
        self._lsp = lsp.LSP()
        self.is_server_start = 'not_started'
        self.DocumentVersionID = -1
        self._deamon_queue = None
        self._workspace_list = []
        self._diagnosis_cache = None
        self._opened_workspace = {}

    def GetInfo(self):
        return {'Name': self._name,
                'WhiteList': ['rust'],
                'Regex': r'[a-z0-9]',
                'TriggerKey': [":","."]}

    def _check(self, version):
        self._deamon_queue = version['DeamonQueue']
        # self._start_server(version['StartingCMD'],
        #         version['Vimruntime'], version['Runtimepath'])
        self._start_server(workspace=version['WorkSpace'],
                           starting_cmd=version['StartingCMD'],
                           is_enable_diagnosis=version['ReturnDiagnosis'])
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
        msg = msg.split('\n')
        g_logger.debug(msg)
        temp = {'ID': -1, 'Results': 'ok', 'ErroCode': code,
                'Event': 'erro_code',
                'Description': msg}
        self._output_queue(temp)
        

    def _start_server(self, starting_cmd="", workspace="",
            is_enable_diagnosis=True):
        if is_enable_diagnosis:
            is_enable_diagnosis = True

        try:
            if workspace not in self._opened_workspace:
                self.is_server_start = 'not_started'
                g_logger.debug('newed a new rust_analyzer Server.')

            if self.is_server_start == 'not_started':
                # starting_cmd = 'f:/rust/rust-analyzer-windows.exe'
                g_logger.debug(starting_cmd)

                # open new server process
                server_pid = self._lsp.StartJob(starting_cmd)
                if server_pid is None:
                    raise ''
                self._opened_workspace[workspace] = server_pid
                self._lsp.ChangeUsingServerID(server_pid)

                # send init request
                rooturi = self._lsp.PathToUri(workspace)
                temp = self._lsp.initialize(rootUri=rooturi)
                # if time out will raise, meanning can not start a job.
                self._lsp.GetResponse(temp['Method'], timeout_=5)

                # init
                threading.Thread(target=self._get_diagnosis,
                                 daemon=True).start()
                threading.Thread(target=self._handle_show_msg,
                                 daemon=True).start()
                threading.Thread(target=self._word_done_progress,
                                 daemon=True).start()
                self._lsp.initialized()
                self.is_server_start = 'started'
            self._lsp.ChangeUsingServerID(self._opened_workspace[workspace])
        except:
            self.is_server_start = 'started_error'
            g_logger.exception(': can not start Sever.')
            self._build_erro_msg(2,
                                 'Failed to start LSP server. Check Log file of server to get more details.')

    def _filter_log_msg(self, msg):
        """ return True means filter this msg.
        """
        if msg.find('no dep handle') != -1:
            # can not find that package
            return True
        if msg.find('AST') != -1:
            return True
        return False

    def _word_done_progress(self):
        g_logger.debug("started hanlde _word_done_progress thread.")
        while 1:
            try:
                response = self._lsp.GetResponse(
                    'window/workDoneProgress/create', timeout_=-1)
                ids = response['id']
                self._lsp.wordDoneProgress(ids)
            except:
                g_logger.exception('')
        

    def _handle_show_msg(self):
        g_logger.debug("started hanlde logmsg thread.")
        while 1:
            try:
                response = self._lsp.GetResponse(
                    'window/showMessage', timeout_=-1)
                response = response['params']
                msg = response['message']
                if self._filter_log_msg(msg):
                    continue
                types = response['type']
                if types == 1:
                    # error and warning
                    self._build_erro_msg(4, msg)
                elif types == 3:
                    # info, TODO
                    pass
            except:
                g_logger.exception('')

    def _did_open_or_change(self, uri, text, document_id, workspace):
        """ will ask diagnostics.
        """
        # {{{
        # LSP requires the edit-version
        if uri not in self._did_open_list:
            return_id = self._lsp.didopen(uri, 'rust', text, version=0)
            self._did_open_list[uri] = {}
            self._did_open_list[uri]['change_version'] = 0
        else:
            self._did_open_list[uri]['change_version'] += 1
            return_id = self._lsp.didchange(
                uri, text, version=self._did_open_list[uri]['change_version'])

        if self.DocumentVersionID == document_id:
            # to compat clangd
            self._output_queue(self._diagnosis_cache)
        self.DocumentVersionID = document_id

        return return_id
        # }}}

    def _waitting_for_response(self, method_, version_id):
        # {{{
        while 1:
            try:
                # GetTodo() will only wait for 5s,
                # after that will raise an erro
                self.return_data = None
                self.return_data = self._lsp.GetResponse(method_, timeout_=5)
                if self.return_data['id'] == version_id:
                    break
            except:  # noqa
                g_logger.exception('')
                return None
        return self.return_data
        # }}}

    def _get_diagnosis(self):
        return_ = {'Event': 'diagnosis'}
        while 1:
            try:
                temp = self._lsp.GetResponse('textDocument/publishDiagnostics',
                        timeout_=-1)
                return_['DocumentID'] = self.DocumentVersionID
                return_['Lists'] = self._diagnosis_analysis(temp['params'])
                self._diagnosis_cache = return_
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
            diagnosis = item['message'].replace("\n", '; ')
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

    def _analys_document_symbols(self, sources, file_path=None):
        lists = []
        if file_path is not None:
            path = file_path
        else:
            path = file_path
        for item in sources:
            kind = self._lsp.GetSymbolsKindByNumber(item['kind'])
            start_line = item['range']['start']['line'] + 1
            start_column = item['range']['start']['character']
            pos = self._genarate_position(start_line, start_column)
            position = {'line': start_line, 'colum': start_column,
                        'path': path}
            items = [{'name': '1', 'content': {'abbr': item['name']}},
                     {'name': '2', 'content': {'abbr': kind}},
                     {'name': '3', 'content': {'abbr': pos}}]
            temp = {'items': items,
                    'type': 'symbol',
                    'position': position}
            lists.append(temp)
        return lists

    def GetSymbol(self, version):
        """ document symbos and workspace symbos
        """
        if not self._check(version):
            return None
        return_ = {'ID': version['VersionID']}
        uri_ = self._lsp.PathToUri(version['FilePath'])
        temp = self._lsp.documentSymbos(uri_)
        # temp = self._lsp.workspaceSymbos()
        try:
            symbos = self._lsp.GetResponse(temp['Method'])
            symbos = symbos['result']
        except:
            symbos = []
        return_['Results'] = self._analys_document_symbols(symbos,
                version['FilePath'])
        return return_

    def GetWorkSpaceSymbol(self, version):
        if not self._check(version):
            return None
        return_ = {'ID': version['VersionID']}
        temp = self._lsp.workspaceSymbos()
        try:
            symbos = self._lsp.GetResponse(temp['Method'])
            symbos = symbos['result']
        except:
            symbos = []
        return_['Results'] = self._analys_document_symbols(symbos,
                version['FilePath'])
        return return_

    def _genarate_position(self, line, colum):
        return '[' + str(line) + ', ' + str(colum)+']'

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
                if item == 'declaration':
                    results = self._lsp.definition(position, uri_)
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
                if kind == "references":
                    start_line = item['range']['start']['line'] + 1
                    start_colum = item['range']['start']['character']
                    file_path = self._lsp.UriToPath(item['uri'])
                else:
                    start_line = item['targetSelectionRange']['start']['line'] + 1
                    start_colum = item['targetSelectionRange']['start']['character']
                    file_path = self._lsp.UriToPath(item['targetUri'])
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

    def OnBufferEnter(self, version):
        if self._check(version):
            # OnBufferEnter is a notification
            # so we return nothing
            uri_ = self._lsp.PathToUri(version['FilePath'])
            self._did_open_or_change(uri_, version['AllTextList'],
                                     version['DocumentVersionID'],
                                     version['WorkSpace'])
        # every event must return something. 'None' means send nothing to client
        return None

    def OnBufferTextChanged(self, version):
        if not self._check(version):
            return None
        uri_ = self._lsp.PathToUri(version['FilePath'])
        g_logger.debug('OnBufferTextChanged')
        line_text = version['AllTextList']
        self._did_open_or_change(uri_, line_text,
                                 version['DocumentVersionID'],
                                 version['WorkSpace'])

    def DoCompletion(self, version):
        if not self._check(version):
            return None
        g_logger.debug('DoCompletion')
        return_ = {'ID': version['VersionID']}
        uri_ = self._lsp.PathToUri(version['FilePath'])
        current_start_postion = \
            {'line': version['StartPosition']['Line'],
             'character': version['StartPosition']['Colum']}
        temp = self._lsp.completion(uri_, current_start_postion)

        _return_data = self._waitting_for_response(temp['Method'], temp['ID'])
        if _return_data is None:
            items = []
        else:
            items = _return_data['result']
        results_list = []
        for item in items:
            results_format = {'abbr': '', 'word': '', 'kind': '',
                              'menu': '', 'info': [], 'user_data': ''}
            results_format['abbr'] = item['label']
            results_format['word'] = item['label']
            results_format['kind'] = 'unknown'
            if 'kind' in item:
                results_format['kind'] = self._lsp.GetKindNameByNumber(
                    item['kind'])
            if 'detail' in item:
                results_format['menu'] = item['detail']
            if 'documentation' in item:
                documentation = item['documentation']
                if type(documentation) is dict:
                    documentation = documentation['value']
                results_format['info'] = documentation.split('\n')

            try:
                if item['insertTextFormat'] == 2:
                    temp = item['textEdit']['newText']
                    results_format['snippet'] = temp
                    results_format['kind'] += '~'
            except:
                pass
            results_list.append(results_format)
        return_['Lists'] = results_list
        return return_
    
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
        if type(results) == list:
            pass
        else:
            results = results['contents']
            return_list = results['value'].split("\n")
        return_['Results'] = return_list
        return return_
