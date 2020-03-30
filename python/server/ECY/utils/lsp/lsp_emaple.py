import sys
import os
sys.path.append('D:/gvim/vimfiles/myplug/ECY_new/python/server')
import utils.lsp.language_server_protocol as LSP

test = LSP.LSP()
test.OuputToStd()

test.StartJob("gopls")

# init_opts = {
#     "iskeyword": "@,48-57,_,192-255,-#",
#     "vimruntime": "",
#     "runtimepath": "",
#     "diagnostic": {
#         "enable": True
#     },
#     "indexes": {
#         "runtimepath": True,
#         "gap": 100,
#         "count": 3,
#         "projectRootPatterns": ["strange-root-pattern",
#                                 ".git",
#                                 "autoload",
#                                 "plugin"]
#     },
#     "suggest": {
#         "fromVimruntime": True,
#         "fromRuntimepath": False
#     }
# }
rooturi = test.PathToUri(os.getcwd())
temp = {'uri': rooturi, 'name':'fuck'}
temp = test.initialize(workspaceFolders=[temp], rootUri=rooturi)
test.GetResponse(temp['Method'])
test.initialized()
uri = test.PathToUri('C:/Users/qwe/go/pkg/mod/golang.org/x/tools/gopls@v0.3.2/main.go')
text = 'package main'
test.didopen(uri, 'go', text)
# print(test.GetResponse('textDocument/publishDiagnostics'))
position = {'line': 0, 'character': 0}
temp = test.completion(uri, position)
test.GetResponse(temp['Method'])
