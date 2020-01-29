from socket import * # noqa
import random
import threading
import json

# local lib
import lib.vim_or_neovim_support as vim_lib
import lib.socket_ as socket_
from lib.event import *


class _do(object):
    def __init__(self):
        import lib.event.genernal as genernal
        import lib.event.html_lsp as html_lsp
        import lib.event.snippets as snippets
        self.event_obj = {'genernal': genernal.GenernalEvent('genernal'),
                          'html_lsp': html_lsp.HtmlLSPEvent('html_lsp'),
                          'snippets': snippets.SnippetsEvent('snippets')}

    def GetCurrentSource(self):
        using_source = vim_lib.CallEval('ECY_main#GetCurrentUsingSourceName()')
        # if using_source is '':
        #     using_source = 'nothing'
        return using_source


class ECY_Client(_do):
    """interface
    """

    def __init__(self):
        _do.__init__(self)
        self._lock = threading.Lock()
        self._id = 0 
        self._HMAC_KEY = -1
        self._port = -1
        self.isdebug = False
        self.is_using_stdio = False

    def UseStdio(self):
        self.is_using_stdio = True

    def StartDebugServer(self):
        self._debug_server = socket_.Socket_(1234, str(1234))
        self._debug_server.ConnectSocket()
        self.isdebug = True
        return 'ok'

    def ConnectSocketServer(self):
        self.CreateHMACKey()
        self.GetUnusedLocalhostPort()
        self.socket_connection = socket_.Socket_(
            self.GetUnusedLocalhostPort(), str(self.CreateHMACKey()))
        self.socket_connection.ConnectSocket()
        self.is_using_stdio = False
        return 'ok'
# {{{

    def GetVersionID_change(self):
        """ return a oder ID. this func will add version id automatically
        """
        self._id += 1
        return self._id

    def GetVersionID_NotChange(self):
        """ return a oder ID. this func just get the ID but won't change ID
        """
        return self._id

    def GetUnusedLocalhostPort(self):
        if self._port == -1:
            sock = socket() # noqa
            # This tells the OS to give us any free port in the
            # range [1024 - 65535]
            sock.bind(('', 0))
            port = sock.getsockname()[1]
            self._port = port
            sock.close()
        return self._port

    def CreateHMACKey(self):
        """new a new key if it's not exist.
        """
        if self._HMAC_KEY == -1:
            self._HMAC_KEY = ''.join(
                [chr(random.randint(48, 122)) for i in range(20)])
            self._HMAC_KEY = bytes(self._HMAC_KEY, encoding='utf-8')
        return self._HMAC_KEY.decode('utf-8')
# }}}

    def _add(self, event):
        version_id = self.GetVersionID_change()
        self._go(event, version_id)

    def _get(self, event):
        # do
        source_name = self.GetCurrentSource()
        if source_name in self.event_obj.keys():
            method = getattr(self.event_obj[source_name], event, None)
        else:
            self.event_obj['genernal'].ChangeSourceName(source_name)
            method = getattr(self.event_obj['genernal'], event, None)
        # return a dict
        return method()

    def _go(self, event, version_id):
        try:
            # self._lock.acquire()
            todo = self._get(event)
            todo['VersionID'] = version_id
            if self.isdebug:
                self._debug_server.AddTodo(todo)
            self.socket_connection.AddTodo(todo)
        except Exception as e:
            raise e

    def Exe(self, do):
        self._add(do)
