import sys
sys.path.append('D:/gvim/vimfiles/myplug/ECY_new/python/server')
import utils.lsp.language_server_protocol as lsps
import os
# init_opts = {'vimruntime':'D:/gvim/vim81','runtimepath':'C:/Users/qwe/vimfiles,D:/gvim/vimfiles/MyPlugins/vim-fugitive,D:/gvim/vimfiles/MyPlugins/vim-plug,D:/gvim/vimfiles/MyPlugins/LeaderF,D:/gvim/vimfiles/MyPlugins/Tabsmanager,D:/gvim/vimfiles/MyPlugins/vim-indent-guides,D:/gvim/vimfiles/MyPlugins/emmet-vim,D:/gvim/vimfiles/MyPlugins/vim-easymotion,D:/gvim/vimfiles/MyPlugins/vim-surround,D:/gvim/vimfiles/MyPlugins/nerdtree,D:/gvim/vimfiles/MyPlugins/popup,D:/gvim/vimfiles/MyPlugins/vim-mark,D:/gvim/vimfiles/MyPlugins/vim-ingo-library,D:/gvim/vimfiles/MyPlugins/vim-startify,D:/gvim/vimfiles/MyPlugins/vim-airline,D:/gvim/vimfiles/MyPlugins/vim-easy-align,D:/gvim/vimfiles/MyPlugins/vim-commentary,D:/gvim/vimfiles/MyPlugins/rainbow,D:/gvim/vimfiles/MyPlugins/winresizer.vim,D:/gvim/vimfiles/MyPlugins/is.vim,D:/gvim/vimfiles/MyPlugins/vim-repeat,D:/gvim/vimfiles/MyPlugins/CompleteParameter.vim,D:/gvim/vimfiles/MyPlugins/vim-bookmarks,D:/gvim/vimfiles/MyPlugins/delimitMate,D:/gvim/vimfiles/MyPlugins/GoSymbol,D:/gvim/vimfiles/MyPlugins/vim-edgemotion,D:/gvim/vimfiles/MyPlugins/ultisnips,D:/gvim/vimfiles/MyPlugins/vim-snippets,D:/gvim/vimfiles/MyPlugins/ctrlp.vim,D:/gvim/vimfiles/MyPlugins/html5.vim,D:/gvim/vimfiles/MyPlugins/vim-autoformat,D:/gvim/vimfiles/MyPlugins/LeaderF-marks,D:/gvim/vimfiles/MyPlugins/targets.vim,D:/gvim/vimfiles,D:/gvim/vim81,D:/gvim/vim81/pack/dist/opt/matchit,D:/gvim/vimfiles/after,D:/gvim/vimfiles/MyPlugins/CompleteParameter.vim/after,D:/gvim/vimfiles/MyPlugins/ultisnips/after,D:/gvim/vimfiles/MyPlugins/html5.vim/after,D:/gvim/vimfiles/MyPlugins/LeaderF-marks/after,C:/Users/qwe/vimfiles/after', 'diagnostic':{'enable':True},'indexes':{'runtimepath':True,'gap':100,'count':3}, 'filetypes':['vim'],'suggest':{'fromVimruntime':True,'fromRuntimepath':False},'iskeyword':'sdf'}


lsp = lsps.LSP()
lsp.Debug()
lsp.StartJob('html-languageserver --stdio')
uri = lsp.PathToUri('C:/Users/qwe/Desktop/socket/htdocs/index.html')
temp = lsp.initialize(initializationOptions=None, rootUri=None)
print(temp['Method'])
# print(lsp.GetResponse(temp['Method']))
lsp_text = "<!DOCTYPE html><html></htm>"
temp = lsp.didopen(uri, 'html', lsp_text, version=0)
print(temp['Method'])
temp = lsp.didchange(uri, lsp_text, version=1)
# position = {'line':0,'character':1}
# temp = lsp.completion(uri,position)
# print(lsp.GetResponse(temp['Method']))
# temp = lsp.completion(uri,position)
# print(lsp.GetResponse(temp['Method']))
