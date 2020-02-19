# Author: Jimmy Huang (1902161621@qq.com)
# License: WTFPL

import utils.lsp.language_server_protocol as lsp
import utils.interface as scope_
import logging
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

    def GetInfo(self):
        return {'Name': self._name, 'WhiteList': ['go'],
                'Regex': r'[\w]',
                'TriggerKey': ['.']}

    def _check(self, version):
        self._deamon_queue = version['DeamonQueue']
        # self._start_server(version['StartingCMD'],
        #         version['Vimruntime'], version['Runtimepath'])
        self._start_server(workspace=version['WorkSpace'],
                           starting_cmd=version['StartingCMD'])
        if self.is_server_start == 'started':
            return True
        return False

    def _output_queue(self, msg):
        if self._deamon_queue is not None:
            self._deamon_queue.put(msg)

    def _build_erro_msg(self, code, msg):
        """and and send it
        """
        msg = msg.split('\n')
        g_logger.debug(msg)
        temp = {'ID': -1, 'Results': 'ok', 'ErroCode': code,
                'Event': 'erro_code',
                'Server_name': self._name,
                'Description': msg}
        self._output_queue(temp)

    def _start_server(self, starting_cmd="", workspace=""):
        try:
            if self.is_server_start == 'not_started':
                if starting_cmd == "":
                    starting_cmd = 'gopls'
                self._lsp.StartJob(starting_cmd)
                # init_opts = {'gocodeCompletionEnabled':True}
                # g_logger.debug(init_opts)
                rooturi = self._lsp.PathToUri(workspace)
                workspace = self._lsp.PathToUri(workspace)
                workspace = {'uri': workspace, 'name': 'init'}
                capabilities = self._lsp.BuildCapabilities()
                capabilities['workspace']['configuration'] = True
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

    def _handle_log_msg(self):
        g_logger.debug("started hanlde logmsg thread.")
        while 1:
            try:
                response = self._lsp.GetResponse(
                    'window/logMessage', timeout_=-1)
                response = response['params']
                types = response['type']
                msg = response['message']
                if types == 1 or types == 2:
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

    def _did_open_or_change(self, uri, text, DocumentVersionID,
                            is_return_diagnoiss=True):
        # {{{
        # LSP require the edit-version
        if uri not in self._did_open_list:
            return_id = self._lsp.didopen(uri, 'go', text, version=0)
            self._did_open_list[uri] = {}
            self._did_open_list[uri]['change_version'] = 0
        else:
            self._did_open_list[uri]['change_version'] += 1
            return_id = self._lsp.didchange(
                uri, text, version=self._did_open_list[uri]['change_version'])
        if is_return_diagnoiss:
            self.DocumentVersionID = DocumentVersionID
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
        while 1:
            temp = self._lsp.GetResponse('textDocument/publishDiagnostics',
                                         timeout_=-1)

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

            line_text = version['AllTextList']
            self._did_open_or_change(uri_, line_text,
                                     version['DocumentVersionID'])
        # every event must return something. 'None' means send nothing to client
        return None

    def DoCompletion(self, version):
        if not self._check(version):
            return None
        return_ = {'ID': version['VersionID'], 'Server_name': self._name}
        uri_ = self._lsp.PathToUri(version['FilePath'])
        line_text = version['AllTextList']
        current_start_postion = \
            {'line': version['StartPosition']['Line'],
             'character': version['StartPosition']['Colum']}
        self._did_open_or_change(uri_, line_text,
                                 version['DocumentVersionID'], version['ReturnDiagnosis'])
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
