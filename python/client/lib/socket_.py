from base64 import b64encode
from socket import * # noqa
import hmac
import queue
import json
import threading


class Socket_(object):
    def __init__(self, PORT, HMAC_KEY_str):
        HOST = '127.0.0.1'  # or 'localhost'
        self.ADDR = (HOST, PORT)
        self._id = 0
        self._HMAC_KEY = HMAC_KEY_str
        self.thread = threading.Thread(target=self.Loop)
        self.thread.daemon = True
        self._isconnected = False
        self.callback_queue = queue.Queue()
        self.thread.start()

    def AddTodo(self, todo):
        self.callback_queue.put(todo)

    def _connect_socket(self):
        try:
            if self._isconnected:
                return
            self.tcpCliSock = socket(AF_INET, SOCK_STREAM) # noqa
            self.tcpCliSock.connect(self.ADDR)
            self._isconnected = True
            self._HMAC_KEY = bytes(str(self._HMAC_KEY), encoding='utf-8')
        except: # noqa
            self._isconnected = False
            raise

    def ConnectSocket(self):
        threading.Thread(target=self._connect_socket).start()

    def BuildMsg(self, msg_dict):
        """build a msg and send it to server
        """
        if not self._isconnected:
            # todo abandom
            return
        self._id += 1
        # convert to unicode, then calculate the HMAC
        msg_str = str(msg_dict)
        msg_length = len(msg_str)
        msg_bytes = bytes(msg_str, encoding='utf-8')
        HMAC_abstract1 = hmac.new(self._HMAC_KEY, msg_bytes).digest()
        HMAC_abstract1 = b64encode(HMAC_abstract1)
        HMAC_abstract1 = HMAC_abstract1.decode('utf-8')
        send_data = {'Method': 'receive_all_msg', 'Key': HMAC_abstract1,
                     'ID': self._id, 'Msg_length': msg_length, 'Msg': msg_dict}
        send_data = bytes(json.dumps(send_data), encoding='utf-8')
        # there are no '\n' in json's string, so we use that to split the text.
        self.tcpCliSock.sendall(send_data+b'\n')

    def Loop(self):
        try:
            while 1:
                todo = self.callback_queue.get()
                self.BuildMsg(todo)
        except:# noqa
            pass
        finally:
            if self._isconnected:
                self._isconnected = False
                self.tcpCliSock.close()
