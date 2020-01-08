import re

import utils.interface as scope_
import utils.lsp.language_server_protocol as lsp


class Operate(scope_.Source_interface):
    def __init__(self):
        self._name = 'html_lsp'
        self._did_open_list = {}
        self._lsp = lsp.LSP()
        self.is_server_start = 0
        self._deamon_queue = None

    def GetInfo(self):
        return {'Name': self._name, 'WhiteList': ['html', 'xhtml'],
                'Regex': r'[\w-]',
                'TriggerKey': ['.', ':', '"', '\'', '<', '=', '/']}

    def _erro_handler(self):
        self._start_server()
        if self.is_server_start == 2:
            return True
        return False

    def _start_server(self):
        try:
            if self.is_server_start == 0:
                self._lsp.StartJob('html-languageserver --stdio')

                # you can change the capabilities of init request like this:

                # capabilities_dict = self._lsp.BuildCapabilities()
                # capabilities_dict['completion']['dynamicRegistration'] = True
                init_msg = self._lsp.initialize(
                    initializationOptions=None, rootUri=None)
                self._lsp.GetResponse(init_msg['Method'])
                self.is_server_start = 1
        except: # noqa
            self.is_server_start = 2

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
        self._deamon_queue = version['DeamonQueue']
        if not self._erro_handler():
            uri_ = self._lsp.PathToUri(version['FilePath'])
            line_text = version['AllTextList']
            self._did_open_or_change(uri_, line_text)
        # return self._erro_handler()
        return None

    def _return_label(self, all_text_list):
        items_list = list(set(re.findall(r'[\w\-]+', all_text_list )))
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
                    results_format['abbr'] = trigger + ' ~'
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
                        results_format['abbr'] += ' ~'
                        results_format['kind'] = '[Snippet]'
                        if 'newText' in item['textEdit']:
                            temp = item['textEdit']['newText']
                            results_format['snippet'] = temp
                except: # noqa
                    pass
                results_list.append(results_format)
        return_['Lists'] = results_list
        return return_
