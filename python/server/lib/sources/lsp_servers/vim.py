# Author: Jimmy Huang (1902161621@qq.com)
# License: WTFPL

import utils.interface as scope_
import utils.lsp.language_server_protocol as lsp


class Operate(scope_.Source_interface):
    def __init__(self):
        self._name = 'vim_lsp'
        self._did_open_list = {}
        self._lsp = lsp.LSP()
        self.is_server_start = 0
        self._deamon_queue = None

    def GetInfo(self):
        return {'Name': self._name, 'WhiteList': ['vim'],
                'Regex': r'[\w\#\&\:]',
                'TriggerKey': ['.', '[', '$', '<', '"', "'"]}

    def _erro_handler(self):
        self._start_server()
        if self.is_server_start == 2:
            return True
        return False

    def _start_server(self):
        try:
            if self.is_server_start == 0:
                self._lsp.StartJob('node C:/Users/qwe/AppData/Local/coc/extensions/node_modules/coc-vimlsp/node_modules/vim-language-server/bin --stdio')
                init_opts = {'vimruntime':'D:/gvim/vim81','runtimepath':'C:/Users/qwe/vimfiles,D:/gvim/vimfiles/MyPlugins/vim-fugitive,D:/gvim/vimfiles/MyPlugins/vim-plug,D:/gvim/vimfiles/MyPlugins/LeaderF,D:/gvim/vimfiles/MyPlugins/Tabsmanager,D:/gvim/vimfiles/MyPlugins/vim-indent-guides,D:/gvim/vimfiles/MyPlugins/emmet-vim,D:/gvim/vimfiles/MyPlugins/vim-easymotion,D:/gvim/vimfiles/MyPlugins/vim-surround,D:/gvim/vimfiles/MyPlugins/nerdtree,D:/gvim/vimfiles/MyPlugins/popup,D:/gvim/vimfiles/MyPlugins/vim-mark,D:/gvim/vimfiles/MyPlugins/vim-ingo-library,D:/gvim/vimfiles/MyPlugins/vim-startify,D:/gvim/vimfiles/MyPlugins/vim-airline,D:/gvim/vimfiles/MyPlugins/vim-easy-align,D:/gvim/vimfiles/MyPlugins/vim-commentary,D:/gvim/vimfiles/MyPlugins/rainbow,D:/gvim/vimfiles/MyPlugins/winresizer.vim,D:/gvim/vimfiles/MyPlugins/is.vim,D:/gvim/vimfiles/MyPlugins/vim-repeat,D:/gvim/vimfiles/MyPlugins/CompleteParameter.vim,D:/gvim/vimfiles/MyPlugins/vim-bookmarks,D:/gvim/vimfiles/MyPlugins/delimitMate,D:/gvim/vimfiles/MyPlugins/GoSymbol,D:/gvim/vimfiles/MyPlugins/vim-edgemotion,D:/gvim/vimfiles/MyPlugins/ultisnips,D:/gvim/vimfiles/MyPlugins/vim-snippets,D:/gvim/vimfiles/MyPlugins/ctrlp.vim,D:/gvim/vimfiles/MyPlugins/html5.vim,D:/gvim/vimfiles/MyPlugins/vim-autoformat,D:/gvim/vimfiles/MyPlugins/LeaderF-marks,D:/gvim/vimfiles/MyPlugins/targets.vim,D:/gvim/vimfiles,D:/gvim/vim81,D:/gvim/vim81/pack/dist/opt/matchit,D:/gvim/vimfiles/after,D:/gvim/vimfiles/MyPlugins/CompleteParameter.vim/after,D:/gvim/vimfiles/MyPlugins/ultisnips/after,D:/gvim/vimfiles/MyPlugins/html5.vim/after,D:/gvim/vimfiles/MyPlugins/LeaderF-marks/after,C:/Users/qwe/vimfiles/after', 'diagnostic':{'enable':True},'indexes':{'runtimepath':True,'gap':100,'count':3}, 'filetypes':['vim'],'suggest':{'fromVimruntime':True,'fromRuntimepath':True}}
                temp = self._lsp.initialize(
                    initializationOptions=init_opts)
                self._lsp.GetResponse(temp['Method'])
                self.is_server_start = 1
        except: # noqa
            self.is_server_start = 2

    def _did_open_or_change(self, uri, text):
        # {{{
        # LSP require the edit-version
        if uri not in self._did_open_list:
            return_id = self._lsp.didopen(uri, 'viml', text, version=0)
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
                self._log.exception("a timeout queue.")
                return None
        return self.return_data
        # }}}

    def OnBufferEnter(self, version):
        self._deamon_queue = version['DeamonQueue']
        if not self._erro_handler():
            uri_ = self._lsp.PathToUri(version['FileType'])
            line_text = version['AllTextList']
            self._did_open_or_change(uri_, line_text)
        # return self._erro_handler()
        return None

    def OnInstall(self, version):
        pass

    def DoCompletion(self, version):
        return_ = {'ID': version['VersionID'], 'Server_name': self._name}
        uri_ = self._lsp.PathToUri(version['FileType'])
        line_text = version['AllTextList']
        current_start_postion = \
            {'line': version['StartPosition']['Line'],
             'character': version['StartPosition']['Colum']}
        self._did_open_or_change(uri_, line_text)
        temp = self._lsp.completion(uri_, current_start_postion)

        # we can set this raising a erro when it is timeout.
        _return_data = self._waitting_for_response(temp['Method'], temp['ID'])

        try:
            items_list = _return_data['result']['items']
        except:
            items_list = []

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
                                  'menu': '', 'info': '', 'user_data':''}
                results_format['abbr'] = item['label']
                results_format['word'] = item['label']
                results_format['kind'] = self._lsp.GetKindNameByNumber(item['kind'])
                results_list.append(results_format)
        return_['Lists'] = results_list
        return return_
