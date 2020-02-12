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
        self._isconnected = False
        self.callback_queue = queue.Queue()
        # threading.Thread(target=self.Loop, daemon=True).start()

    def AddTodo(self, todo):
        self.Send(todo)
        # self.callback_queue.put(todo)

    def _connect_socket(self):
        if self._isconnected:
            g_logger.debug("connect successfully:")
            return
        try:
            self.tcpCliSock = socket()  # noqa
            self.tcpCliSock.connect(self.ADDR)
            self._HMAC_KEY = bytes(str(self._HMAC_KEY), encoding='utf-8')
            self._isconnected = True
        except:  # noqa
            self._isconnected = False
            g_logger.exception("connect failed:")

    def ConnectSocket(self):
        threading.Thread(target=self._connect_socket).start()

    def BuildMsg(self, msg_dict):
        """build a msg and send it to server
        """
        self._id += 1
        # convert to unicode, then calculate the HMAC
        msg_str = str(msg_dict)
        msg_length = len(msg_str)
        msg_bytes = bytes(msg_str, encoding='utf-8')
        # And for compatibility, we must specify 'digestmod'
        HMAC_abstract1 = hmac.new(
            self._HMAC_KEY, msg_bytes, digestmod=hashlib.md5).digest()
        HMAC_abstract1 = b64encode(HMAC_abstract1)
        HMAC_abstract1 = HMAC_abstract1.decode('utf-8')
        send_data = {'Method': 'receive_all_msg', 'Key': HMAC_abstract1,
                     'ID': self._id, 'Msg_length': msg_length, 'Msg': msg_dict}
        send_data = bytes(json.dumps(send_data), encoding='utf-8')
        # there are no '\n' in json's string, so we use that to split the text.
        self.tcpCliSock.sendall(send_data+b'\n')

    def Send(self, msg):
        if not self._isconnected:
            # todo abandom
            return
        self.BuildMsg(msg)

    def Loop(self):
        try:
            while 1:
                todo = self.callback_queue.get()
                if not self._isconnected:
                    # todo abandom
                    continue
                self.BuildMsg(todo)
        except:  # noqa
            pass
        finally:
            if self._isconnected:
                self._isconnected = False
                self.tcpCliSock.close()
