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
        self._name = 'go_gopls'
        self._did_open_list = {}
        self._lsp = lsp.LSP()
        self.is_server_start = 'not_started'
        self.DocumentVersionID = -1
        self._deamon_queue = None
        self._workspace_list = []
        self.BASE_DIR = os.path.dirname(os.path.abspath(__file__))
        self._workspace = None

    def GetInfo(self):
        return {'Name': self._name, 'WhiteList': ['go'],
                'Regex': r'[A-Za-z0-9\_]',
                'TriggerKey': ['.']}

    def _check(self, version):
        self._deamon_queue = version['DeamonQueue']
        # self._start_server(version['StartingCMD'],
        #         version['Vimruntime'], version['Runtimepath'])
        self._workspace =  version['WorkSpace']
        self._start_server(workspace=self._workspace,
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

    def _save_log_msg(self, ):
        pass

    def _start_server(self, starting_cmd="", workspace="",
            is_enable_diagnosis=True):
        if is_enable_diagnosis:
            is_enable_diagnosis = True
        try:
            if self.is_server_start == 'not_started':
                if starting_cmd == "":
                    starting_cmd = 'gopls'
                self._lsp.StartJob(starting_cmd)
                rooturi = self._lsp.PathToUri(workspace)
                workspace = self._lsp.PathToUri(workspace)
                workspace = {'uri': workspace, 'name': 'init'}
                capabilities = self._lsp.BuildCapabilities()
                capabilities['workspace']['configuration'] = True
                capabilities['textDocument']['publishDiagnostics']\
                        ['relatedInformation'] = is_enable_diagnosis
                temp = self._lsp.initialize(workspaceFolders=[workspace],
                                            rootUri=rooturi,
                                            capabilities=capabilities)
                # if time out will raise, meanning can not start a job.
                self._lsp.GetResponse(temp['Method'])
                self.is_server_start = 'started'
                threading.Thread(target=self._get_diagnosis,
                                 daemon=True).start()
                threading.Thread(
                    target=self._handle_configuration, daemon=True).start()
                threading.Thread(target=self._handle_log_msg,
                                 daemon=True).start()
                self._lsp.initialized()
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

    def _handle_log_msg(self):
        g_logger.debug("started hanlde logmsg thread.")
        if self._workspace is None or self._workspace == '':
            output_log_dir = self.BASE_DIR + "/gopls.log"
        else:
            output_log_dir = self._workspace + "/gopls.log"
        fileHandler = logging.FileHandler(
            output_log_dir, mode="w", encoding="UTF-8")
        formatter = logging.Formatter(
            '%(asctime)s %(filename)s:%(lineno)d | %(message)s')
        fileHandler.setFormatter(formatter)
        lsp_logger = logging.getLogger('gopls')
        lsp_logger.addHandler(fileHandler)
        lsp_logger.setLevel(logging.DEBUG)
        lsp_logger.debug("started hanlde logmsg thread.")
        while 1:
            try:
                response = self._lsp.GetResponse(
                    'window/logMessage', timeout_=-1)
                response = response['params']
                msg = response['message']
                if self._filter_log_msg(msg):
                    continue
                types = response['type']
                if types == 1:
                    # erro of warning
                    self._build_erro_msg(4, msg)
                elif types == 3:
                    # info, TODO
                    pass
            except:
                g_logger.exception('')

    def _handle_configuration(self):
        g_logger.debug("started _handle_configuration thread.")
        while 1:
            try:
                response = self._lsp.GetResponse('workspace/configuration',
                                                 timeout_=-1)

                config = {
                    'hoverKind': 'NoDocumentation',
                    'completeUnimported': True,
                    'staticcheck': True,
                    'usePlaceholders': True,
                    'deepCompletion': True}
                results = []
                for item in response['params']['items']:
                    results.append(config)
                self._lsp.configuration(response['id'], results=results)
            except:
                g_logger.exception('')

    def _did_open_or_change(self, uri, text, document_id):
        """ will ask diagnostics.
        """
        # {{{
        # LSP requires the edit-version
        if uri not in self._did_open_list:
            return_id = self._lsp.didopen(uri, 'go', text, version=0)
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
                self.return_data = self._lsp.GetResponse(method_, timeout_=50)
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

    def OnBufferEnter(self, version):
        if self._check(version):
            # OnBufferEnter is a notification
            # so we return nothing
            uri_ = self._lsp.PathToUri(version['FilePath'])
            workspace = version['WorkSpace']
            if workspace not in self._workspace_list:
                self._workspace_list.append(workspace)
                add_workspace = [{'uri': self._lsp.PathToUri(workspace), 'name':
                                  workspace}]
                self._lsp.didChangeWorkspaceFolders(
                    add_workspace=add_workspace)
                # current_start_postion = {'line': 0,'character': 0}
                # self._lsp.completion(uri_, current_start_postion)

            line_text = version['AllTextList']
            self._did_open_or_change(uri_, line_text,
                                     version['DocumentVersionID'])
        # every event must return something. 'None' means send nothing to client
        return None

    def OnBufferTextChanged(self, version):
        if not self._check(version):
            return None
        uri_ = self._lsp.PathToUri(version['FilePath'])
        line_text = version['AllTextList']
        self._did_open_or_change(uri_, line_text,
                                 version['DocumentVersionID'])

    def DoCompletion(self, version):
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
            items = []
        else:
            items = _return_data['result']['items']
        results_list = []
        for item in items:
            results_format = {'abbr': '', 'word': '', 'kind': '',
                              'menu': '', 'info': [], 'user_data': ''}
            results_format['abbr'] = item['label']
            results_format['word'] = item['label']
            results_format['kind'] = self._lsp.GetKindNameByNumber(
                item['kind'])
            if 'detail' in item:
                results_format['menu'] = item['detail']
            if 'documentation' in item:
                temp = item['documentation'].split('\n')
                results_format['info'] = temp

            try:
                if item['insertTextFormat'] == 2:
                    if 'newText' in item['textEdit']:
                        temp = item['textEdit']['newText']
                        if '$' in temp or '(' in temp:
                            temp = temp.replace('{\\}', '\{\}')
                            results_format['snippet'] = temp
                            results_format['kind'] += '~'
            except:
                pass
            results_list.append(results_format)
        return_['Lists'] = results_list
        return return_
