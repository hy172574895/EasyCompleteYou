# Author: Jimmy Huang (1902161621@qq.com)
# License: WTFPL

from base64 import b64encode
from socket import *  # noqa
import hmac
import hashlib
import queue
import json
import threading
import logging

global g_logger
g_logger = logging.getLogger('ECY_client')


class Socket_(object):
    def __init__(self, PORT, HMAC_KEY_str):
        self.ADDR = (gethostname(), PORT)
        self._id = 0
        self._HMAC_KEY = HMAC_KEY_str
        self.is_connected = False
        self.callback_queue = queue.Queue()
        # threading.Thread(target=self.Loop, daemon=True).start()

    def AddTodo(self, todo):
        self.Send(todo)
        # self.callback_queue.put(todo)

    def _connect_socket(self):
        if self.is_connected:
            return
        try:
            self.tcpCliSock = socket()  # noqa
            self.tcpCliSock.connect(self.ADDR)
            self._HMAC_KEY = bytes(str(self._HMAC_KEY), encoding='utf-8')
            self.is_connected = True
            g_logger.debug("connect successfully:")
        except:  # noqa
            self.is_connected = False
            g_logger.exception("connect failed:")

    def ConnectSocket(self):
        threading.Thread(target=self._connect_socket).start()

    def _calculate_key1(self, dicts_str):
        """ return str encoded by 64base.
        """
        msg_bytes = bytes(dicts_str, encoding='utf-8')
        HMAC_abstract1 = hmac.new(
            self._HMAC_KEY, msg_bytes, digestmod=hashlib.md5).digest()
        HMAC_abstract1 = b64encode(HMAC_abstract1)
        HMAC_abstract1 = str(HMAC_abstract1, encoding='utf-8')
        return HMAC_abstract1

    def BuildMsg(self, msg_dict):
        """build a msg and send it to server
        """
        self._id += 1
        msg_str = str(msg_dict)
        msg_length = len(msg_str)
        # key1 = self._calculate_key1(msg_str)
        key1 = ''
        # And for compatibility, we must specify 'digestmod'
        send_data = {'Method': 'receive_all_msg', 'Key': key1,
                     'ID': self._id, 'Msg_length': msg_length, 'Msg': msg_dict}
        send_data = bytes(json.dumps(send_data), encoding='utf-8')
        # there are no '\n' in json's string, so we use that to split the text.
        self.tcpCliSock.sendall(send_data+b'\n')
        g_logger.debug('sended a msg.')

    def Send(self, msg):
        try:
            if not self.is_connected:
                g_logger.debug('msg abandomed.')
                return
            self.BuildMsg(msg)
        except Exception as e:
            g_logger.exception('')

    def Loop(self):
        # legacy code, some python in vim can not use `queue`
        try:
            while 1:
                todo = self.callback_queue.get()
                if not self.is_connected:
                    # todo abandom
                    continue
                self.BuildMsg(todo)
        except:  # noqa
            pass
        finally:
            if self.is_connected:
                self.is_connected = False
                self.tcpCliSock.close()
