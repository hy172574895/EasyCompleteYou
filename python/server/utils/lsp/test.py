import sys
sys.path.append('D:/gvim/vimfiles/myplug/python_version/python')
import language_server_protocol
import os
lsp = language_server_protocol.LSP()
version={'all_text_list': ['let b:did_indent = 1'], 'current_line_context': '  ', 'version_id': 18, 'current_colum': 2, 'file_path': 'D:/gvim/vimfiles/myplug/python_version/autoload/test.vim', 'line_nr': 5}
lsp.StartJob('node C:/Users/qwe/AppData/Local/coc/extensions/node_modules/coc-vimlsp/node_modules/vim-language-server/bin --stdio')
uri=lsp.PathToUri(version['file_path'])
init_opts = {'vimruntime':'D:/gvim/vim81','runtimepath':'C:/Users/qwe/vimfiles,D:/gvim/vimfiles/MyPlugins/vim-fugitive,D:/gvim/vimfiles/MyPlugins/vim-plug,D:/gvim/vimfiles/MyPlugins/LeaderF,D:/gvim/vimfiles/MyPlugins/Tabsmanager,D:/gvim/vimfiles/MyPlugins/vim-indent-guides,D:/gvim/vimfiles/MyPlugins/emmet-vim,D:/gvim/vimfiles/MyPlugins/vim-easymotion,D:/gvim/vimfiles/MyPlugins/vim-surround,D:/gvim/vimfiles/MyPlugins/nerdtree,D:/gvim/vimfiles/MyPlugins/popup,D:/gvim/vimfiles/MyPlugins/vim-mark,D:/gvim/vimfiles/MyPlugins/vim-ingo-library,D:/gvim/vimfiles/MyPlugins/vim-startify,D:/gvim/vimfiles/MyPlugins/vim-airline,D:/gvim/vimfiles/MyPlugins/vim-easy-align,D:/gvim/vimfiles/MyPlugins/vim-commentary,D:/gvim/vimfiles/MyPlugins/rainbow,D:/gvim/vimfiles/MyPlugins/winresizer.vim,D:/gvim/vimfiles/MyPlugins/is.vim,D:/gvim/vimfiles/MyPlugins/vim-repeat,D:/gvim/vimfiles/MyPlugins/CompleteParameter.vim,D:/gvim/vimfiles/MyPlugins/vim-bookmarks,D:/gvim/vimfiles/MyPlugins/delimitMate,D:/gvim/vimfiles/MyPlugins/GoSymbol,D:/gvim/vimfiles/MyPlugins/vim-edgemotion,D:/gvim/vimfiles/MyPlugins/ultisnips,D:/gvim/vimfiles/MyPlugins/vim-snippets,D:/gvim/vimfiles/MyPlugins/ctrlp.vim,D:/gvim/vimfiles/MyPlugins/html5.vim,D:/gvim/vimfiles/MyPlugins/vim-autoformat,D:/gvim/vimfiles/MyPlugins/LeaderF-marks,D:/gvim/vimfiles/MyPlugins/targets.vim,D:/gvim/vimfiles,D:/gvim/vim81,D:/gvim/vim81/pack/dist/opt/matchit,D:/gvim/vimfiles/after,D:/gvim/vimfiles/MyPlugins/CompleteParameter.vim/after,D:/gvim/vimfiles/MyPlugins/ultisnips/after,D:/gvim/vimfiles/MyPlugins/html5.vim/after,D:/gvim/vimfiles/MyPlugins/LeaderF-marks/after,C:/Users/qwe/vimfiles/after', 'diagnostic':{'enable':True},'indexes':{'runtimepath':True,'gap':100,'count':3}, 'filetypes':['vim'],'suggest':{'fromVimruntime':True,'fromRuntimepath':False},'iskeyword':'sdf'}


temp=lsp.initialize(rootUri=uri,initializationOptions=init_opts)
print(lsp.GetResponse(temp['Method']))
lsp_text = str.join('\n', version['all_text_list'])
temp = lsp.didopen(uri,'vim',lsp_text,version=0)
temp = lsp.didchange(uri, lsp_text,version=1)
position = {'line':0,'character':1}
temp = lsp.completion(uri,position)
print(lsp.GetResponse(temp['Method']))
temp = lsp.completion(uri,position)
print(lsp.GetResponse(temp['Method']))
