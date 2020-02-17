# Author: Jimmy Huang (1902161621@qq.com)
# License: WTFPL

import logging
import threading
global g_logger
g_logger = logging.getLogger('ECY_server')

import utils.interface as scope_
import utils.lsp.language_server_protocol as lsp


class Operate(scope_.Source_interface):
    def __init__(self):
        """ notes: 
        """
        self._name = 'go_langserver'
        self._did_open_list = {}
        self._lsp = lsp.LSP()
        self.is_server_start = 'not_started'
        self.DocumentVersionID = -1
        self._deamon_queue = None

    def GetInfo(self):
        return {'Name': self._name, 'WhiteList': ['go'],
                'Regex': r'[\w]',
                'TriggerKey': ['.']}

    def _check(self, version):
        self._deamon_queue = version['DeamonQueue']
        # self._start_server(version['StartingCMD'],
        #         version['Vimruntime'], version['Runtimepath'])
        self._start_server(workspace=version['WorkSpace'])
        if self.is_server_start == 'started':
            return True
        return False

    def _build_erro_msg(self, code, msg):
        """and and send it
        """
        temp = {'ID': -1, 'Results': 'ok', 'ErroCode': code,
                'Event': 'erro_code',
                'Description':msg}
        if self._deamon_queue is not None:
            self._deamon_queue.put(temp)
        return temp

    def _start_server(self, starting_cmd="", workspace=""):
        try:
            if self.is_server_start == 'not_started':
                if starting_cmd == "":
                    starting_cmd = 'gopls'
                self._lsp.StartJob(starting_cmd)
                # init_opts = {'gocodeCompletionEnabled':True}
                # g_logger.debug(init_opts)
                rooturi = self._lsp.PathToUri(workspace)
                workspace = {'uri': workspace, 'name':'init'}
                temp = self._lsp.initialize(workspaceFolders=[workspace], rootUri=rooturi)
                # if time out will raise, meanning can not start a job.
                self._lsp.GetResponse(temp['Method'])
                self.is_server_start = 'started'
                threading.Thread(target=self._get_diagnosis, daemon=True).start()
                self._lsp.initialized()
        except: # noqa
            self.is_server_start = 'started_error'
            g_logger.exception(': can not start Sever.' )
            self._build_erro_msg(2,
                    'Failed to start LSP server. Check Log file of server to get more details.')

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
            except: # noqa
                g_logger.exception('')
                return None
        return self.return_data
        # }}}

    def _get_diagnosis(self):
        while 1:
            g_logger.debug("started diagnosis")
            temp = self._lsp.GetResponse('textDocument/publishDiagnostics',
                    timeout_=-1)
            g_logger.debug(temp)

    def OnBufferEnter(self, version):
        if self._check(version):
            # OnBufferEnter is a notification
            # so we return nothing
            uri_ = self._lsp.PathToUri(version['FilePath'])
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
        g_logger.debug(_return_data)
        if _return_data is None:
            items = []
        else:
            items = _return_data['result']['items']
        results_list = []
        for item in items:
            results_format = {'abbr': '', 'word': '', 'kind': '',
                              'menu': '', 'info': [], 'user_data':''}
            results_format['abbr'] = item['label']
            results_format['word'] = item['label']
            results_format['kind'] = self._lsp.GetKindNameByNumber(item['kind'])
            if 'detail' in item:
                temp = item['detail']
            # try:
            #     if item['insertTextFormat'] == 2:
            #         results_format['kind'] += '~'
            #         if 'newText' in item['textEdit']:
            #             temp = item['textEdit']['newText']
            #             temp = temp.replace('{\\}', '')
            #             results_format['snippet'] = temp
            # except:
            #     pass
            results_list.append(results_format)
        return_['Lists'] = results_list
        return return_
