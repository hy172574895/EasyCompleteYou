# Author: Jimmy Huang (1902161621@qq.com)
# License: WTFPL

import random
import threading
import logging
import sys
import os
import importlib
from socket import *  # noqa

# local lib
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
sys.path.append(BASE_DIR)
from lib import socket_
from lib import vim_or_neovim_support as vim_lib
import lib.event.genernal as genernal

g_is_debug = vim_lib.GetVariableValue('g:ECY_debug')
if g_is_debug:
    fileHandler = logging.FileHandler(
        BASE_DIR + "/ECY_client.log", mode="w", encoding="UTF-8")
    formatter = logging.Formatter(
        '%(asctime)s %(filename)s:%(lineno)d | %(message)s')
    fileHandler.setFormatter(formatter)
global g_logger
g_logger = logging.getLogger('ECY_client')
if g_is_debug:
    g_logger.addHandler(fileHandler)
    g_logger.setLevel(logging.DEBUG)


class _do(object):
    def __init__(self):
        self.UpdateClientModule()
        self.event_obj = {'genernal': genernal.GenernalEvent('genernal')}

    def UpdateClientModule(self):
        self.available_engine_name_dict = vim_lib.GetVariableValue(
                'g:ECY_engine_client_info')

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
        self._completion_id = 0
        self._document_id = 0
        self._HMAC_KEY = -1
        self._port = -1
        self.isdebug = False
        self.is_using_stdio = False

    def UseStdio(self):
        self.is_using_stdio = True

    def Log(self):
        g_logger.debug(
            "From Vim: " + vim_lib.GetVariableValue('g:ECY_log_msg'))
        return 'ok'

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
        self.is_using_stdio = False
        return 'ok'
# {{{

    def GetCompletionVersionID_Changing(self):
        """ return a oder ID. this func will add version id automatically
        """
        self._completion_id += 1
        return self._completion_id

    def GetCompletionVersionID_NotChanging(self):
        """ return a oder ID. this func just get the ID but won't change ID
        """
        return self._completion_id

    def GetDocumentVersionID_Changing(self):
        """ return a oder ID. this func will add version id automatically
        """
        self._document_id += 1
        return self._document_id

    def GetDocumentVersionID_NotChanging(self):
        """ return a oder ID. this func just get the ID but won't change ID
        """
        return self._document_id

    def GetUnusedLocalhostPort(self):
        if self._port == -1:
            sock = socket()  # noqa
            # This tells the OS to give us any free port in the
            # range [1024 - 65535]
            sock.bind(('', 0))
            port = sock.getsockname()[1]
            self._port = port
            sock.close()
        return self._port

    def GetCurrentBufferPath(self):
        return vim_lib.GetCurrentBufferFilePath()

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
        version_id = self.GetCompletionVersionID_NotChanging()
        document_version_id = self.GetDocumentVersionID_NotChanging()
        self._go(event, version_id, document_version_id)

    def _import_client_event(self, server_name, client_lib, event):
        try:
            module_temp = importlib.import_module(client_lib)
            obj_temp = module_temp.Operate(server_name)
            self.event_obj[server_name] = obj_temp
            g_logger.debug("imported a Client lib: " + server_name)
            return getattr(obj_temp, event, None)
        except:
            g_logger.exception("Failed to load Client's lib")
            return None

    def _get(self, event):
        # do
        engine_name = self.GetCurrentSource()
        if engine_name not in self.available_engine_name_dict.keys():
            self.UpdateClientModule()
        method = None
        if engine_name in self.available_engine_name_dict.keys():
            if engine_name not in self.event_obj.keys() \
                    and self.available_engine_name_dict[engine_name]['lib'] != '':
                client_lib = self.available_engine_name_dict[engine_name]['lib']
                method = self._import_client_event(engine_name, client_lib, event)
            else:
                method = getattr(self.event_obj[engine_name], event, None)

        if method is None:
            self.event_obj['genernal'].ChangeSourceName(engine_name)
            method = getattr(self.event_obj['genernal'], event, None)
        # return a dict
        return method()

    def _go(self, event, version_id, document_id):
        try:
            # self._lock.acquire()
            todo = self._get(event)
            if todo is None:
                return
            todo['VersionID'] = version_id
            todo['DocumentVersionID'] = document_id
            if self.isdebug:
                self._debug_server.AddTodo(todo)
            self.socket_connection.AddTodo(todo)
        except:
            g_logger.exception("Failed to trigger a Client event.")

    def Exe(self, do):
        self._add(do)
