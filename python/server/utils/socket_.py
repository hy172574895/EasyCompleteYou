# Author: Jimmy Huang (1902161621@qq.com)
# License: WTFPL

import hmac
import hashlib
import threading
import queue
import json
from socket import *
from base64 import b64decode
import logging

global g_logger
g_logger = logging.getLogger('ECY')


class Server(object):
    def __init__(self, port, hmac_str, is_use_socket_to_get_msg=True):
        self._results_queue = queue.Queue()
        if not is_use_socket_to_get_msg:
            pass
            # TODO
            # self.thread = threading.Thread(target=self.StdioLoop)
            # self.stdio_data_handler = StdioDataHander()
        else:
            self.HOST = gethostname()
            # for security reason, we have to make sure the client is the right one.
            self.BUFSIZ = 1024 * 100

            self.ADDR = (self.HOST, int(port))
            self.tcpSerSock = socket(AF_INET, SOCK_STREAM)
            self.tcpSerSock.bind(self.ADDR)
            self.tcpSerSock.listen(5)

            self.thread = threading.Thread(target=self.SocketLoop)
            # with HMAC for socket
            self._HMAC_KEY = bytes(str(hmac_str), encoding='utf-8')
            self.thread.daemon = True

    def GetResults(self):
        self.thread.start()
        return self._results_queue

    def SocketLoop(self):
        g_logger.debug("using socket to input")
        while True:
            tcpCliSock, addr = self.tcpSerSock.accept()
            data_bytes = b''
            g_logger.debug("server connect successfully.")
            # tcpCliSock.settimeout(5)
            try:
                while True:
                    data_bytes += tcpCliSock.recv(self.BUFSIZ)
                    if not data_bytes:
                        return
                    part_bytes = data_bytes.split(b'\n')
                    # we make sure every recived json can be loaded with no erro.
                    # a simple C/S
                    # if the last one in the variable part_bytes is empty
                    # so it's incomplete
                    the_last_one = len(part_bytes)-1
                    data_bytes = part_bytes[the_last_one]
                    i = 0
                    while i < the_last_one:
                        data_dict = json.loads(bytes.decode(part_bytes[i]))
                        i += 1
                        self.HandData(data_dict)
            except Exception as e:
                g_logger.exception("something wrong")
                # time out or something wrong.
                # maybe that data is too big. we donot accept that big data beacause
                # this server just like a callback event
            finally:
                tcpCliSock.close()
        self.tcpSerSock.close()

    def _calculate_key2(self, dicts):
        """ return bytes
        """
        dicts_byte = bytes(str(dicts), encoding='utf-8')
        # we are using MD5, it's safe enough for us, because the key is
        # too complicated.
        # And for compatibility, we must specify 'digestmod'
        HMAC_abstract2 = hmac.new(
            self._HMAC_KEY, dicts_byte, digestmod=hashlib.md5).digest()
        return HMAC_abstract2

    def _calculate_key1(self, key_str):
        """ return bytes
        """
        HMAC_abstract1 = bytes(key_str, encoding='utf-8')
        HMAC_abstract1 = b64decode(HMAC_abstract1)
        return HMAC_abstract1
    
    def _compare_key(self, key1_bytes, key2_bytes):
        return hmac.compare_digest(key1_bytes, key2_bytes) 

    def HandData(self, data_dict):
        if data_dict['Method'] == 'receive_all_msg':
            key1 = self._calculate_key1(data_dict['Key'])
            key2 = self._calculate_key2(data_dict['Msg'])
            if self._compare_key(key1, key2):
                data_dict = {'Msg': data_dict['Msg']}
                self._results_queue.put(data_dict)
            else:
                g_logger.debug(key1)
                g_logger.debug(key1)
                g_logger.debug("a msg was abandomed.")
                # TODO: handle an unkonw msg
                pass
