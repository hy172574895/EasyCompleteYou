# Author: Jimmy Huang (1902161621@qq.com)
# License: WTFPL

# stdlib
import argparse
import json
import queue
import threading
import logging
import sys
import os


# local lib
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
sys.path.append(BASE_DIR)
from ECY.utils import socket_ as server
from lib import request_handler as request_handler

parser = argparse.ArgumentParser(
    description='EasyCompleteYou, Easily complete you.')
parser.add_argument('--debug_log', action='store_true', help='debug with log')
parser.add_argument('--hmac', help='the security key of socket communication')
parser.add_argument('--port', help='the port of socket')
parser.add_argument('--log_dir', help='the file of log to output')
# parser.add_argument('--input_with_socket', action='store_true',
#                     help='accept socket data to input. using stdio is default. And you have to give the HMAC and PORT')
# parser.add_argument('--output_with_socket', action='store_true',
#                     help='output results to socket. using stdio is default')
# parser.add_argument('--output_not_with_stdio', action='store_true',
#                     help='do not ouput results to stdio')
g_args = parser.parse_args()

if g_args.log_dir is None:
    output_log_dir = BASE_DIR + "/ECY_server.log"
else:
    output_log_dir = g_args.log_dir

if g_args.debug_log:
    fileHandler = logging.FileHandler(
        output_log_dir, mode="w", encoding="UTF-8")
    formatter = logging.Formatter(
        '%(asctime)s %(filename)s:%(lineno)d | %(message)s')
    fileHandler.setFormatter(formatter)
global g_logger
g_logger = logging.getLogger('ECY_server')
if g_args.debug_log:
    g_logger.addHandler(fileHandler)
    g_logger.setLevel(logging.DEBUG)
    g_logger.debug(BASE_DIR)


class Handler(object):
    def __init__(self, request_queue,
                 is_output_result_to_socket=False,
                 is_output_result_to_stdio=True):
        self._is_output_socket = is_output_result_to_socket
        self._request_queue = request_queue
        self._is_output_stdio = is_output_result_to_stdio

        self._pass_results_queue = queue.Queue()
        self.event_handler = request_handler.EventHandler(
            self._pass_results_queue)
        threading.Thread(target=self._handler, daemon=True).start()
        self._pass_results_to_vim()  # will block this process

    def _handler(self):
        """ is just a thread
        """
        g_logger.debug('Handler started.')
        while 1:
            try:
                todo_dict = self._request_queue.get()
                todo_dict = self.event_handler.HandleIt(todo_dict)
                for item in todo_dict:
                    if item is not None:
                        self._pass_results_queue.put(item)
            except:
                g_logger.exception("something wrong")
                # self._pass_results_queue.put({'Event': 'erro', 'Erro': erro})

    def _pass_results_to_vim(self):
        """ this should not be a thread; because some operating system will not
        ouput data to stdio, in a thread.
        """
        g_logger.debug('pass thread started.')
        try:
            while 1:
                temp = json.dumps(self._pass_results_queue.get())
                if self._is_output_stdio:
                    self.StdioOutput(temp)
                if self._is_output_socket:
                    # TODO
                    pass
        except:
            g_logger.exception("something wrong")

    def StdioOutput(self, sending_data_bytes):
        sys.__stdout__.write(sending_data_bytes + '\n')
        sys.__stdout__.flush()


Handler(server.Server(g_args.port, g_args.hmac).GetResults())
g_logger.debug('Server finished.')
