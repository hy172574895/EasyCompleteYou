# Author: Jimmy Huang (1902161621@qq.com)
# License: WTFPL

import json
from urllib.parse import urljoin
from urllib.request import pathname2url
import threading
import queue

# local lib
import utils.lsp.stand_IO_connection as conec


class LSP(conec.Operate):
    def __init__(self):
        self._id = 0
        self._lock = threading.Lock()
        self.server_id = -1
        self._queue_dict = {}
        self._waitting_response = {}
        super().__init__()
        threading.Thread(target=self._classify_response, daemon=True).start()
        self._debug = False

    def Debug(self):
        self._debug = not self._debug

    def _classify_response(self):
        while 1:
            todo = self.GetTodo()
            todo = json.loads(todo['data'])
            if self._debug:
                print(todo)
            if 'id' not in todo.keys():
                # a notification send from server
                self._add_queue(todo['method'], todo)
            else:
                if todo['id'] in self._waitting_response or\
                        'method' not in todo.keys():
                    # a response
                    method_name = self._pop_waitting(todo['id'])
                    self._add_queue(method_name, todo)
                else:
                    # a request that send from the server
                    self._add_queue(todo['method'], todo)

    def GetServerStatus_(self):
        return self.GetServerStatus(self.server_id)

    def GetResponse(self, _method_name, timeout_=5):
        if _method_name not in self._queue_dict:
            # new
            self._queue_dict[_method_name] = queue.Queue(maxsize=10)
        if timeout_ == -1:
            return self._queue_dict[_method_name].get()
        else:
            return self._queue_dict[_method_name].get(timeout=timeout_)

    def _add_queue(self, _method_name, _todo):
        if _method_name is None:
            return None
        if _method_name in self._queue_dict:
            obj_ = self._queue_dict[_method_name]
        else:
            # obj_ = queue.Queue()
            # self._queue_dict[_method_name] = obj_

            # user should call GetResponse() once to create a queue
            # if don't, this msg will be abandomed.
            return None
        obj_.put(_todo)
        return obj_

    def _add_waitting(self, _id, _method_name):
        """ waiting lists
        """
        try:
            self._lock.acquire()
            self._waitting_response[_id] = _method_name
        finally:
            self._lock.release()

    def _pop_waitting(self, _id):
        """get the response of method name by id to classify 
        """
        try:
            self._lock.acquire()
            if _id in self._waitting_response:
                method_ = self._waitting_response[_id]
                self._waitting_response.pop(_id)
                return method_
            else:
                return None
        finally:
            self._lock.release()

    def _build_request(self, params, method, isNotification=False):
        """build request format and send it to server as request or notification.
        """
        if self.server_id <= 0:
            # raise an erro:
            # return 'E002: you have to send a initialize request first.'
            return None
        context = {'jsonrpc': '2.0',
                   'method':  method,
                   'params':  params}
        # we have to increase the ID all the time for distinguished by ECY
        self._id += 1
        if not isNotification:
            # id_text       = "ECY_"+str(self._id)
            context['id'] = self._id
            self._add_waitting(self._id, method)
        context = json.dumps(context)
        context_lenght = len(context)
        message = (
            "Content-Length: {}\r\n\r\n"
            "{}".format(context_lenght, context)
        )
        self.SendData(self.server_id, message.encode(encoding="utf-8"))
        return {'ID': self._id, 'Method': method}

    def BuildCapabilities(self):
        WorkspaceClientCapabilities = {
                "applyEdit": True,
                "workspaceEdit": {
                    "documentChanges": True,
                    "resourceOperations": ["Create", "Rename", "Delete"],
                    "failureHandling": ["Abort"]
                    },
                "didChangeConfiguration": {
                    "dynamicRegistration": False
                    },
                "didChangeWatchedFiles": False,
                "symbol": {
                    "dynamicRegistration": True,
                    "symbolKind": {"valueSet": []}
                    },
                "executeCommand": {
                    "dynamicRegistration": False
                    },
                "workspaceFolders": False,
                "configuration": False
                }  # noqa
        TextDocumentClientCapabilities = {
                "synchronization": {
                    "dynamicRegistration": False,
                    "willSave": False,
                    "willSaveWaitUntil": False,
                    "didSave": True
                    },
                "completion": {
                    "dynamicRegistration": True,
                    "completionItem": {
                        "snippetSupport": True,
                        "commitCharactersSupport": False,
                        "documentationFormat": [],
                        "deprecatedSupport": False,
                        "preselectSupport": False
                        },
                    "completionItemKind": {"valueSet": []},
                    "contextSupport": True
                    },
                "hover": {
                    "dynamicRegistration": True,
                    "contentFormat": []
                    },
                "signatrueHelp": {
                    "dynamicRegistration": True,
                    "signatrueInformation": {
                        "documentationFormat": [],
                        "parameterInformation": {"labelOffsetSupport": True}
                        }
                    },
                "references": {
                    "dynamicRegistration": True
                    },
                "documentHighlight": {
                    "dynamicRegistration": True
                    },
                "documentSymbol": {
                    "dynamicRegistration": True,
                    "symbolKind": {"valueSet": []},
                    "hierarchicalDocumentSymbolSupport": False
                    },
                "formatting": {
                    "dynamicRegistration": False
                    },
                "rangeFormatting": {
                    "dynamicRegistration": True
                    },
                "onTypeFormatting": {
                    "dynamicRegistration": False
                    },
                "declaration": {
                        "dynamicRegistration": True,
                        "linkSupport": True
                        },
                "definition": {
                        "dynamicRegistration": True,
                        "linkSupport": True
                        },
                "typeDefinition": {
                        "dynamicRegistration": True,
                        "linkSupport": True
                        },
                "implementation": {
                        "dynamicRegistration": False,
                        "linkSupport": False
                        },
                "codeAction": {
                        "dynamicRegistration": False,
                        "codeActionLiteralSupport": {
                            "codeActionKind": {
                                "valueSet": []
                                }
                            }
                        },
                "codeLens": {
                        "dynamicRegistration": False
                        },
                "documentLink": {
                        "dynamicRegistration": True
                        },
                "colorProvider": {
                        "dynamicRegistration": False
                        },
                "rename": {
                        "dynamicRegistration": True,
                        "prepareSupport": True
                        },
                "publishDiagnostics": {
                        "relatedInformation": True
                        },
                "foldingRange": {
                        "dynamicRegistration": False,
                        "rangeLimit": False,
                        "lineFoldingOnly": False
                        }
                }  # noqa
        Capabilities = {'workspace': WorkspaceClientCapabilities,
                        'textDocument': TextDocumentClientCapabilities,
                        'experimental': None}
        return Capabilities

    def initialize(self, processId=None, rootUri=None,
                   initializationOptions=None,
                   trace='off',
                   workspaceFolders=None,
                   capabilities=None):

        if self.server_count == 0:
            return 'E001:you have to start a server first.'
        else:
            self.server_id = self.server_count
        if capabilities is None:
            capabilities = self.BuildCapabilities()
        params = {'processId':           processId,
                  'rootUri':               rootUri,
                  'initializationOptions': initializationOptions,
                  'workspaceFolders':      workspaceFolders,
                  'capabilities':          capabilities,
                  'trace':                 trace}
        return self._build_request(params, 'initialize')

    def didopen(self, uri, languageId, text, version=None):
        textDocument = {'uri': uri, 'languageId': languageId,
                        'text': text, 'version': version}
        params = {'textDocument': textDocument}
        return self._build_request(params, 'textDocument/didOpen', isNotification=True)

    def didchange(self, uri, text, version=None, range_=None, rangLength=None):
        textDocument = {'version': version, 'uri': uri}
        params = {'textDocument': textDocument}
        if range_ is not None:
            TextDocumentContentChangeEvent = {'range': range_,
                                              'rangLength': rangLength,
                                              'text': text}
        else:
            TextDocumentContentChangeEvent = {'text': text}
        params = {'textDocument': textDocument,
                  'contentChanges': [TextDocumentContentChangeEvent]}
        return self._build_request(params, 'textDocument/didChange', isNotification=True)

    def completion(self, uri, position,
                   triggerKind=1,
                   triggerCharacter=None):
        TextDocumentIdentifier = {'uri': uri}

        CompletionContext = {'triggerKind': triggerKind,
                             'triggerCharacter':         triggerCharacter}

        params = {'context':    CompletionContext,
                  'textDocument': TextDocumentIdentifier,
                  'position':     position}
        return self._build_request(params, 'textDocument/completion')

    def PathToUri(self, file_path):
        return urljoin('file:', pathname2url(file_path))

    def GetDiagnosticSeverity(self, kindNr):
        # {{{
        if KindNr == 1:
            return 'Error'
        if KindNr == 2:
            return 'Warning'
        if KindNr == 3:
            return 'Information'
        if KindNr == 4:
            return 'Hint'
        # }}}

    def GetMessageType(self, kindNr):
        # {{{
        if KindNr == 1:
            return 'Error'
        if KindNr == 2:
            return 'Warning'
        if KindNr == 3:
            return 'Info'
        if KindNr == 4:
            return 'Log'
# }}}

    def GetKindNameByNumber(self, KindNr):
        # {{{
        if KindNr == 1:
            return 'Text'
        if KindNr == 2:
            return 'Method'
        if KindNr == 3:
            return 'Function'
        if KindNr == 4:
            return 'Constructor'
        if KindNr == 5:
            return 'Field'
        if KindNr == 6:
            return 'Variable'
        if KindNr == 7:
            return 'Class'
        if KindNr == 8:
            return 'Interface'
        if KindNr == 9:
            return 'Module'
        if KindNr == 10:
            return 'Property'
        if KindNr == 11:
            return 'Unit'
        if KindNr == 12:
            return 'Value'
        if KindNr == 13:
            return 'Enum'
        if KindNr == 14:
            return 'Keyword'
        if KindNr == 15:
            return 'Snippet'
        if KindNr == 16:
            return 'Color'
        if KindNr == 17:
            return 'File'
        if KindNr == 18:
            return 'Reference'
        if KindNr == 19:
            return 'Folder'
        if KindNr == 20:
            return 'EnumMember'
        if KindNr == 21:
            return 'Constant'
        if KindNr == 22:
            return 'Struct'
        if KindNr == 23:
            return 'Event'
        if KindNr == 24:
            return 'Operator'
        if KindNr == 25:
            return 'TypeParameter'
        return 'Unkonw'  # }}}
