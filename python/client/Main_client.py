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
        self.event_obj = {'genernal': genernal.GenernalEvent('genernal')}

    def GetCurrentSource(self):
        using_source = vim_lib.CallEval('ECY_main#GetCurrentUsingSourceName()')
        # if using_source is '':
        #     using_source = 'nothing'
        return using_source

    def Integration(self):
        todo = self._basic()
        todo['Event'] = 'integration'
        todo['Integration_event'] = vim_lib.GetVariableValue(
            'g:ECY_do_something_event')
        if todo['Integration_event'] == 'filter_search_items':
            todo['KeyWords'] = vim_lib.\
                    GetVariableValue('g:ecy_fileter_search_items_keyword')
        return todo

        # try:
        #     vim_lib.CallEval('UltiSnips#SnippetsInCurrentScope( 1 )')
        #     opts_temp['Ultisnips_snippets'] = vim_lib.\
        #         GetVariableValue('g:current_ulti_dict_info')
        # except: # noqa
        #     pass

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

    def _add(self, method):
        version_id = self.GetVersionID_change()
        threading.Thread(target=self._go(method, version_id)).start()

    def _go(self, method, version_id):
        try:
            self._lock.acquire()
            # do
            source_name = self.GetCurrentSource()
            if source_name in self.event_obj.keys():
                method = getattr(self.event_obj[source_name], method, None)
            else:
                self.event_obj['genernal'].ChangeSourceName(source_name)
                method = getattr(self.event_obj['genernal'], method, None)
            if self.GetVersionID_NotChange() != version_id:
                # we filter some usless requests at here
                return
            todo = method()
            todo['VersionID'] = version_id
            if self.isdebug:
                self._debug_server.AddTodo(todo)
            self.socket_connection.AddTodo(todo)
        except Exception as e:
            raise e
        finally:
            self._lock.release()

    def Exe(self, do):
        try:
            self._add(do)
        except Exception as e:
            raise
